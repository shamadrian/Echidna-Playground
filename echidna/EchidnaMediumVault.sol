// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {MediumVault} from "../src/MediumVault.sol";

contract EchidnaMediumVault  {
    MediumVault public vault;

    constructor()  {
        vault = new MediumVault();
    }

    function do_donate() public payable {
        if (msg.value == 0) return;
        (bool success, ) = address(vault).call{value: msg.value}("");
        require(success, "Deposit failed");
    }

    function do_deposit() public payable {
        if (msg.value == 0) return;
        vault.deposit{value: msg.value}();
    }

    function do_withdraw(uint256 amount) public {
        if (amount == 0) return;
        if (amount > address(vault).balance) return;
        vault.withdraw(amount);
    }

    function echidna_totalDeposited_eq_balance() public view returns (bool) {
        return vault.totalDeposited() == address(vault).balance;
    }
}
