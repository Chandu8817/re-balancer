import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { configDotenv } from "dotenv";
configDotenv();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.15",
    settings: {
      optimizer: {
        enabled: true,

        runs: 500,
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://rpc.soniclabs.com/",
        // blockNumber: 18767997,
      },
      hardfork: "shanghai",
    },
    soniclabs: {
      url: "https://rpc.soniclabs.com/",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      chainId: 146,
    },
  },
};

export default config;
