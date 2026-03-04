// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AdvancedVault is ERC4626 {
    uint256 public totalAssetsDeposited;
    constructor(IERC20 _asset) ERC4626(_asset) ERC20("FaultyVaultShares", "FVS") {}

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        totalAssetsDeposited += assets;
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        totalAssetsDeposited -= assets;
        return super.withdraw(assets, receiver, owner);
    }
}
