// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();

    console.log(
      "Deploying contracts with the account:",
      deployer.address
    );
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
    
    const existContractAddress = "";
    const badgeTokenAddress="";
    const factory = await ethers.getContractFactory("JurassicVirusNFT");
    let nft;

    nft = await factory.deploy();
    console.log("NFT Contract Address:", nft.address);

    const tokenFactory = await ethers.getContractFactory("CultureToken");
    let token = await badgeTokenFactory.attach("0x89049c98245D8cF6CBEE7fcE673272653b45c1A0");
    // let token = await tokenFactory.deploy();
    console.log("Token address:", token.address);

    console.log("update token address", await nft.updateToken(token.address));

    console.log("grant miner role:", await token.grantRole(token.getMinterRole(), nft.address));
    console.log("grant burner role", await token.grantRole(token.getBurnerRole(), nft.address));

    console.log(await token.grantRole(badgeToken.getMinterRole(), "0xf46B1E93aF2Bf497b07726108A539B478B31e64C"));
    // 0xBbe14Ab2F06Ef9B33DA7da789005b0CD669C7F81  张振
    // transfer test token
    // let tran = BigInt(10000 * 10 ** 18);
    // await badgeToken.mint("0x274fD8C49DECe3C474D182a290D6b2F61d6Dce36", tran);
    // await badgeToken.mint("0xBbe14Ab2F06Ef9B33DA7da789005b0CD669C7F81", tran);

    console.log("");
    console.log("npx hardhat console --network rinkeby");
    console.log("");  
    console.log("const punkFactory = await ethers.getContractFactory(\"PunkRunnerNFT\");");
    console.log("");
    console.log("const ct = await punkFactory.attach(\""+nft.address+"\");");
    console.log("");
    console.log("await ct.purchaseNFT(5, {from:\""+deployer.address+"\", value:ethers.utils.parseEther(\"0.03\")});");
    console.log("");


    // console.log(await badgeToken.grantRole(badgeToken.getMinterRole(), "0xf46B1E93aF2Bf497b07726108A539B478B31e64C"));
    // console.log(await badgeToken.grantRole(badgeToken.getMinterRole(), "0xe28da41CC50F1205072aaa400cDc28B31Bc1c4e0"));
    // console.log(await badgeToken.grantRole(badgeToken.getBurnerRole(), "0xe28da41CC50F1205072aaa400cDc28B31Bc1c4e0"));

    // 0xBbe14Ab2F06Ef9B33DA7da789005b0CD669C7F81  张振
    // transfer test token
    let tran = BigInt(10000 * 10 ** 18);
    
    // 
    // await badgeToken.mint("0x274fD8C49DECe3C474D182a290D6b2F61d6Dce36", tran);
    await token.mint("0xBbe14Ab2F06Ef9B33DA7da789005b0CD669C7F81", tran);
    await token.mint("0xf46B1E93aF2Bf497b07726108A539B478B31e64C", tran);
    
    // tao ge
    // await badgeToken.mint("0x801204b07A772Ac656E854B0091f96Cbb2736810", tran);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
