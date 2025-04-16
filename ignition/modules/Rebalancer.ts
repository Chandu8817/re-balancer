// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";

const RebalancerModule = buildModule("RebalancerModule", (m) => {
 
  const router = "0x5543c6176FEb9B4b179078205d7C29EEa2e2d695";
  const positionManager = "0x12E66C8F215DdD5d48d150c8f46aD0c6fB0F4406";
  const maxFee = ethers.parseEther("0.8");
  const rebalancer = m.contract("Rebalancer", [router, maxFee,675857,"0x095b84cf2B26a11F42b8DBE5dA7Dc45fBdf0ACD4","0x9F59398D0a397b2EEB8a6123a6c7295cB0b0062D"]);

  return { rebalancer };
});

export default RebalancerModule;
