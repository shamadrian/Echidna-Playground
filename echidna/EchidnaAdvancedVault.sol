// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AdvancedVault} from "../src/AdvancedVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EchidnaAdvancedVault is ERC20 {
    AdvancedVault public vault;

    constructor() ERC20("TestAsset", "TST") {
        // 1) Give the harness a big balance of the underlying token
        _mint(address(this), 1_000_000 ether);

        // 2) Deploy the AdvancedVault using this token as the underlying asset
        vault = new AdvancedVault(IERC20(address(this)));

        // 3) Allow the vault to pull tokens from this contract on deposit
        _approve(address(this), address(vault), type(uint256).max);
    }

    // -------- Actions Echidna can fuzz (must NOT start with `echidna_`) --------

    // Simulate deposits into the vault
    function do_deposit(uint256 assets) public {
        if (assets == 0 || assets > balanceOf(address(this))) return;
        vault.deposit(assets, address(this));
    }

    // Simulate withdraws via withdraw()
    function do_withdraw(uint256 assets) public {
        if (assets == 0) return;
        uint256 maxAssets = vault.maxWithdraw(address(this));
        if (assets > maxAssets) return;
        vault.withdraw(assets, address(this), address(this));
    }

    // Simulate withdraws via redeem()
    function do_redeem(uint256 shares) public {
        if (shares == 0) return;
        uint256 maxShares = vault.maxRedeem(address(this));
        if (shares > maxShares) return;
        vault.redeem(shares, address(this), address(this));
    }

    // -------- The invariant (property) --------

    function echidna_totalAssetsDeposited_le_totalAssets() public view returns (bool) {
        return vault.totalAssetsDeposited() <= vault.totalAssets();
    }
}
