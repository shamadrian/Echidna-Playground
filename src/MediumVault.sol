// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MediumVault {
    uint256 public totalDeposited;

    function deposit() public payable {
        totalDeposited += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= totalDeposited, "Not enough funds in the vault");
        totalDeposited -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}
