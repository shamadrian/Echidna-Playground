// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TestToken} from "./assets/TestToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PriviledgeVault is AccessControl {
    ERC20 public token;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE"); 
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    mapping(address => uint256) public balances;
    uint256 public totalAssetsDeposited;
    uint8 public paused = 1;

    
    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender), "Not an owner");
        _;
    }

    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, msg.sender), "Not a pauser");
        _;
    }

    modifier pausible() {
        require(paused == 1, "Contract is paused");
        _;
    }

    modifier onlyWhenPaused() {
        require(paused == 2, "Contract is not paused");
        _;
    }

    constructor(ERC20 _token, address _pauser) {
        token = _token;
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, _pauser);
    }

    function deposit(uint256 amount) public pausible {
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        totalAssetsDeposited += amount;
    }

    function withdraw(uint256 amount) public pausible {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalAssetsDeposited -= amount;
        token.transfer(msg.sender, amount);
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, contractBalance);
    }

    function pause() public onlyPauser {
        paused = 2;
    }

    function unpause() public onlyPauser {
        paused = 1;
    }
}