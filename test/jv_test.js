
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PumkRunner", function () {

  let owner, addr1, addr2, addrs;
  let nftFactory;
  let nft;
  let tokenFactory;
  let token;

  async function showAllAddressNFTInformation() {
    await showAddressNFTInformation("owner", owner);    
    await showAddressNFTInformation("addr1", addr1);    
    await showAddressNFTInformation("addr2", addr2);    
    await showAddressNFTInformation("addr3", addr3);    
  }

  async function showAddressNFTInformation(ownerName, addr) {
    let myNFTs = await nft.connect(addr).listMyNFT();
    console.log(ownerName, "'s nfts: ", myNFTs);

    for (var i=0;i<myNFTs.length;i++) {
      console.log("NFT:", myNFTs[i], "  Information");
      console.log("points:", await nft.connect(addr).queryPoints(addr.address));
      console.log("ability:", await nft.connect(addr).queryAbility(myNFTs[i]));
      console.log("token balance", await nft.connect(addr).queryTokenBalance(myNFTs[i]));
      console.log("token fight balance", await nft.connect(addr).queryTokenFightBalance(myNFTs[i]));
      console.log("--------------------------------------");
    }
  }

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.

    [owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();

    nftFactory = await ethers.getContractFactory("JurassicVirusNFT");
    nft = await nftFactory.deploy();
    await nft.deployed();
    console.log("nft address: " + nft.address);

    tokenFactory = await ethers.getContractFactory("CultureToken");
    token = await tokenFactory.deploy();
    console.log("token address: " + token.address);

  });




  it("Test Purchase", async function () {

    let totalPay = BigInt(1000000 * 10 ** 18);
    await token.grantRole(token.getMinterRole(), owner.address);

    await token.mint(owner.address, totalPay);
    await token.mint(addr1.address, totalPay);
    await token.mint(addr2.address, totalPay);
    await token.mint(addr3.address, totalPay);

    // console.log(await token.balanceOf(owner.address));
    
    await token.grantRole(token.getBurnerRole(), nft.address);
    await token.grantRole(token.getMinterRole(), nft.address);
    await nft.updateToken(token.address);

    await token.approve(nft.address, totalPay);
    await token.connect(addr1).approve(nft.address, totalPay);
    await token.connect(addr2).approve(nft.address, totalPay);
    await token.connect(addr3).approve(nft.address, totalPay);

    let fightMode = BigInt(2);
    let bets = BigInt(100 * 10 ** 18);
    await nft.purchaseNFT(2, {value: ethers.utils.parseEther("0.2")});
    let myNFTs = await nft.listMyNFT();
    await nft.updateLevel(myNFTs[0], bets);
    await nft.updateLevel(myNFTs[0], bets);
    await nft.updateLevel(myNFTs[0], bets);

    await showAddressNFTInformation("owner", owner);
    // await nft.startMode(myNFTs[1], fightMode, bets);
    await nft.burnNFT(myNFTs[1]);
    await nft.assignAllEnergy(myNFTs[0], 1,5,2);

    await showAddressNFTInformation("owner", owner);
    // await showAllAddressNFTInformation();

    await nft.connect(addr1).purchaseNFT(1, {value: ethers.utils.parseEther("1")});
    let addr1NFTs = await nft.connect(addr1).listMyNFT();
    // await showAddressNFTInformation("addr1", addr1);
    await nft.connect(addr1).updateLevel(addr1NFTs[0], bets);
    await nft.connect(addr1).startMode(addr1NFTs[0], fightMode, bets);
    // await showAddressNFTInformation("addr1", addr1);
    
    await nft.connect(addr2).purchaseNFT(1, {value: ethers.utils.parseEther("1")});
    // await showAddressNFTInformation("addr2", addr2);

    let addr2NFTs = await nft.connect(addr2).listMyNFT();
    await nft.connect(addr2).updateLevel(addr2NFTs[0], bets);
    await nft.connect(addr2).updateLevel(addr2NFTs[0], bets);
    await nft.connect(addr2).startMode(addr2NFTs[0], 2, bets);
    // await showAddressNFTInformation("addr2", addr2);


    await nft.connect(addr3).purchaseNFT(1, {value: ethers.utils.parseEther("1")});
    // await showAddressNFTInformation("addr3", addr3);
    let addr3NFTs = await nft.connect(addr3).listMyNFT();
    await nft.connect(addr3).updateLevel(addr3NFTs[0], bets);
    await nft.connect(addr3).updateLevel(addr3NFTs[0], bets);
    await nft.connect(addr3).updateLevel(addr3NFTs[0], bets);
    await nft.connect(addr3).startMode(addr3NFTs[0], 2, bets);
    // await showAddressNFTInformation("addr3", addr3);
    
    
    // await showAllAddressNFTInformation();




    

  });
  




});