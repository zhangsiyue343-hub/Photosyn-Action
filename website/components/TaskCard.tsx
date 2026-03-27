import { motion } from "framer-motion";
import Link from "next/link";

export default function TaskCard({ task }: any) {
  return (
    <motion.div
      whileHover={{ scale: 1.05 }}
      className="bg-gradient-to-br from-purple-900 to-black 
      p-5 rounded-2xl shadow-xl"
    >
      <h2 className="text-xl font-bold">{task.title}</h2>

      <p className="text-gray-400 mt-2">
        奖励 {task.reward}
      </p>

      <p className="mt-2 text-purple-300">
        🌌 {task.status}
      </p>

      <Link href={`/detail/${task.id}`}>
        <button className="mt-4 w-full bg-primary py-2 rounded-lg">
          进入契约
        </button>
      </Link>
    </motion.div>
  );
}
