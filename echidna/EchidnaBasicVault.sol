// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BasicVault} from "../src/BasicVault.sol";

contract EchidnaBasicVault is BasicVault {
    function echidna_totalDeposited_eq_balance() public view returns (bool) {
        return totalDeposited == address(this).balance;
    }
}