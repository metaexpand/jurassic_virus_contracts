// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IERC20Burnable.sol";
import "hardhat/console.sol";

/**
    1. 代理合约，让合约可以升级
 */
contract JurassicVirusNFT is ERC721Burnable, AccessControl {

    /// @dev Library 
    ////////////////////////////////////////////
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;


    /// @dev structs of the Game.
    ////////////////////////////////////////////
    struct Ability {
        uint256 strength;
        uint256 explosive;
        uint256 agility;
    }


    /// @dev all events in the Pumk Runner Game.
    ////////////////////////////////////////////
    event WithdrawEvent(address withdrawWallet, uint256 withdrawAmount, uint256 withdrawTimestamp); 

    event FightEvent(uint256 winNFT, uint256 loseNFT, uint256 bets, Ability winnerAbility, Ability loserAbility, uint256 fightTimestamp); 

    event ChargeEvent(address payWallet, uint256 chargeNFT, uint256 chargeAmount, uint256 chargeTimestamp);

    event PurchaseEvent(address purchaseWallet, uint256 purchaseAmount, uint256 purchaseTimestamp);

    event LevelUPEvent(uint256 nftID, uint256 originLevel, uint256 updatedLevel, uint256 levelUpTimestamp);

    event ModeChangeEvent(int256 nftID, uint256 originalMode, uint256 changedMode, uint256 changeTimestamp);

    event BurnNFTEvent(int256 nftID, uint256 burnedTimestamp);
    ////////////////////////////////////////////


    /// @dev All constant defination
    ////////////////////////////////////////////
    bytes32 public constant OPERATION_ROLE = keccak256("OPERATION_ROLE"); 

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); 
    
    uint256 public constant TOTAL_SUPPLY = 3333;

    uint256 public constant PRICE = 0.06 ether; 

    uint256 public constant BURN_POINTS = 10;

    ///  add constant 
    address private _TOKEN = 0xd906643B897dC7E9380ADebaCB011e6eF39403Dd;
    ////////////////////////////////////////////

    
    /// @dev public variable for business
    ////////////////////////////////////////////
    Counters.Counter private _totalSold;
    /// @dev notice upgrade token

    bool private IS_SELLING = true;

    EnumerableSet.UintSet fightingNFTs;
    
    uint256 randNonce = 0;

    /// @dev 
    mapping(uint256=>Ability) abilityOfNFT;

    mapping(address=>EnumerableSet.UintSet) ownedNFTs;

    /// @dev NFT ID => start mining time / purchase time
    mapping(uint256=>uint256) miningTimestamp;

    /// @dev NFT ID => 1(Nomal Mode)  2(Fight Mode)
    mapping(uint256=>uint256) modeOfNFT;

    /// @dev NFT ID => level, default 0, max 5
    mapping(uint256=>uint256) levelOfNFTs;

    /// @dev withdrawable tokens
    mapping(address=>uint256) withdrawableToken;

    /// token => fight balance 
    mapping(uint256=>uint256) fightBalance;

    /// token => bets how many token will to pay for the fight round
    mapping(uint256=>uint256) fightBet;

    /// wallet=>points
    mapping(address=>uint256) nftPoints;

    /// functions 
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /// NFT Related
    ////////////////////////////////////////////////////////////////////////

    constructor() ERC721("PumkRunner", "PRR") {
        _setupRole(OPERATION_ROLE, msg.sender);
    }

    /// @dev mint one token one time
    ///
    function _mintOne(address _to, uint256 _tokenId) private {
        _totalSold.increment();
        _safeMint(_to, _tokenId);
    }


    /// @dev total sold
    function totalSold() public view returns (uint256) {
        return _totalSold.current();
    }


    function isEnoughSupply(uint256 amount, bool needReportError) private view returns (bool) {
        uint256 solded = totalSold(); 
        uint256 afterPurchase = solded + amount;
        if (needReportError) {
            require(afterPurchase <= TOTAL_SUPPLY, "Max limit");
            return true;
        } else {
            if (afterPurchase <= TOTAL_SUPPLY) {
                return true;
            } else {
                return false;
            }
        }
    }

    function baseRequire(uint256 amount) private view {

        require(IS_SELLING == true, "Not start selling yet(1)");
        require(amount >= 1, "at least purchase 1");
        require(amount <= 10, "at most purchase 10");
        require(msg.value >= (PRICE * amount), "insufficient value"); // must send 10 ether to play

        isEnoughSupply(amount, true);
    }



    /// @dev inner method to verify the owner of the token
    function isOwner(uint256 nftID, address owner) private view returns(bool isNFTOwner) {
        address tokenOwner = ownerOf(nftID);        
        isNFTOwner = (tokenOwner == owner);

    } 


    /// @dev mint function
    /// 
    function mintToAddress(address purchaseUser, uint256 amount) private {

        EnumerableSet.UintSet storage nftSet = ownedNFTs[purchaseUser];
        
        for (uint256 i=0; i<amount; i++) {
            uint256 tokenId = _totalSold.current() + 1;
            _mintOne(purchaseUser, tokenId);
            nftSet.add(tokenId);
        }

        // emit PurchaseNotification(purchaseUser, category, amount, block.timestamp);
    }


    /// @dev
    /// 
    function listMyNFT() external view returns (uint256[] memory tokens) {

        address walletAddress = msg.sender;

        EnumerableSet.UintSet storage nftSets = ownedNFTs[walletAddress];

        tokens = nftSets.values();

    }


    /// @dev 
    function purchaseNFT(uint256 amount) external payable {

        address purchaseUser = msg.sender;
        baseRequire(amount);
        mintToAddress(purchaseUser, amount);

    }

    /// @dev 
    /// todo add limitation
    function updateToken(address tokenAddr) public {
        _TOKEN = tokenAddr;
    }

    /// GameFi Related
    ////////////////////////////////////////////////////////////////////////

    function random(uint256 randomSeed, uint256 lrange, uint256 mrange) internal returns (uint) {
        randNonce++; 
        uint256 randomnumber = uint(keccak256(abi.encodePacked(randNonce, randomSeed, msg.sender ,block.timestamp, block.difficulty))) % (mrange - lrange + 1);
        randomnumber = randomnumber + lrange;
        return randomnumber;
    }


    /// @dev
    function queryNextLevelTokenRequire(uint256 nftID) public view returns (uint256 requirement) {
        uint256 currentLevel = levelOfNFTs[nftID];
        require (currentLevel + 1 <= 5, "already top level");
        requirement = requiredUpdateTokens(currentLevel + 1);

    }

    /// @dev
    function requiredUpdateTokens(uint256 levelState) public pure returns (uint256 tokenAmount) {

        require(levelState>=1 && levelState<=5, " - level should be 1 - 5");

        tokenAmount = 0;

        if (levelState == 1) {
            tokenAmount = 500;
        }
        if (levelState == 2) {
            tokenAmount = 1200;
        }
        if (levelState == 3) {
            tokenAmount = 2000;
        }
        if (levelState == 4) {
            tokenAmount = 3000;
        }
        if (levelState == 5) {
            tokenAmount = 5000;
        }

    }

    /// @dev
    function queryLevel(uint256 nftID) public view returns (uint256 level) {
        level = levelOfNFTs[nftID];
    }
    

    /// @dev 
    ///
    function updateLevel(uint256 nftID) public {
        
        require(isOwner(nftID, msg.sender), "only owner can update");

        uint256 nextLevelTokens = queryNextLevelTokenRequire(nftID);

        require(nextLevelTokens > 0, "can not update anymore");

        // transfer token according 
        // @todo 

        // random ability order
        uint256 abilityCount = random(nftID + nextLevelTokens + totalSold() , 80, 130);
        uint256 ability1 = random(abilityCount, 0, abilityCount);
        uint256 ability2 = random(abilityCount - ability1, 0, abilityCount - ability1);
        uint256 ability3 = abilityCount - ability1 - ability2;

        require((ability1 + ability2 + ability3) == abilityCount, "Should be equals");
        require(abilityCount >= 80, "Should be more than 80");
        require(abilityCount <= 130, "Should be less than 130");


        Ability storage ability = abilityOfNFT[nftID];
        ability.strength += ability1;
        ability.explosive += ability2;
        ability.agility += ability3;

        // level up
        levelOfNFTs[nftID]++;

        // add fight balance (80% for fight balance)

        fightBalance[nftID] += nextLevelTokens * 80 / 100;

        console.log("NFT: %s,  balance: %s", nftID, fightBalance[nftID]);

        // burn 20% 
        burnToken(nextLevelTokens/100*20);
        
        console.log("after update,  strength: %s, explosive: %s, agility: %s", ability.strength, ability.explosive, ability.agility);

    }



    /// @dev burn the token
    function burnToken(uint256 amount) private {
        // IERC20Burnable(_TOKEN).burn(amount);
    }

    
    /// 进入战斗模式，需要扣除400点
    /// 战斗装甲 点击战斗 - 取消战斗 战斗一次
    /// 自己设置战斗的UNION金额 100的倍数 
    /// 输赢点数根据低点用户的划分

    /// @param nftID token id
    /// @param nMode 0=not start, 1=normal, 2=fighting
    /// @param bets lowest bet
    function startMode(uint256 nftID, uint256 nMode, uint256 bets) public {
        /// require token owner
        require(isOwner(nftID, msg.sender));

        /// valid level
        require(queryLevel(nftID) > 0, "Level should be at least 1");

        /// valid fight balance
        require(fightBalance[nftID] >= bets, "fight balance is not enough");

        /// require valid mode
        require(nMode == 1 || nMode == 2, "Wrong Mode");
 
        uint256 mode = modeOfNFT[nftID];
        if (mode != nMode) {
            // new mode should claim rewards first
            // then calculate based new mode;
            claimRewards(nftID);
            modeOfNFT[nftID] = nMode;

        } 
        
        if (nMode == 1) {
            fightBet[nftID] = 0;
            // if exist
            fightingNFTs.remove(nftID);
        } 

        if (nMode == 2) {
            uint256 nftLevel = levelOfNFTs[nftID];
            require(nftLevel > 0, "require level up");

            require (bets % 100 == 0, "bets setting error");
            fightBet[nftID] = bets;
            // if not exist
            fightingNFTs.add(nftID);
            if (fightingNFTs.length() > 1) {
                // trigger fight
                fight(nftID);
            }
            
        }
    }

    

    ///    战斗随机挑选中的对手 
    ///    可以手动执行战斗
    /// 战斗 80% - 同级对手 15% 一级差距对手 5% 2级差距对手 
    /// 如果打平，则发起人获胜
    function fight(uint256 nftID) public { 

        require(isOwner(nftID, msg.sender), "only owner can fight");        
        uint256 requireLevelGap = decideLevelGap(nftID);
        // search opponent （level / bet amount match)
        (uint256 opponentNFT, uint256 finalBets) = searchForOpponent(nftID, requireLevelGap);
        // // if it's not 0
        // // opponent level confirmed
        console.log("fight status -- [NFT: %s, OpponentNFT: %s, Bets: %s]", nftID, opponentNFT, finalBets);
        fightWithOpponent(nftID, opponentNFT, finalBets);

    }


    /// @dev
    function decideLevelGap(uint256 nftID) private returns (uint256 requireLevelGap) {
        uint256 i = fightingNFTs.length();
        uint256 opponentLevelSeed = random(i + nftID, 1, 100);
        if (opponentLevelSeed > 70 && opponentLevelSeed <= 90) {
            requireLevelGap = 1;
        } else if (opponentLevelSeed > 90 && opponentLevelSeed < 100) {
            requireLevelGap = 2;
        }

    }

    /// @dev 
    function searchForOpponent(uint256 nftID, uint256 levelGap) private returns (uint256 opponentNFT, uint256 finalBets) {

        require(fightingNFTs.length() > 1, "waiting for more opponents");
        
        uint256 lastIndex = fightingNFTs.length();
        uint256 startOpponentIndex = random(lastIndex + nftID, 1, lastIndex - 1);        
        uint256 originalStartOpponentIndex = startOpponentIndex;
        uint256 myBets = fightBet[nftID];
        uint256 loopTime = 0;
        uint256 starterNFTLevel = levelOfNFTs[nftID];

        while (loopTime < 100) {
            loopTime ++;
            startOpponentIndex++;
            if (startOpponentIndex == lastIndex) {
                startOpponentIndex = 0;
            }
            // loop finished
            if (startOpponentIndex == originalStartOpponentIndex) {
                break;
            }
            // if it's the owner self continue;
            // level match
console.log("before at fightingNFTS: %s, totalLength: %s", startOpponentIndex, fightingNFTs.length());
            opponentNFT = fightingNFTs.at(startOpponentIndex);
console.log("after at fightingNFTS: %s, totalLength: %s", startOpponentIndex, fightingNFTs.length());
            
            uint256 opponentNFTLevel = levelOfNFTs[opponentNFT];

            if (starterNFTLevel > opponentNFTLevel && (starterNFTLevel - opponentNFTLevel != levelGap)) {
                continue;
            }

            if (starterNFTLevel < opponentNFTLevel &&  (opponentNFTLevel - starterNFTLevel) != levelGap) {
                continue;
            }

            if (starterNFTLevel == opponentNFTLevel && levelGap != 0) {
                continue;
            }

            console.log("length: %s, index is: %s, gap: %s",lastIndex,startOpponentIndex, levelGap);
            console.log("MyNFT  %s - %s", nftID,starterNFTLevel);
            console.log("OpponentNFT %s - %s", opponentNFT,opponentNFTLevel);
            
            uint256 opponentBets = fightBet[opponentNFT];
            console.log("Bets compare  %s - %s", myBets,opponentBets);

            if (myBets > opponentBets) {
                finalBets = opponentBets;
            } else {
                finalBets = myBets;
            }

            break;
        }
    }

    /// @dev
    function fightWithOpponent(uint256 starter, uint256 opponent, uint256 bets) private {
        
        Ability memory starterAbility = abilityOfNFT[starter];
        Ability memory opponentAbility = abilityOfNFT[opponent];

        // 对比3项数值

        uint256 starterPoints = 3;

        if (starterAbility.strength > opponentAbility.strength) {
            starterPoints += 1;
        } else if (starterAbility.strength < opponentAbility.strength) {
            starterPoints -= 1;
        }

        if (starterAbility.explosive > opponentAbility.explosive) {
            starterPoints += 1;
        } else if (starterAbility.explosive < opponentAbility.explosive) {
            starterPoints -= 1;
        }

        if (starterAbility.agility > opponentAbility.agility) {
            starterPoints += 1;
        } else if (starterAbility.agility < opponentAbility.agility) {
            starterPoints -= 1;
        }

        
        if (starterPoints >= 3) {
            // winner is starter
            uint256 winRewards = handleLoser(opponent, bets);
            handleWinner(starter, winRewards);
            
        } else {
            // winner is opponent
            uint256 winRewards = handleLoser(starter, bets);
            handleWinner(opponent, winRewards);

        }

    }



    /// 赢家的收益12%交税Burn掉
    function handleWinner(uint256 nftID, uint256 bets) private {
        
        address nftOwner = ownerOf(nftID);
        // 胜者获得上限低的那集奖励
        withdrawableToken[nftOwner] += bets;
        uint256 burnAmount = bets;
        burnToken(burnAmount);
    }


    /// @dev
    function handleLoser(uint256 nftID, uint256 bets) private returns(uint256 loseTokens){

        // 战败扣除相应的余额
        if(fightBalance[nftID] >= bets) {
            fightBalance[nftID] -= bets; 
            loseTokens = bets;
        } else {
            loseTokens = fightBalance[nftID];
            fightBalance[nftID] = 0;
        }
        
        // 余额不足下线战斗模式
        if (fightBalance[nftID] < fightBet[nftID]) {
            fightingNFTs.remove(nftID);
            modeOfNFT[nftID] = 0;
            miningTimestamp[nftID] = block.timestamp;

            // 没有Claim出来的UNION是否销毁？@todo

        } 

    }


    function claimRewards(uint256 nftID) public {

        // ((2/86400) * (time2-time1)));

        require(isOwner(nftID, msg.sender), "only owner can claim");

        address nftOwner = ownerOf(nftID);
        
        uint256 perDayAmount = calculatePerDayRewards(nftID);

        uint256 lastUpdateTime = miningTimestamp[nftID];
        // uint256 mode = modeOfNFT[nftID];
        uint256 rewards = (perDayAmount*10**18);

        uint256 rewardsPerDay = rewards / 86400;

        uint256 totalRewards = (rewardsPerDay * (block.timestamp - lastUpdateTime));

        withdrawableToken[nftOwner] += totalRewards;

        miningTimestamp[nftID] = block.timestamp;

    }


    function calculatePerDayRewards(uint256 nftID) private view returns(uint256 rewardsPerDay) {

        uint256 mode = modeOfNFT[nftID];
        uint256 level = levelOfNFTs[nftID];

        if (mode == 1) {            
            rewardsPerDay = level + 2;
        } else if (mode == 2) {
            if (level == 1) {
                rewardsPerDay = 5;
            }
            else if (level == 2) {
                rewardsPerDay = 8;
            }
            else if (level == 3) {
                rewardsPerDay = 10;
            }
            else if (level == 4) {
                rewardsPerDay = 15;
            }
            else if (level == 5) {
                rewardsPerDay = 20;
            }
        }
    }

    /// @dev
    /// 
    function queryAbility(uint256 nftID) public view returns(Ability memory ability) {
        require(_exists(nftID), "require exists!");
        ability = abilityOfNFT[nftID];
    }


    /// @dev recharge badges into package so the Pumk Runner can fight 
    /// 
    function recharge(uint256 nftID, uint256 amount) public {
    
        address chargeUser = msg.sender;
        require(amount / (100 * 10 ** 18) == 0, "require % 100 == 0");
        uint256 totalFee = amount;
        uint256 walletBalance = IERC20(_TOKEN).balanceOf(chargeUser);

        require(walletBalance >= totalFee, "insufficient token balance"); 
        IERC20(_TOKEN).transferFrom(chargeUser, address(this), totalFee);
        fightBalance[nftID] += amount;

    }


    /// @dev 
    /// 
    /// 
    function withdrawToken() public {
        address withdrawUser = msg.sender;
        uint256 totalFee = withdrawableToken[withdrawUser];
        if (totalFee> 0) {
            IERC20(_TOKEN).transferFrom(address(this), withdrawUser, totalFee);
            withdrawableToken[withdrawUser] = 0;
            emit WithdrawEvent(withdrawUser, totalFee, block.timestamp); 
        }
    } 


    /// Burn 基础装甲获取随机分配属性值（12点）
    function burnNFT(uint256 nftID) external {
        // is owner
        require(isOwner(nftID, msg.sender), "Only owner can burn");
        
        nftPoints[msg.sender] += BURN_POINTS;

        burn(nftID);
    }


    /// @dev 
    function queryPoints(address user) external view returns (uint256 points){
        points = nftPoints[user];
    }


    /// @dev assign energy
    /// @param ability  1=strength, 2=explosive, 3=agility
    function assignEnergy(uint256 nftID, uint256 ability, uint256 points) public {
        address user = msg.sender;
        // approve owner
        require(nftPoints[user] >= points, "Points is not enough");
        // ability available
        require(ability == 1 || ability == 2 || ability == 3, "Ability is not correct");
        // assign ability
        Ability storage nftAbility = abilityOfNFT[nftID];
        if (ability == 1) {
            nftAbility.strength += points;
        }
        else if (ability == 2) {
            nftAbility.explosive += points;
        }
        else if (ability == 3) {
            nftAbility.agility += points;
        }        
        // remove points
        nftPoints[user] -= points;
    }


    function queryWithdrawToken(address wallet) public view returns(uint256 tokenRemain) {
        tokenRemain = withdrawableToken[wallet];
    }

    function queryMyWithdrawToken() public view returns(uint256 tokenRemain) {
        tokenRemain = withdrawableToken[msg.sender];
    }

    function queryFightBalance(uint256 nftID) external view returns (uint256 fightRemain) {
        fightRemain = fightBalance[nftID];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId); 
    }
}