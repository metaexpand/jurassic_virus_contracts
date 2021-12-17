// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "hardhat/console.sol";
import "./IGameNFT.sol";

contract JurassicVirusNFT is IGameNFT, ERC721Burnable, Ownable {
    

    using Counters for Counters.Counter;

    using EnumerableSet for EnumerableSet.UintSet;
    
    Counters.Counter private _totalSold;

    event WithdrawEvent();

    event FightEvent();

    event ChargeEvent();

    event PurchaseEvent();

    
    address private _TOKEN = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
    
    /// @dev 
    uint256 public constant TOTAL_SUPPLY = 10000;
    uint256 public constant PRICE = 0.06 ether;

    /// 500 UNION
    uint256 public constant UPGRADE_STONE_PRICE = 500*10**18;

    bool private IS_SELLING = true;

    uint256 randNonce = 0;
    // mapping(address=>EnumerableSet.UintSet) ownedStones;

    struct Ability {
        uint affection;
        uint resistance;
        uint damage;
    }

    /// @dev token id => ability
    mapping(uint=>Ability) ability;

    mapping(address=>EnumerableSet.UintSet) ownedToken;

    EnumerableSet.UintSet fightingTokens;

    /// @dev token id => start mining time / purchase time
    mapping(uint=>uint256) miningTimestamp;

    /// @dev token id => 1(Nomal Mode)  2(Fight Mode)
    mapping(uint=>uint) tokenMode;

    /// @dev token id => level, default 0, max 5
    mapping(uint=>uint) tokenLevel;

    mapping(uint=>uint) miningTime;

    mapping(address=>uint256) withdrawable;

    /// wallet => Ability point can be used add to any token 
    mapping(address=>Ability) userAbility;

    /// token => fight balance 
    mapping(uint=>uint256) fightBalance;

    /// token => bets how many token will to pay for the fight round
    mapping(uint=>uint256) fightBet;

    constructor() ERC721("Jurassic Virus NFT", "JVN") {}

    /**
        @dev mint one token one time
     */
    function _mintOne(address _to, uint _tokenId) private {
        _totalSold.increment();
        _safeMint(_to, _tokenId);
    }

    function totalSold() public view returns (uint256) {
        return _totalSold.current();
    }


    function isEnoughSupply(uint amount, bool needReportError) private view returns (bool) {

        uint256 solded = totalSold(); 

        uint256 afterPurchase = solded + amount;

        if (needReportError) {
            require(afterPurchase <= TOTAL_SUPPLY, "WastelandUnion: Max limit");
            return true;
        } else {
            if (afterPurchase <= TOTAL_SUPPLY) {
                return true;
            } else {
                return false;
            }
        }
    }

    function baseRequire(uint amount) private view {

        require(IS_SELLING == true, "WastelandUnion: Not start selling yet(1)");
        require(amount >= 1, "WastelandUnion: at least purchase 1");
        require(amount <= 5, "WastelandUnion: at most purchase 5");
        require(msg.value >= (PRICE * amount), "WastelandUnion: insufficient value"); // must send 10 ether to play

        isEnoughSupply(amount, true);
    }


    function mintToAddress(address purchaseUser, uint amount) private {

        EnumerableSet.UintSet storage tokenSet = ownedToken[purchaseUser];
        
        for (uint i=0; i<amount; i++) {
            uint tokenId = _totalSold.current() + 1;
            _mintOne(purchaseUser, tokenId);
            tokenSet.add(tokenId);
        }

        // emit PurchaseNotification(purchaseUser, category, amount, block.timestamp);
    }


    function listMine() external view returns (uint256[] memory tokens) {

        address walletAddress = msg.sender;

        EnumerableSet.UintSet storage tokenSet = ownedToken[walletAddress];

        tokens = tokenSet.values();

    }

    function purchase(uint amount) external payable {

        address purchaseUser = msg.sender;

        baseRequire(amount);
        
        for (uint256 i = 0; i < amount; i++) { 
            mintToAddress(purchaseUser, amount);
        }

    }

    function updateTokenContract(address _token) public {
        _TOKEN = _token;
    }

    
    function random(uint randomSeed, uint lrange, uint mrange) internal returns (uint) {

        randNonce++; 
        uint randomnumber = uint(keccak256(abi.encodePacked(randNonce, randomSeed, msg.sender ,block.timestamp, block.difficulty))) % (mrange - lrange + 1);
        randomnumber = randomnumber + lrange;
        return randomnumber;
    }



    function upgrade(uint tokenId, uint stones) public returns (uint s1, uint i1, uint a1) {
        
    }


    /// @param tokenId token id
    /// @param nMode 0=not start, 1=normal, 2=fighting
    function startMode(uint tokenId, uint nMode, uint bet) public {
        /// require token owner
        /// require valid mode
        uint mode = tokenMode[tokenId];
        if (mode != nMode) {
            tokenMode[tokenId] = nMode;
        } 

        uint bets = fightBet[tokenId];
        if (bets != bet) {
            fightBet[tokenId] = bet;
        } 

    }

    
    /// @dev
    ///
    ///
    function fight(uint tokenId) public { 


    }


    /// @dev
    ///
    ///
    function fightWithOpponent(uint starter, Ability memory starterAbility, uint opponent, Ability memory opponentAbility, uint bets) private {

        uint starterPoints = 3;

        if (starterAbility.affection > opponentAbility.affection) {
            starterPoints += 1;
        } else if (starterAbility.affection < opponentAbility.affection) {
            starterPoints -= 1;
        }

        if (starterAbility.resistance > opponentAbility.resistance) {
            starterPoints += 1;
        } else if (starterAbility.resistance < opponentAbility.resistance) {
            starterPoints -= 1;
        }

        if (starterAbility.damage > opponentAbility.damage) {
            starterPoints += 1;
        } else if (starterAbility.damage < opponentAbility.damage) {
            starterPoints -= 1;
        }

        
        if (starterPoints >= 3) {
            // winner is starter
            handleWinner(starter, bets);
            handleLoser(opponent, bets);
        } else {
            // winner is opponent
            handleWinner(opponent, bets);
            handleLoser(starter, bets);
        }


    }

    


    function handleWinner(uint tokenId, uint bets) private {
        

        address theOwner = ownerOf(tokenId);
        withdrawable[theOwner] += bets;
        uint256 burnAmount = bets * 10 ** 18  ;
        // IERC20(_TOKEN).burn(burnAmount);
        
    }

    function handleLoser(uint tokenId, uint bets) private {
        address mechaOwner = ownerOf(tokenId);
        fightBalance[tokenId] -= bets;
        if (fightBalance[tokenId] < fightBet[tokenId]) {
            fightingTokens.remove(tokenId);
            tokenMode[tokenId] = 0;
            miningTimestamp[tokenId] = 0;
        }

    }


    function claimRewards(uint tokenId) public {
        // ((2/86400) * (time2-time1)));
        uint lastUpdateTime = miningTime[tokenId];
        uint mode = tokenMode[tokenId];
    }




    
    function withdraw() public {
        address withdrawUser = msg.sender;
        uint256 totalFee = withdrawable[withdrawUser];
        if (totalFee> 0) {
            IERC20(_TOKEN).transferFrom(address(this), withdrawUser, totalFee);
            withdrawable[withdrawUser] = 0;
        }
    } 



    function burnToken(uint tokenId) public {
        // is owner
        



    }


    function assignEnergy(uint tokenId, uint ability, uint points)  public {
        

        // approve owner
        // ability available
        // assign ability
        // remove points

    }


    

}