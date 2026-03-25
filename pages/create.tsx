import { useState } from "react";
import { useRouter } from "next/router";
import { ethers } from "ethers";
import { getContract } from "../lib/contract";

/**
 * Create Goal 页面：
 *  - 输入 description
 *  - 输入金额（本合约 createGoal 后会自动 invest）
 *  - 输入天数（转换成 durationSeconds）
 *  - 点击按钮后：调用 createGoal（并在金额>0时追加 invest）
 */
export default function Create() {
  const router = useRouter();

  const [description, setDescription] = useState("");
  const [amount, setAmount] = useState("0"); // ETH 金额（因为当前 ABI 是 payable invest）
  const [days, setDays] = useState("7");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCreate() {
    setLoading(true);
    setError(null);

    try {
      const contract = await getContract();

      // 目标数量：新 goalId = 当前 count
      const count = await contract.getGoalsCount(); // bigint

      const d = Number(days);
      if (!Number.isFinite(d) || d <= 0) {
        throw new Error("天数必须是大于 0 的数字");
      }
      // 注意：tsconfig target 可能低于 ES2020，因此不要使用 BigInt 字面量（例如 86400n）
      const durationSeconds = BigInt(Math.floor(d)) * BigInt(86400);

      // 1) 创建目标
      const tx = await contract.createGoal(description, durationSeconds);
      await tx.wait();

      // 2) 金额>0：立刻投资（可选）
      const amt = amount.trim();
      if (amt && Number(amt) > 0) {
        const tx2 = await contract.invest(count, {
          value: ethers.parseEther(amt),
        });
        await tx2.wait();
      }

      // 跳转到新目标详情页
      router.push(`/goal/${count.toString()}`);
    } catch (e: any) {
      setError(e?.message ?? String(e));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ padding: 20, maxWidth: 520, margin: "0 auto" }}>
      <h2>Create Goal</h2>

      <div style={{ display: "grid", gap: 12, marginTop: 12 }}>
        <div style={{ display: "grid", gap: 6 }}>
          <div>description</div>
          <input
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Your goal description"
          />
        </div>

        <div style={{ display: "grid", gap: 6 }}>
          <div>amount（ETH）</div>
          <input
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0"
          />
        </div>

        <div style={{ display: "grid", gap: 6 }}>
          <div>days</div>
          <input
            value={days}
            onChange={(e) => setDays(e.target.value)}
            placeholder="7"
          />
        </div>

        {error ? <p style={{ color: "red" }}>{error}</p> : null}

        <button
          onClick={handleCreate}
          disabled={loading || description.trim().length === 0}
        >
          {loading ? "Creating..." : "Create"}
        </button>
      </div>
    </div>
  );
}