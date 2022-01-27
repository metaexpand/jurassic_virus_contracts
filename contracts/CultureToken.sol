// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC20Control.sol";

import "hardhat/console.sol";

contract CultureToken is ERC20, AccessControl, IERC20Control {

    event MintEvent(address minter, address target, uint256 amount, uint256 time);
    event BurnEvent(address burner, uint256 amount, uint256 time);

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); 
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); 
    uint256 public constant AMOUNT = 21000000;
    uint256 public constant DECIMAL = 18;
    uint256 public constant TOTAL_SUPPLY = AMOUNT * 10 ** uint(DECIMAL);

    uint256 private _minted = 0;

    function getBurnerRole() external pure returns(bytes32) {
        return BURNER_ROLE;
    }

    function getMinterRole() external pure returns(bytes32) {
        return MINTER_ROLE;
    }
    
    constructor() ERC20("Culture", "CUL") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function burn(uint256 burnAmount) external override onlyRole(BURNER_ROLE) {
        _burn(msg.sender, burnAmount);
        emit BurnEvent(msg.sender, burnAmount, block.timestamp);
    }

    function mint(address target, uint256 mintAmount) external override onlyRole(MINTER_ROLE) {
        require(_minted + mintAmount <= TOTAL_SUPPLY, "mint over limitd");
        _mint(target, mintAmount);  
        _minted += mintAmount;
        emit MintEvent(msg.sender, target, mintAmount, block.timestamp);
    }

}