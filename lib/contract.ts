import { ethers } from "ethers";

// 这里换成你部署的合约地址
const contractAddress = "0x578ddA12a6b77Aab7BbFeA658F9cf2d34f5970b0";

// ABI：告诉前端“合约有哪些函数”
const abi = [
  "function createGoal(string _desc, uint256 _duration)",
  "function invest(uint256 _id) payable",
  "function completeGoal(uint256 _id)",
  "function getGoalsCount() view returns (uint256)",
  "function getGoal(uint256 _id) view returns (address,string,uint256,uint256,bool)"
];

// 获取合约实例（后面所有操作都靠它）
export async function getContract() {

  // 检查用户是否有钱包（MetaMask）
  if (!window.ethereum) throw new Error("No wallet");

  // 创建 provider（区块链连接）
  const provider = new ethers.BrowserProvider(window.ethereum);

  // 获取用户账户（签名者）
  const signer = await provider.getSigner();

  // 返回合约对象（可以调用函数）
  return new ethers.Contract(contractAddress, abi, signer);
}