# JurassicVirusNFT





## 1.Contents
<!-- START doctoc -->
<!-- END doctoc -->

## 2.Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| ADMIN_ROLE | bytes32 |
| TOTAL_SUPPLY | uint256 |
| PRICE | uint256 |
| WITHDRAW_ADDRESS | address |

## 3.Modifiers

## 4.Functions

### constructor
NFT Related


*Declaration:*
```solidity
function constructor(
) public ERC721
```
*Modifiers:*
| Modifier |
| --- |
| ERC721 |




### tokenURI



*Declaration:*
```solidity
function tokenURI(
) public returns
(string)
```




### totalSold

> total sold


*Declaration:*
```solidity
function totalSold(
) public returns
(uint256)
```


*Returns:*
| Arg | Description |
| --- | --- |
|`total` | sold amount

### queryPurchaseTotalFee



*Declaration:*
```solidity
function queryPurchaseTotalFee(
) public returns
(uint256 totalFee)
```




### isOwner

> inner method to verify the owner of the token

*Declaration:*
```solidity
function isOwner(
) public returns
(bool isNFTOwner)
```




### listMyNFT

> show all purchased nfts by Arrays


*Declaration:*
```solidity
function listMyNFT(
) external returns
(uint256[] tokens)
```


*Returns:*
| Arg | Description |
| --- | --- |
|`tokens` | nftID array

### listNFT

> show all purchased nfts by Arrays


*Declaration:*
```solidity
function listNFT(
) external returns
(uint256[] tokens)
```


*Returns:*
| Arg | Description |
| --- | --- |
|`tokens` | nftID array

### purchaseNFT

> user doing purchase


*Declaration:*
```solidity
function purchaseNFT(
uint256 amount
) external
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`amount` | uint256 | how many


### claimRewards

> claim token(after claim, need to withdraw to wallet)


*Declaration:*
```solidity
function claimRewards(
uint256 nftID,
bool triggerFight
) public
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | the one try to claim TOKEN
|`triggerFight` | bool | true=trigger fight, false=no


### queryNextLevelTokenRequire

> query how much token needed for next level

*Declaration:*
```solidity
function queryNextLevelTokenRequire(
) public returns
(uint256 requirement)
```




### startMode



*Declaration:*
```solidity
function startMode(
uint256 nftID,
uint256 nMode,
uint256 bets
) public
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | token id
|`nMode` | uint256 | 0=not start, 1=normal, 2=fighting
|`bets` | uint256 | lowest bet


### positiveFight

> start fight


*Declaration:*
```solidity
function positiveFight(
uint256 nftID
) public
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | the owner's nft trying to fight


### requiredUpdateTokens

> query how many token needed to upgrade

*Declaration:*
```solidity
function requiredUpdateTokens(
) public returns
(uint256 tokenAmount)
```




### queryLevel

> query the level of the NFT


*Declaration:*
```solidity
function queryLevel(
uint256 nftID
) public returns
(uint256 level)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | the token id


### queryNextLevel

> query the next level of NFT

*Declaration:*
```solidity
function queryNextLevel(
) public returns
(uint256 nextLevel)
```




### updateLevel



*Declaration:*
```solidity
function updateLevel(
) public
```




### queryClaimableRewards

> query how many token can claim for rewards


*Declaration:*
```solidity
function queryClaimableRewards(
uint256 nftID
) public returns
(uint256 totalRewards)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | target nft


### calculatePerDayRewards

> calculate rewards

*Declaration:*
```solidity
function calculatePerDayRewards(
) public returns
(uint256 rewardsPerDay)
```




### queryAbility

> check ability of the NFT


*Declaration:*
```solidity
function queryAbility(
uint256 nftID
) public returns
(struct JurassicVirusNFT.Ability ability)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | query target


### queryPoints

> query how many points user can be used to assign


*Declaration:*
```solidity
function queryPoints(
address user
) external returns
(uint256 points)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`user` | address | query user


### recharge

> recharge into NFT


*Declaration:*
```solidity
function recharge(
uint256 nftID,
uint256 totalFee
) public
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | the nft
|`totalFee` | uint256 | charge amount


### withdrawToken

> withdraw token

*Declaration:*
```solidity
function withdrawToken(
) public
```




### burnNFT

> Burn nft to get points


*Declaration:*
```solidity
function burnNFT(
uint256 nftID
) external
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | burned NFT id


### queryMode

> query which mode current is


*Declaration:*
```solidity
function queryMode(
uint256 nftID
) external returns
(uint256 mode)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | target nft


### queryFightBalance

> query total fight balance (include reward's and charged)


*Declaration:*
```solidity
function queryFightBalance(
uint256 nftID
) public returns
(uint256 balance)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | target nft


### queryTokenFightBalance

> query query balance only for fight


*Declaration:*
```solidity
function queryTokenFightBalance(
uint256 nftID
) public returns
(uint256 balance)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | target nft


### queryTokenBalance

> query charged balance (can withdraw)


*Declaration:*
```solidity
function queryTokenBalance(
uint256 nftID
) external returns
(uint256 balance)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | target nft


### queryBounty

> query how much pay or get after fight


*Declaration:*
```solidity
function queryBounty(
uint256 nftID
) external returns
(uint256 bounty)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftID` | uint256 | target nft


### assignAllEnergy

> 


*Declaration:*
```solidity
function assignAllEnergy(
uint256 ability1Points,
uint256 ability2Points,
uint256 ability3points
) external
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`ability1Points` | uint256 | strength
|`ability2Points` | uint256 | explosive
|`ability3points` | uint256 | agility


### payForUpgrade



*Declaration:*
```solidity
function payForUpgrade(
) internal
```




### random



*Declaration:*
```solidity
function random(
) internal returns
(uint256)
```




### batchMint
/ Admin Functions


*Declaration:*
```solidity
function batchMint(
) external onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### setSelling



*Declaration:*
```solidity
function setSelling(
) external onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### setBaseURI



*Declaration:*
```solidity
function setBaseURI(
) external onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### withdrawETH



*Declaration:*
```solidity
function withdrawETH(
) external
```




### updateToken
/ @dev update function tokens
todo add limitation


*Declaration:*
```solidity
function updateToken(
) external onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### supportsInterface



*Declaration:*
```solidity
function supportsInterface(
) public returns
(bool)
```




## 5.Events
### CommonEvent

> combine event



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`eventType` | address | :white_check_mark: |    different eventType read different parameter:
                    1=claim, user=withdraw user, amount=withdrawAmount
                    2=Fight nft1ID=Win, nft2ID=Lose, amount=bets
                    3=Charge nft1ID=Charge target, user=charge wallet, amount=charge amount                     
                    5=LevelUp nft1ID=targetNFT, status=final level
                    6=Mode Change nft1ID=changed nftID, status=final Mode
                    7=Burn nft1ID=targetID
                    8=Search Opponent nft1ID=targetID, nft2ID=opponentID, status=1 find, 0=not find
### PurchaseEvent





