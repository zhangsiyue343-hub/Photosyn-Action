"use client";

import { useState } from "react";
import { motion } from "framer-motion";

export default function App() {
  const [page, setPage] = useState("home");
  const [progress, setProgress] = useState(30);

  const tasks = [
    {
      id: 1,
      title: "30天跳槽计划",
      reward: "100 USDC",
      status: "🔥 恒星进行中",
    },
    {
      id: 2,
      title: "提升表达能力",
      reward: "50 USDC",
      status: "🌱 萌芽",
    },
  ];

  return (
    <div className="min-h-screen bg-black text-white overflow-hidden relative">

      {/* 🌌 星云背景 */}
      <div className="absolute inset-0 bg-gradient-to-br from-purple-900 via-black to-blue-900 opacity-80" />

      <div className="relative z-10 p-6">

        {/* 顶部 */}
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-3xl font-bold">
            🌌 Photosyn-Action
          </h1>

          <button className="bg-purple-600 px-4 py-2 rounded-xl">
            Connect Wallet
          </button>
        </div>

        {/* 导航 */}
        <div className="flex gap-3 mb-6">
          <button onClick={() => setPage("home")}>市场</button>
          <button onClick={() => setPage("create")}>发布</button>
          <button onClick={() => setPage("detail")}>竞拍</button>
          <button onClick={() => setPage("growth")}>成长</button>
        </div>

        {/* 🌌 首页 */}
        {page === "home" && (
          <div className="grid gap-4">
            {tasks.map((t) => (
              <motion.div
                key={t.id}
                whileHover={{ scale: 1.05 }}
                className="bg-gradient-to-br from-purple-800 to-black p-5 rounded-2xl shadow-xl backdrop-blur"
              >
                <h2 className="text-xl font-bold">{t.title}</h2>
                <p className="text-gray-400 mt-2">
                  奖励 {t.reward}
                </p>
                <p className="mt-2 text-purple-300">
                  {t.status}
                </p>

                <button
                  onClick={() => setPage("detail")}
                  className="mt-4 w-full bg-purple-600 py-2 rounded-xl"
                >
                  进入契约
                </button>
              </motion.div>
            ))}
          </div>
        )}

        {/* ✍️ 发布 */}
        {page === "create" && (
          <div className="max-w-md">
            <h2 className="text-2xl mb-4">发布成长契约</h2>

            <input className="w-full p-2 mb-3 bg-black border rounded" placeholder="需求标题" />
            <textarea className="w-full p-2 mb-3 bg-black border rounded" placeholder="描述" />
            <input className="w-full p-2 mb-3 bg-black border rounded" placeholder="奖金 (USDC)" />

            <button className="bg-green-500 px-4 py-2 rounded-xl">
              发布
            </button>
          </div>
        )}

        {/* 💰 竞拍 */}
        {page === "detail" && (
          <div>
            <h2 className="text-2xl mb-4">竞拍成长伙伴</h2>

            {[
              { name: "导师A", rate: "20%" },
              { name: "导师B", rate: "30%" },
            ].map((b, i) => (
              <motion.div
                key={i}
                whileHover={{ scale: 1.03 }}
                className="border p-4 mb-3 rounded-xl bg-black/50 backdrop-blur"
              >
                <p>{b.name}</p>
                <p>分成：{b.rate}</p>

                <button className="mt-2 bg-purple-600 px-3 py-1 rounded">
                  选择TA
                </button>
              </motion.div>
            ))}
          </div>
        )}

        {/* 📈 成长 */}
        {page === "growth" && (
          <div>
            <h2 className="text-2xl mb-4">成长执行</h2>

            <button
              onClick={() => setProgress(progress + 10)}
              className="bg-blue-500 px-4 py-2 rounded-xl"
            >
              今日打卡
            </button>

            <div className="mt-4">
              <p>进度：{progress}%</p>

              <div className="w-full bg-gray-700 h-3 rounded mt-2">
                <div
                  className="bg-cyan-400 h-3 rounded transition-all"
                  style={{ width: `${progress}%` }}
                />
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
