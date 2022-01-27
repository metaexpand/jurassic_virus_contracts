// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Control is IERC20 {

    function burn(uint256 burnAmount) external;

    function mint(address target, uint256 mintAmount) external;
}