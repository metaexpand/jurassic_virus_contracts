// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IERC20Control.sol";
import "hardhat/console.sol";

///
///
///
contract JurassicVirusNFT is ERC721Burnable, AccessControl {

    /// @dev Library
    ////////////////////////////////////////////
    using EnumerableSet for EnumerableSet.UintSet;
    
    /// @dev structs of the Game.
    ////////////////////////////////////////////
    struct Ability {
        uint256 lethality;
        uint256 infectivity;
        uint256 resistance;
    }

    /// @dev all events in the Punk Runner Game.
    ////////////////////////////////////////////
    /// @dev combine event
    /// @param eventType    different eventType read different parameter:
    ///                     1=claim, user=withdraw user, amount=withdrawAmount
    ///                     2=Fight nft1ID=Win, nft2ID=Lose, amount=bets
    ///                     3=Charge nft1ID=Charge target, user=charge wallet, amount=charge amount                     
    ///                     5=LevelUp nft1ID=targetNFT, status=final level
    ///                     6=Mode Change nft1ID=changed nftID, status=final Mode
    ///                     7=Burn nft1ID=targetID
    ///                     8=Search Opponent nft1ID=targetID, nft2ID=opponentID, status=1 find, 0=not find
    event CommonEvent(
        address indexed from,
        uint256 indexed eventType, 
        uint256 nft1ID, 
        uint256 nft2ID, 
        uint256 amount, 
        uint256 status, 
        uint256 eventTimestamp
    );

    event PurchaseEvent(address purchaseWallet, uint256 nftID, uint256 purchaseTimestamp);
    ////////////////////////////////////////////

    /// @dev All constant defination
    ////////////////////////////////////////////

    /// @dev admin role defination
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    uint256 public constant TOTAL_SUPPLY = 555;

    uint256 public constant PRICE = 0.0003 ether;

    address public constant WITHDRAW_ADDRESS = 0xeC3600f2BAE175cf0e35C04607ba4cCb5532348d;

    /// @dev token contract
    address private _TOKEN = 0xBd8D2baDc742cADBC86FF89C6670B25F343c3eAd;
    ////////////////////////////////////////////


    /// @dev public variable for business
    ////////////////////////////////////////////

    /// @dev how many NFTs have been sold
    uint256 private _totalSold;

    /// @dev notice upgrade token
    bool private IS_SELLING = true;

    /// @dev fight mode will be put here
    EnumerableSet.UintSet private fightingNFTs;
    
    /// @dev random seed
    uint256 private randNonce = 0;

    /// @dev structs of ability
    mapping(uint256=>Ability) private abilityOfNFT;

    mapping(address=>EnumerableSet.UintSet) private ownedNFTs;

    /// @dev NFT ID => start mining time / purchase time
    mapping(uint256=>uint256) private miningTimestamp;

    /// @dev NFT ID => 1(Nomal Mode)  2(Fight Mode)
    mapping(uint256=>uint256) private modeOfNFT;

    /// @dev NFT ID => level, default 0, max 5
    mapping(uint256=>uint256) private levelOfNFTs;

    /// @dev token => fight balance 
    mapping(uint256=>uint256) private tokenFightBalance;

    /// @dev token => balance (withdrawable)
    mapping(uint256=>uint256) private tokenBalance;

    /// @dev token => bets how many token will to pay for the fight round
    mapping(uint256=>uint256) private fightBet;

    /// @dev wallet=>points
    mapping(address=>uint256) private nftPoints;

    // bool private REVEALED = false;

    string private BASE_URI = "https://gateway.pinata.cloud/ipfs/QmbEo9Lty8b1rmuEQ9jJR6imZrk7cC46K9Vgsqpjxdso8m/";

    /// functions
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////


    /// NFT Related
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    constructor() ERC721("Jurassic Virus", "JVN") {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "token is not exist!");
        uint256 tokenLevel = levelOfNFTs[tokenId];
        return string(abi.encodePacked(BASE_URI, Strings.toString(tokenLevel)));
    }


    /// @dev total sold
    /// @return total sold amount
    function totalSold() public view returns (uint256) {
        return _totalSold;
    }


    /// @dev check if we have storage for the purchase
    function isEnoughStorage(uint256 amount) private view returns (bool) {
        uint256 solded = totalSold();
        uint256 afterPurchase = solded + amount;
        require(afterPurchase <= TOTAL_SUPPLY, "Max limit");
    }


    function queryPurchaseTotalFee(uint256 amount) public view returns (uint256 totalFee) {
        // price validate
        totalFee = (PRICE * amount);
    }

    
    function purchaseValidate(address purchaseUser, uint256 amount) private view {
        // basic validate
        require(IS_SELLING == true, "Not start selling yet(1)");
        require(amount >= 1, "at least purchase 1");
        require(amount <= 10, "at most purchase 10");
        // console.log("current owned %s", ownedNFTs[purchaseUser].length());
        // require(ownedNFTs[purchaseUser].length() + amount <= 20, "purchase over is limite");
        isEnoughStorage(amount);
        require(msg.value >= (PRICE * amount), "insufficient value");
    }


    /// @dev inner method to verify the owner of the token
    function isOwner(uint256 nftID, address owner) public view returns(bool isNFTOwner) {
        address tokenOwner = ownerOf(nftID);
        isNFTOwner = (tokenOwner == owner);
    }


    /// @dev mint function
    function mintToAddress(address purchaseUser, uint256 amount) private {
        EnumerableSet.UintSet storage nftSet = ownedNFTs[purchaseUser];
        uint256 currentTokenId = _totalSold;
        for(uint256 i=0; i<amount; i++){
            // do mint
            currentTokenId = currentTokenId + 1;
            _safeMint(purchaseUser, currentTokenId);
            nftSet.add(currentTokenId);

            _upgrade(currentTokenId);
            // rewards
            uint256 PER_NFT_PURCHASED_REWARDS = 150 * 10 ** 18;
            tokenFightBalance[currentTokenId] = PER_NFT_PURCHASED_REWARDS;
            // emit PurchaseEvent(purchaseUser, currentTokenId, block.timestamp);
        }
        _totalSold = currentTokenId;
    }

    /// @dev show all purchased nfts by Arrays
    /// @return tokens nftID array
    function listMyNFT() external view returns (uint256[] memory tokens) {
        address walletAddress = msg.sender;
        EnumerableSet.UintSet storage nftSets = ownedNFTs[walletAddress];
        tokens = nftSets.values();
    }


    /// @dev show all purchased nfts by Arrays
    /// @return tokens nftID array
    function listNFT(address wallet) external view returns (uint256[] memory tokens) {
        EnumerableSet.UintSet storage nftSets = ownedNFTs[wallet];
        tokens = nftSets.values();
    }


    /// @dev user doing purchase
    /// @param amount how many
    function purchaseNFT(uint256 amount) external payable {

        address purchaseUser = msg.sender;
        purchaseValidate(purchaseUser, amount);
        mintToAddress(purchaseUser, amount);
    }




    /// GameFi Related
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /// @dev claim token(after claim, need to withdraw to wallet)
    /// @param nftID the one try to claim TOKEN
    /// @param triggerFight true=trigger fight, false=no
    function claimRewards(uint256 nftID, bool triggerFight) public {
        // ((2/86400) * (time2-time1)));
        require(isOwner(nftID, msg.sender), "only owner can claim");

        pureClaim(nftID);

        if (triggerFight) {
            uint256 mode = modeOfNFT[nftID];
            if (mode == 2) {
                _fight(nftID);
            }
        }
    }

    /// @dev query how much token needed for next level
    function queryNextLevelTokenRequire(uint256 nftID) public view returns (uint256 requirement) {
        uint256 currentLevel = levelOfNFTs[nftID];
        requirement = requiredUpdateTokens(currentLevel + 1);
    }

    /// @param nftID token id
    /// @param nMode 0=not start, 1=normal, 2=fighting
    /// @param bets lowest bet
    function startMode(uint256 nftID, uint256 nMode, uint256 bets) public {
        /// require token owner
        require(isOwner(nftID, msg.sender), "only owner can change mode");

        _updateBets(nftID, bets);

        bool isChanged = _changeMode(nftID, nMode);
        if (isChanged) {
            if (nMode == 2) {
                _fight(nftID);
            }
        }
        emit CommonEvent(msg.sender, 6, nftID, 0, 0, nMode, block.timestamp);
    }

    /// @dev start fight
    /// @param nftID the owner's nft trying to fight
    function positiveFight(uint256 nftID, uint256 bets) public {
        require(isOwner(nftID, msg.sender), "only owner can change mode");

        _updateBets(nftID, bets);

        _fight(nftID);

    }

    /// @dev query how many token needed to upgrade
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
        // for test
        // tokenAmount = 1000;
        tokenAmount = tokenAmount * 10 ** 18;
    }

    /// @dev query the level of the NFT
    /// @param nftID the token id
    function queryLevel(uint256 nftID) public view returns (uint256 level) {
        level = levelOfNFTs[nftID];
    }

    /// @dev query the next level of NFT
    function queryNextLevel(uint256 nftID) public view returns(uint256 nextLevel) {
        nextLevel = queryLevel(nftID) + 1;

    }

    // @dev try to update NFT level
    // @param nftID the token want to update
    function updateLevel(uint256 nftID, uint256 bets) public {

        require(isOwner(nftID, msg.sender), "only owner can update");
        require(isUpgradeable(nftID), "can't upgrade anymore");
        
        uint256 targetLevel = queryNextLevel(nftID);
        payForUpgrade(nftID, targetLevel);
        // random ability order
        _upgrade(nftID);
        // 
        startMode(nftID, 2, bets);
        // emit LevelUPEvent(nftID, currentLevel, currentLevel + 1, block.timestamp);
        emit CommonEvent(msg.sender, 5, nftID, 0, 0, targetLevel, block.timestamp);
    }

    /// @dev query how many token can claim for rewards
    /// @param nftID target nft 
    function queryClaimableRewards(uint256 nftID) public view returns(uint256 totalRewards) {

        uint256 perDayRewards = calculatePerDayRewards(nftID);
        uint256 lastUpdateTime = miningTimestamp[nftID];
        if (lastUpdateTime == 0) {
            totalRewards = 0;
            return totalRewards;
        }
        uint256 secondRewards = perDayRewards / 86400;
        totalRewards = (secondRewards * (block.timestamp - lastUpdateTime)); 

    }

    /// @dev calculate rewards
    function calculatePerDayRewards(uint256 nftID) public view returns(uint256 rewardsPerDay) {

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
        rewardsPerDay = rewardsPerDay * 10 ** 18;
    }


    /// @dev check ability of the NFT
    /// @param nftID query target
    function queryAbility(uint256 nftID) public view returns(Ability memory ability) {
        // require(_exists(nftID), "require exists!");
        ability = abilityOfNFT[nftID];
    }



    /// @dev query how many points user can be used to assign
    /// @param user query user
    function queryPoints(address user) external view returns (uint256 points){
        points = nftPoints[user];
    }


    /// @dev recharge into NFT
    /// @param nftID the nft
    /// @param totalFee charge amount
    function recharge(uint256 nftID, uint256 totalFee, uint256 bets) public {
    
        address chargeUser = msg.sender;
        require(totalFee % (100 * 10 ** 18) == 0, "require % 100 == 0");

        uint256 walletBalance = IERC20(_TOKEN).balanceOf(chargeUser);
        require(walletBalance >= totalFee, "insufficient token balance");
        IERC20(_TOKEN).transferFrom(chargeUser, address(this), totalFee);
        tokenBalance[nftID] += totalFee;

        startMode(nftID, 2, bets);
        // emit ChargeEvent(chargeUser, nftID, amount, block.timestamp);
        emit CommonEvent(chargeUser, 3, nftID, 0, totalFee, 0, block.timestamp);

    }


    /// @dev withdraw token
    function withdrawToken(uint256 nftID, uint256 withdrawAmount) public {
        address withdrawUser = msg.sender;
        uint256 balance = tokenBalance[nftID];

        if (withdrawAmount > 0 && withdrawAmount <= balance) {
            address nftOwner = ownerOf(nftID);
            if (nftOwner == withdrawUser) {
                IERC20Control(_TOKEN).mint(withdrawUser, withdrawAmount);
                tokenBalance[nftID] = balance - withdrawAmount;

                uint256 mode = modeOfNFT[nftID];
                if (mode == 2 && queryFightBalance(nftID) < fightBet[nftID]) {
                    // reset status
                    startMode(nftID, 0, 0);
                } 
                emit CommonEvent(withdrawUser, 1, 0, 0, withdrawAmount, 0, block.timestamp);
            }
            // emit WithdrawEvent(withdrawUser, totalFee, block.timestamp);

        }
    }

    /// @dev Burn nft to get points
    /// @param nftID burned NFT id
    function burnNFT(uint256 nftID) external {
        // is owner
        require(isOwner(nftID, msg.sender), "Only owner can burn"); 
        uint256 BURN_POINTS = 10;
        nftPoints[msg.sender] += BURN_POINTS;
        burn(nftID);
        EnumerableSet.UintSet storage nftSets = ownedNFTs[msg.sender];
        nftSets.remove(nftID);
        // emit BurnNFTEvent(nftID, block.timestamp);
        emit CommonEvent(msg.sender, 7, nftID, 0, 0, 0, block.timestamp);
    }

    /// @dev query which mode current is
    /// @param nftID target nft 
    function queryMode(uint256 nftID) external view returns (uint256 mode){
        mode = modeOfNFT[nftID];
    }

    /// @dev query total fight balance (include reward's and charged)
    /// @param nftID target nft 
    function queryFightBalance(uint256 nftID) public view returns(uint256 balance) {
        balance = tokenFightBalance[nftID] + tokenBalance[nftID];
    }

    /// @dev query query balance only for fight
    /// @param nftID target nft 
    function queryTokenFightBalance(uint256 nftID) public view returns(uint256 balance) {
        balance = tokenFightBalance[nftID];
    }

    /// @dev query charged balance (can withdraw)
    /// @param nftID target nft 
    function queryTokenBalance(uint256 nftID) external view returns (uint256 balance){
        balance = tokenBalance[nftID];
    }

    /// @dev query how much pay or get after fight
    /// @param nftID target nft 
    function queryBounty(uint256 nftID) external view returns (uint bounty) {
        bounty = fightBet[nftID];
    }

    /// @dev 
    /// @param ability1Points strength
    /// @param ability2Points explosive
    /// @param ability3points agility
    function assignAllEnergy(uint256 nftID, uint256 ability1Points, uint256 ability2Points, uint256 ability3points) external {
        address user = msg.sender;
        // approve owner
        require(nftPoints[user] >= (ability1Points + ability2Points + ability3points), "Points is not enough");
        // assign ability
        Ability storage nftAbility = abilityOfNFT[nftID];
        if (ability1Points > 0) {
            nftAbility.lethality += ability1Points;
        }
        if (ability2Points > 0) {
            nftAbility.infectivity += ability2Points;
        }
        
        if (ability3points > 0) {
            nftAbility.resistance += ability3points;
        }
        // remove points
        nftPoints[user] -= (ability1Points + ability2Points + ability3points);
    }





    function payForUpgrade(uint256 nftID, uint256 level) internal {

        uint256 nextLevelTokenRequirement = queryNextLevelTokenRequire(nftID);
        // transfer token
        IERC20(_TOKEN).transferFrom(msg.sender, address(this), nextLevelTokenRequirement);
        // add fight balance (80% for fight balance) 
        tokenFightBalance[nftID] += (nextLevelTokenRequirement * 80 / 100);
        // burn 20%
        burnToken(nextLevelTokenRequirement * 20 / 100);

    }


    function isUpgradeable(uint256 nftID) private returns(bool canUpgrade) {
        canUpgrade = !(queryNextLevel(nftID) > 5);
    }

    function _upgrade(uint256 nftID) private returns(uint256 nextLevelToken) {

        require(isUpgradeable(nftID), "can not update anymore");

        uint256 lowBorder = 80;
        uint256 highBorder = 130;
        uint256 abilityCount = random(nftID + totalSold(), lowBorder, highBorder);

        uint256 ability1 = random(abilityCount, 0, abilityCount);
        uint256 ability2 = random(abilityCount - ability1, 0, abilityCount - ability1);
        uint256 ability3 = abilityCount - ability1 - ability2;

        require((ability1 + ability2 + ability3) == abilityCount, "Should be equals");
        require(abilityCount >= lowBorder, "Should be more than 80");
        require(abilityCount <= highBorder, "Should be less than 130");

        Ability storage ability = abilityOfNFT[nftID];
        ability.lethality += ability1;
        ability.infectivity += ability2;
        ability.resistance += ability3;

        // level up
        levelOfNFTs[nftID]++;
        // console.log("after update,  lethality: %s, infectivity: %s, resistance: %s", ability.lethality, ability.infectivity, ability.resistance);
    }

    function transferTo(uint256 tokenAmount, address sender, address target) private {
        require(tokenAmount > 0, "need to be more than 0");
        // uint256 actualFee = calculateTransferedToken(tokenAmount);
        // transfer token
        IERC20(_TOKEN).transferFrom(sender, target, tokenAmount);
    }

    /// @dev burn the token
    function burnToken(uint256 amount) private {
        IERC20Control(_TOKEN).burn(amount);
    }




    function _changeMode(uint256 nftID, uint256 nMode) private returns (bool isChanged) {
        /// require valid mode
        require(nMode==0 || nMode == 1 || nMode == 2, "Wrong Mode");
        isChanged = true;
        uint256 mode = modeOfNFT[nftID];
        if (mode == nMode) {
            isChanged = false;
        }
        if (mode != 0 && isChanged) {
            pureClaim(nftID);
        }
        if (isChanged) {
            modeOfNFT[nftID] = nMode;
            if (nMode == 1 || nMode == 0) {
                fightingNFTs.remove(nftID);
            }
        }
    }




    function _updateBets(uint256 nftID, uint256 bets) private {

        uint256 BETS_MAX_LIMIT = 1000 * 10 ** 18;
        uint256 BETS_MIN_LIMIT = 100 * 10 ** 18;

        require(bets <= BETS_MAX_LIMIT, "bets is too many");
        require(bets >= BETS_MIN_LIMIT, "bets is too little");
        require(bets % BETS_MIN_LIMIT == 0, "bet % 100 should be 0");
        if (fightBet[nftID] != bets) {
            fightBet[nftID] = bets;
        }
    }

    
    ///@dev token owner take initiative to fight, it it's even, the one trigger the fight will win.
    ///@param nftID the one trigger the fight
    ///@notice 12% profit'll be burnd, 70% chance to fight with the same level, and 20% and 10% will fight different level's
    function _fight(uint256 nftID) private {

        uint256 requireLevelGap = decideLevelGap(nftID);
        // search opponent （level / bet amount match)
        (uint256 opponentNFT, uint256 finalBets, bool findOpponent) = searchForOpponent(nftID, requireLevelGap);
        // console.log("fight status -- [NFT: %s, OpponentNFT: %s, Bets: %s]", nftID, opponentNFT, finalBets);
        if (findOpponent) {
            emit CommonEvent(msg.sender, 8, nftID, opponentNFT, 0, 1, block.timestamp);
            fightWithOpponent(nftID, opponentNFT, finalBets);
        } else {
            emit CommonEvent(msg.sender, 8, nftID, 0, 0, 0, block.timestamp);
        }
    }


    /// @dev 12% profit'll be burnd, 70% chance to fight with the same level, and 20% and 10% will fight different level's
    function decideLevelGap(uint256 nftID) private returns (uint256 requireLevelGap) {
        uint256 i = fightingNFTs.length();
        uint256 opponentLevelSeed = random(i + nftID, 1, 100);
        if (opponentLevelSeed > 70 && opponentLevelSeed <= 90) {
            requireLevelGap = 1;
        } else if (opponentLevelSeed > 90 && opponentLevelSeed < 100) {
            requireLevelGap = 2;
        }
    }

    /// @dev search for opponents
    function searchForOpponent(uint256 nftID, uint256 levelGap) private returns (uint256 opponentNFT, uint256 finalBets, bool findOpponent) {

        // require(fightingNFTs.length() > 1, "waiting for more opponents");
        if (fightingNFTs.length() <= 1) {
            opponentNFT = 0;
            finalBets = 0;
            findOpponent = false;
            return (opponentNFT, finalBets, findOpponent);
        }

        uint256 lastIndex = fightingNFTs.length();
        uint256 startOpponentIndex = random(lastIndex + nftID, 1, lastIndex - 1);
        uint256 originalStartOpponentIndex = startOpponentIndex;
        uint256 myBets = fightBet[nftID];
        uint256 loopTime = 0;
        uint256 starterNFTLevel = levelOfNFTs[nftID];
        // at most loop 100 time's
        findOpponent = false;
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
            //console.log("before at fightingNFTS: %s, totalLength: %s", startOpponentIndex, fightingNFTs.length());
            opponentNFT = fightingNFTs.at(startOpponentIndex);
            //console.log("after at fightingNFTS: %s, totalLength: %s", startOpponentIndex, fightingNFTs.length());
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

            if (ownerOf(nftID) == ownerOf(opponentNFT)) {
                continue;
            }

            // console.log("length: %s, index is: %s, gap: %s",lastIndex,startOpponentIndex, levelGap);
            // console.log("MyNFT  %s - %s", nftID,starterNFTLevel);
            // console.log("OpponentNFT %s - %s", opponentNFT,opponentNFTLevel);
            
            uint256 opponentBets = fightBet[opponentNFT];
            // console.log("Bets compare  %s - %s", myBets,opponentBets);

            if (myBets > opponentBets) {
                finalBets = opponentBets;
            } else {
                finalBets = myBets;
            }

            findOpponent = true;
            break;
        }
    }

    /// @dev doing fight action
    function fightWithOpponent(uint256 starter, uint256 opponent, uint256 bets) private {
        
        Ability memory starterAbility = abilityOfNFT[starter];
        Ability memory opponentAbility = abilityOfNFT[opponent];
        // compare 3 value and decide the winner
        uint256 starterPoints = 3;

        if (starterAbility.lethality > opponentAbility.lethality) {
            starterPoints += 1;
        } else if (starterAbility.lethality < opponentAbility.lethality) {
            starterPoints -= 1;
        }

        if (starterAbility.infectivity > opponentAbility.infectivity) {
            starterPoints += 1;
        } else if (starterAbility.infectivity < opponentAbility.infectivity) {
            starterPoints -= 1;
        }

        if (starterAbility.resistance > opponentAbility.resistance) {
            starterPoints += 1;
        } else if (starterAbility.resistance < opponentAbility.resistance) {
            starterPoints -= 1;
        }
        if (starterPoints >= 3) {
            // winner is starter
            uint256 winRewards = handleLoser(opponent, bets);
            handleWinner(starter, winRewards);
            address starterOwner = ownerOf(starter);
            address opponentOwner = ownerOf(opponent);
            // emit FightEvent(starter, opponent, bets, starterAbility, opponentAbility, block.timestamp);
            emit CommonEvent(starterOwner, 2, starter, opponent, bets, 1, block.timestamp);
            emit CommonEvent(opponentOwner, 2, starter, opponent, bets, 2, block.timestamp);

        } else {
            // winner is opponent
            address starterOwner = ownerOf(starter);
            address opponentOwner = ownerOf(opponent);
            uint256 winRewards = handleLoser(starter, bets);
            handleWinner(opponent, winRewards);
            // emit FightEvent(opponent, starter, bets, opponentAbility, starterAbility, block.timestamp);
            emit CommonEvent(opponentOwner, 2, opponent, starter, bets, 1, block.timestamp);
            emit CommonEvent(starterOwner, 2, opponent, starter, bets, 2, block.timestamp);
        }

    }

    /// 12% profit'll be burned
    function handleWinner(uint256 nftID, uint256 bets) private {
        // address nftOwner = ownerOf(nftID);
        tokenBalance[nftID] += (bets * 88 / 100);
        uint256 burnAmount = (bets * 12 / 100);
        burnToken(burnAmount);
    }


    /// @dev handle loser business
    function handleLoser(uint256 nftID, uint256 bets) private returns(uint256 loseTokens){

        minusBalance(nftID, bets);
        
        // if balance is not enough, then quit fight mode
        if (queryFightBalance(nftID) < fightBet[nftID]) {
            pureClaim(nftID);
            fightingNFTs.remove(nftID);
            modeOfNFT[nftID] = 0;
        }

        loseTokens = bets;
    }

    function minusBalance(uint256 nftID, uint256 amount) private {
        if (tokenFightBalance[nftID] >= amount) {
            tokenFightBalance[nftID] = tokenFightBalance[nftID] - amount;
            
        } else if(tokenFightBalance[nftID] + tokenBalance[nftID] >= amount) {
            uint256 rewards = tokenFightBalance[nftID];
            tokenFightBalance[nftID] = 0;
            tokenBalance[nftID] = (tokenBalance[nftID] + rewards) - amount;
        } else {
            require((tokenFightBalance[nftID] + tokenBalance[nftID]) >= amount , "balance is not enough(1)");
        }
    }

    function random(uint256 randomSeed, uint256 lrange, uint256 mrange) internal returns (uint) {
        randNonce++;
        uint256 randomnumber = uint(keccak256(abi.encodePacked(randNonce, randomSeed, msg.sender ,block.timestamp, block.difficulty))) % (mrange - lrange + 1);
        randomnumber = randomnumber + lrange;
        return randomnumber;
    }

    function pureClaim(uint256 nftID) private {
        
        address nftOwner = ownerOf(nftID);
        uint256 mode = modeOfNFT[nftID];
        if (mode == 0) {
            return;
        }

        if (miningTimestamp[nftID] == 0) {
            return;
        }

        uint256 totalRewards = queryClaimableRewards(nftID);
        if (totalRewards > 0) {
            tokenBalance[nftID] += totalRewards; 
            miningTimestamp[nftID] = block.timestamp;
            emit CommonEvent(nftOwner, 1, 0, 0, totalRewards, 0, block.timestamp);
        }
    }

    /// Admin Functions
    //////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////
    function batchMint(address wallet, uint amount) external onlyRole(ADMIN_ROLE) {
        isEnoughStorage(amount);
        mintToAddress(wallet, amount);
    }

    function setSelling(bool isSelling) external onlyRole(ADMIN_ROLE) {
        IS_SELLING = isSelling;
    }

    function setBaseURI(string memory baseURI) external onlyRole(ADMIN_ROLE) {
        BASE_URI = baseURI;
    }

    function withdrawETH() external {
        if (msg.sender == WITHDRAW_ADDRESS) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /// @dev update function tokens
    /// todo add limitation
    function updateToken(address tokenAddr) external onlyRole(ADMIN_ROLE) {
        _TOKEN = tokenAddr;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}