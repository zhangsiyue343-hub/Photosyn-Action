import { useEffect, useState } from "react";
import { getContract } from "../lib/contract";
import Link from "next/link";

export default function Home() {

  // 存储所有目标
  const [goals, setGoals] = useState<any[]>([]);

  // 加载数据
  async function loadGoals() {
    const contract = await getContract();

    // 获取目标数量
    const count = await contract.getGoalsCount();

    let list = [];

    // 循环获取每一个目标
    for (let i = 0; i < count; i++) {
      const g = await contract.getGoal(i);

      // 把数据放入数组
      list.push({ id: i, ...g });
    }

    setGoals(list);
  }

  // 页面加载时执行
  useEffect(() => {
    loadGoals();
  }, []);

  return (
    <div style={{ padding: 20 }}>
      <h1>🌱 Photosyn-Action</h1>

      {/* 跳转创建页面 */}
      <Link href="/create">Create Goal</Link>

      {/* 展示所有目标 */}
      {goals.map((g) => (
        <div key={g.id} style={{ border: "1px solid #ccc", margin: 10, padding: 10 }}>
          
          {/* 目标描述 */}
          <p>{g[1]}</p>

          {/* 当前资金 */}
          <p>💰 {g[2].toString()} wei</p>

          {/* 跳转详情 */}
          <Link href={`/goal/${g.id}`}>View</Link>
        </div>
      ))}
    </div>
  );
}