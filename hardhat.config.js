require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");
require('hardhat-contract-sizer');
require("dotenv").config();

module.exports = {
  solidity: "0.8.17",
  // Testnets
  networks: {
    //BSC Testnet
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [process.env.BSC_TESTNET_PRIVATE_KEY],
    },
    //Goerli Testnet
    goerli: {
      url: `https://goerli.infura.io/v3/681d784bc2db408b8aa49ec6b887d47a`,
      chainId: 5,
      gasPrice: 20000000000,
      accounts: [process.env.GOERLI_TESTNET_PRIVATE_KEY]
    },
    //Polygon Testnet
    matic: {
      url: "https://polygon-mumbai.infura.io/v3/4458cf4d1689497b9a38b1d6bbf05e78",
      chainId: 80001,
      gasPrice: 20000000000,
      accounts: [process.env.POLYGON_TESTNET_PRIVATE_KEY]
    }
  },

  // Mainnets
  // networks: {
  // BSC Mainnet
  // gasPrice: 20000000000,
  // mainnet: {
  //   url: "https://bsc-dataseed.binance.org/",
  //   chainId: 56,
  //   accounts: [process.env.BSC_MAINNET_PRIVATE_KEY]
  // },
  // Ethereum Mainnet
  // mainnet: {
  //   url: "https://mainnet.infura.io/v3/04b835bf9aca4468b7d7ee914b4f58ff", // or any other JSON-RPC provider
  //   chainId: 1,
  //   gasPrice: 2904635,
  //   accounts: [process.env.ETHEREUM_MAINNET_PRIVATE_KEY]
  // },
  // Polygon Mainnet
  // polygon: {
  //   url: "https://polygon-rpc.com",
  //   chainId: 137, 
  //   accounts: [process.env.POLYGON_MAINNET_PRIVATE_KEY]
  // }
  // },

  etherscan: {
    // polygon apiKey
    apiKey: "61NXGEUMZJGEXU5ZTZQN8ZGHRBC8PAVSFN"
    // apiKey: {
    //   bscTestnet: "7FH7WAR3SHRS7UDI2YZQWVR5F1SJ3PJBI2",
    //   //   // bsc: "7FH7WAR3SHRS7UDI2YZQWVR5F1SJ3PJBI2",
    //   //   goerli: "JB7KZVSGD7Z4AGJGEYITX4WY1W5V4I5D1K",
    //   //   mainnet: "JB7KZVSGD7Z4AGJGEYITX4WY1W5V4I5D1K"
    // }
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
      details: { yul: false },
    },
  },
};