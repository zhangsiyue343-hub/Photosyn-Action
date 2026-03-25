// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ActionSBT
 * @notice 基于 ERC721 的“不可转让”代币（SBT，Soulbound Token）：
 * - 非转让：禁止转账相关函数（让它“绑定在用户身上”）
 * - 支持 mint：由合约拥有者（owner）铸造发给用户
 * - 记录成长行为：每个 SBT 除了 tokenId，还会存一个“类型 + 行为描述”
 */
contract ActionSBT is ERC721, Ownable {
    // 3 种 SBT 类型（枚举）
    enum SBTType {
        Courage, // 勇气：例如敢于尝试/迎难而上
        Execution, // 执行：例如能落地/按计划完成
        Mentor // 导师：例如帮助他人/提供指导
    }

    // 每个 tokenId 对应的元数据（Meta）
    struct SBTMeta {
        SBTType sbtType; // 该 SBT 属于哪种类型
        string behavior; // 成长行为描述（可读文本，用于展示）
    }

    // 用于生成 tokenId：1 开始自增
    uint256 private _nextTokenId = 1;

    // tokenId => 元数据（类型 + 行为）
    mapping(uint256 => SBTMeta) private _meta;

    // 铸造事件：方便前端/索引器监听“谁领到了什么类型的 SBT”
    event SBTMinted(
        uint256 indexed tokenId,
        address indexed to,
        SBTType indexed sbtType,
        string behavior
    );

    // 构造函数：把部署者设置为 owner
    constructor() ERC721("ActionSBT", "ASBT") Ownable(msg.sender) {}

    /**
     * @notice 铸造（mint）一个 SBT
     * @param to 接收地址：SBT 会被“发给”谁
     * @param sbtType SBT 类型：Courage / Execution / Mentor
     * @param behavior 行为描述：用于记录成长，例如“坚持复盘/完成冲刺/指导新人”
     * @dev 只有 owner 才能 mint（onlyOwner）
     */
    function mint(
        address to,
        SBTType sbtType,
        string calldata behavior
    ) external onlyOwner returns (uint256 tokenId) {
        // 基础校验：不能发给零地址
        require(to != address(0), "SBT: zero address");
        // 基础校验：behavior 不能为空
        require(bytes(behavior).length > 0, "SBT: empty behavior");

        // 生成新的 tokenId
        tokenId = _nextTokenId;
        _nextTokenId += 1;

        // 把类型和行为写入到元数据映射里
        _meta[tokenId] = SBTMeta({sbtType: sbtType, behavior: behavior});

        // 使用 ERC721 的 _safeMint：把 tokenId 安全铸造给 to
        // safeMint 内部会检查接收者是否是合约地址以及是否支持回调
        _safeMint(to, tokenId);

        // 发事件：前端可以监听该事件来展示“已获得的 SBT”
        emit SBTMinted(tokenId, to, sbtType, behavior);
    }

    /**
     * @notice 查询 tokenId 对应的 SBT 类型
     * @dev 不存在的 tokenId 会直接 revert，提示不存在
     */
    function sbtTypeOf(uint256 tokenId) public view returns (SBTType) {
        require(_exists(tokenId), "SBT: nonexistent token");
        return _meta[tokenId].sbtType;
    }

    /**
     * @notice 查询 tokenId 对应的成长行为描述
     * @dev 不存在的 tokenId 会直接 revert
     */
    function behaviorOf(
        uint256 tokenId
    ) public view returns (string memory) {
        require(_exists(tokenId), "SBT: nonexistent token");
        return _meta[tokenId].behavior;
    }

    /**
     * @dev 关键点：SBT 禁止转让
     * - transferFrom / safeTransferFrom 是 ERC721 最常用的“转移所有权”入口
     * - 我们直接 revert，任何外部调用都无法转走 token
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("SBT: non-transferable");
    }

    // safeTransferFrom（重载 1）：同样禁止
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("SBT: non-transferable");
    }

    // safeTransferFrom（重载 2）：同样禁止（带 data 参数）
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("SBT: non-transferable");
    }

    /**
     * @dev 进一步加强 soulbound：
     * - approve：授权别人转你的 token（这里禁用）
     * - setApprovalForAll：允许某个 operator 批量转你的 token（这里禁用）
     * 禁用它们可以减少钱包/前端误导（避免它们以为 token 可被转让）
     */
    function approve(address, uint256) public pure override {
        revert("SBT: non-transferable");
    }

    // setApprovalForAll：禁用
    function setApprovalForAll(address, bool) public pure override {
        revert("SBT: non-transferable");
    }
}

