require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
require("hardhat-abi-exporter");
require("hardhat-tracer");
require("hardhat-gas-reporter");

require('dotenv').config();

const { RINKEBY_API_URL, RINKEBY_PRIVATE_KEY, TC_API_URL, TC_PRIVATE_KEY, ETH_PRIVATE_KEY} = process.env;

// require('dotenv').config({path:__dirname+'/.env'})

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },

  gasReporter: {
    currency: 'CHF',
    gasPrice: 21,
    enabled: false
  },

  networks: {
    test: {
        url: TC_API_URL,
        accounts: [TC_PRIVATE_KEY]
        // ,
        // allowUnlimitedContractSize: true,
        // gas: 1200000000,
        // gasPrice: 10000000070, 
    },
    eth: {
      url: `https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`,
      accounts: [ETH_PRIVATE_KEY]
      // allowUnlimitedContractSize: true,
      // gas: 1200000000,
      // gasPrice: 10000000070, 
    },
    rinkeby: {
      url: RINKEBY_API_URL,
      accounts: [RINKEBY_PRIVATE_KEY]
      // ,
      // allowUnlimitedContractSize: true,
      // gas: 1200000000,
      // gasPrice: 10000000070, 
    }

  },
  
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  }

};




