import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-gas-reporter";
import "@primitivefi/hardhat-dodoc";
import "hardhat-interface-generator";
import "@nomicfoundation/hardhat-foundry";

import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.23",
  networks: {
    sepolia: {
      url: "https://eth-sepolia.public.blastapi.io",
      accounts: [process.env.PRIVATE_KEY as string],
    },
    mainnet: {
      url: "https://rpc.ankr.com/eth",
      accounts: [process.env.PRIVATE_KEY as string],
    },
    hardhat: {
      forking: {
        url: "https://rpc.ankr.com/eth",
      },
    },
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.API_KEY as string,
    },
    customChains: [
      {
        network: "mainnet",
        chainId: 1,
        urls: {
          apiURL: "https://api.etherscan.io/api/",
          browserURL: "https://etherscan.io/",
        },
      },
    ],
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v6",
  },
  gasReporter: {
    currency: "USD",
  },
  dodoc: {
    runOnCompile: true,
    debugMode: false,
  },
};

export default config;
