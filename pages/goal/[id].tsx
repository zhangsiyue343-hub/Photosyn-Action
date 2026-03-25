import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { getContract } from "../../lib/contract";
import { ethers } from "ethers";

export default function GoalPage() {

  const router = useRouter();
  const { id } = router.query; // 获取URL里的id

  const [goal, setGoal] = useState<any>(null);
  const [amount, setAmount] = useState("");

  // 加载目标数据
  async function load() {
    if (!id) return;

    const contract = await getContract();
    const g = await contract.getGoal(id);

    setGoal(g);
  }

  // 投资
  async function invest() {
    const contract = await getContract();

    const tx = await contract.invest(id, {
      value: ethers.parseEther(amount), // 把字符串转成ETH
    });

    await tx.wait();

    load(); // 更新数据
  }

  // 完成目标
  async function complete() {
    const contract = await getContract();

    const tx = await contract.completeGoal(id);

    await tx.wait();

    alert("Completed!");
  }

  useEffect(() => {
    load();
  }, [id]);

  if (!goal) return <div>Loading...</div>;

  return (
    <div style={{ padding: 20 }}>
      <h2>{goal[1]}</h2>

      <p>💰 {goal[2].toString()}</p>

      {/* 输入投资金额 */}
      <input
        placeholder="ETH"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
      />

      <button onClick={invest}>Invest</button>

      <button onClick={complete}>Complete</button>
    </div>
  );
}