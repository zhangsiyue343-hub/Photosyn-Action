// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GrowthPool
 * @notice 黑客松 MVP：
 *         用户创建成长目标，其他人可在截止时间前用 USDC 投资。
 *         到期后，如果创建者已标记目标完成，则投资人可领取；
 *         否则投资人可以退回其本金。
 *
 * @dev 结果与分配逻辑（MVP 简化）：
 * - 创建者在截止时间前/当日调用一次 `completeGoal(id)`。
 * - 任意人可在截止时间后调用 `finalize(id)`。
 * - completed == true：
 *    每个投资人按其投入比例领取本金（MVP 中等同于“按投入金额返还”）。
 * - completed == false：
 *    每个投资人都领取本金（退款）。
 *
 *         本 MVP 不包含“额外奖励”。如需可在创建/最终结算时额外注入奖励金额后扩展实现。
 */
contract GrowthPool {
    // -------------------------------------------------------------------------
    // 代币接口（USDC）
    // -------------------------------------------------------------------------
    interface IERC20 {
        function transfer(address to, uint256 value) external returns (bool);

        function transferFrom(address from, address to, uint256 value) external returns (bool);
    }

    // -------------------------------------------------------------------------
    // 事件
    // -------------------------------------------------------------------------
    event GoalCreated(
        uint256 indexed goalId,
        address indexed creator,
        string description,
        uint256 deadline
    );
    event Invested(uint256 indexed goalId, address indexed investor, uint256 amount);
    event GoalCompleted(uint256 indexed goalId, address indexed creator);
    event GoalFinalized(uint256 indexed goalId, bool completed);
    event Claimed(
        uint256 indexed goalId,
        address indexed investor,
        uint256 amount,
        bool completed
    );

    // -------------------------------------------------------------------------
    // 防重入保护（MVP 不依赖外部库）
    // -------------------------------------------------------------------------
    uint256 private _reentrancyLock = 1;
    modifier nonReentrant() {
        require(_reentrancyLock == 1, "REENTRANCY");
        _reentrancyLock = 2;
        _;
        _reentrancyLock = 1;
    }

    // -------------------------------------------------------------------------
    // 存储结构
    // -------------------------------------------------------------------------
    IERC20 public immutable usdc;
    uint256 public goalsCount;

    struct Goal {
        address creator;
        string description;
        uint256 deadline;
        uint256 totalInvested;
        bool completed; // creator 标记完成（finalize 前）
        bool finalized; // 是否已最终结算（finalize 是否已调用）
    }

    // goalId => 目标数据
    mapping(uint256 => Goal) public goals;

    // goalId => 投资人 => 投入的 USDC 数量
    mapping(uint256 => mapping(address => uint256)) public userInvested;

    // goalId => 投资人 => 是否已领取
    mapping(uint256 => mapping(address => bool)) public claimed;

    // -------------------------------------------------------------------------
    // 构造函数
    // -------------------------------------------------------------------------
    constructor(address usdcAddress) {
        require(usdcAddress != address(0), "USDC_ZERO");
        usdc = IERC20(usdcAddress);
    }

    // -------------------------------------------------------------------------
    // 核心功能（无管理员，按规则开放）
    // -------------------------------------------------------------------------

    /**
     * @notice 创建一个成长目标。
     * @param description 目标描述（可读文本）
     * @param durationSeconds 距离截止时间的秒数
     */
    function createGoal(string calldata description, uint256 durationSeconds) external returns (uint256) {
        bytes memory descBytes = bytes(description);
        require(descBytes.length > 0, "DESC_EMPTY");
        require(durationSeconds > 0, "DURATION_ZERO");

        uint256 goalId = goalsCount;
        goalsCount += 1;

        uint256 deadline = block.timestamp + durationSeconds;

        Goal storage g = goals[goalId];
        g.creator = msg.sender;
        g.description = description;
        g.deadline = deadline;
        g.totalInvested = 0;
        g.completed = false;
        g.finalized = false;

        emit GoalCreated(goalId, msg.sender, description, deadline);
        return goalId;
    }

    /**
     * @notice 在截止时间前为目标投资 USDC。
     * @param goalId 目标 id
     * @param amount 投资金额（USDC 的原始代币单位；通常 USDC 是 6 位小数）
     */
    function invest(uint256 goalId, uint256 amount) external nonReentrant {
        Goal storage g = goals[goalId];
        require(g.creator != address(0), "GOAL_NOT_FOUND");
        require(block.timestamp < g.deadline, "DEADLINE_PASSED");
        require(!g.finalized, "FINALIZED");
        require(amount > 0, "AMOUNT_ZERO");

        // Effects（先更新状态）
        userInvested[goalId][msg.sender] += amount;
        g.totalInvested += amount;

        // Interactions（再进行外部调用/转账）
        _safeTransferFrom(msg.sender, address(this), amount);

        emit Invested(goalId, msg.sender, amount);
    }

    /**
     * @notice 创建者标记目标为完成。
     * @dev MVP：
     * - 只有创建者可以调用
     * - 只能在截止时间前/当日调用
     * - finalize 在截止时间后调用，用来最终结算结果
     */
    function completeGoal(uint256 goalId) external {
        Goal storage g = goals[goalId];
        require(g.creator != address(0), "GOAL_NOT_FOUND");
        require(msg.sender == g.creator, "NOT_CREATOR");
        require(!g.finalized, "FINALIZED");
        require(block.timestamp <= g.deadline, "TOO_LATE");
        require(!g.completed, "ALREADY_COMPLETED");

        g.completed = true;
        emit GoalCompleted(goalId, msg.sender);
    }

    /**
     * @notice 在截止时间后进行最终结算。
     * @dev 如果创建者没有调用 `completeGoal`，则视为失败。
     */
    function finalize(uint256 goalId) external nonReentrant {
        Goal storage g = goals[goalId];
        require(g.creator != address(0), "GOAL_NOT_FOUND");
        require(!g.finalized, "ALREADY_FINALIZED");
        require(block.timestamp >= g.deadline, "DEADLINE_NOT_REACHED");

        g.finalized = true;
        emit GoalFinalized(goalId, g.completed);
    }

    /**
     * @notice finalize 后领取资金（根据结果领取）。
     * @dev MVP 规则：
     * - completed == true：
     *   每个投资人按其投入金额比例领取本金
     * - completed == false：
     *   每个投资人领取本金（退款）
     */
    function claim(uint256 goalId) external nonReentrant {
        Goal storage g = goals[goalId];
        require(g.creator != address(0), "GOAL_NOT_FOUND");
        require(g.finalized, "NOT_FINALIZED");

        uint256 amount = userInvested[goalId][msg.sender];
        require(amount > 0, "NOTHING_TO_CLAIM");
        require(!claimed[goalId][msg.sender], "ALREADY_CLAIMED");

        claimed[goalId][msg.sender] = true;

        // MVP：返还金额 = 投资本金。（等价于“按投入比例返还本金”）
        uint256 payout = amount;
        userInvested[goalId][msg.sender] = 0;

        _safeTransfer(msg.sender, payout);

        emit Claimed(goalId, msg.sender, payout, g.completed);
    }

    // -------------------------------------------------------------------------
    // 视图函数（给前端读取）
    // -------------------------------------------------------------------------
    function getGoalsCount() external view returns (uint256) {
        return goalsCount;
    }

    /**
     * @notice 为前端提供目标数据格式：
     *         (address, string, uint256, uint256, bool)
     */
    function getGoal(uint256 goalId)
        external
        view
        returns (address creator, string memory description, uint256 deadline, uint256 totalInvested, bool completed)
    {
        Goal storage g = goals[goalId];
        return (g.creator, g.description, g.deadline, g.totalInvested, g.completed);
    }

    // -------------------------------------------------------------------------
    // 安全代币转账
    // -------------------------------------------------------------------------
    function _safeTransferFrom(address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(usdc).call(
            abi.encodeWithSelector(usdc.transferFrom.selector, from, to, value)
        );
        require(success && _isERC20ReturnTrue(data), "TRANSFER_FROM_FAILED");
    }

    function _safeTransfer(address to, uint256 value) internal {
        (bool success, bytes memory data) = address(usdc).call(
            abi.encodeWithSelector(usdc.transfer.selector, to, value)
        );
        require(success && _isERC20ReturnTrue(data), "TRANSFER_FAILED");
    }

    function _isERC20ReturnTrue(bytes memory data) internal pure returns (bool) {
        // 有些 ERC20 代币不会返回数据；这种情况视为成功。
        if (data.length == 0) return true;
        // 如果返回了数据，应该是布尔 true。
        return abi.decode(data, (bool));
    }
}

