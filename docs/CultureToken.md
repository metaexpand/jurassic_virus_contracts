# CultureToken





## 1.Contents
<!-- START doctoc -->
<!-- END doctoc -->

## 2.Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| BURNER_ROLE | bytes32 |
| MINTER_ROLE | bytes32 |
| AMOUNT | uint256 |
| DECIMAL | uint256 |
| TOTAL_SUPPLY | uint256 |

## 3.Modifiers

## 4.Functions

### getBurnerRole



*Declaration:*
```solidity
function getBurnerRole(
) external returns
(bytes32)
```




### getMinterRole



*Declaration:*
```solidity
function getMinterRole(
) external returns
(bytes32)
```




### burn



*Declaration:*
```solidity
function burn(
) external onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### mint



*Declaration:*
```solidity
function mint(
) external onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




## 5.Events
### MintEvent





### BurnEvent





