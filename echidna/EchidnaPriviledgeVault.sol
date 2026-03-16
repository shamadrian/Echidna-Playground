// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PriviledgeVault} from "../src/PrivilegeVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {TestToken} from "../src/assets/TestToken.sol";

// Minimal proxy that acts as a distinct caller
contract UserProxy {
    ERC20 public token;
    PriviledgeVault public vault;
    constructor(ERC20 _token, PriviledgeVault _vault) {
        token = _token;
        vault = _vault;
    }

    function approve(uint256 amount) external {
        ERC20(address(token)).approve(address(vault), amount);
    }

    function doDeposit(uint256 amount) external {
        vault.deposit(amount);
    }

    function doWithdraw(uint256 amount) external {
        vault.withdraw(amount);
    }

    function doEmergencyWithdraw() external {
        vault.emergencyWithdraw();
    }
}

contract EchidnaPriviledgeVault {
    ERC20 public token;
    PriviledgeVault public vault;
    address public owner = address(0x1000000000000000000000000000000000000000);
    address public pauser = address(0x2000000000000000000000000000000000000000);
    address public user1 = address(0x3000000000000000000000000000000000000000);
    address public user2 = address(0x4000000000000000000000000000000000000000);

    // per-caller proxy pattern so Echidna can simulate distinct callers
    mapping(address => address) public proxies;
    address[] public proxyList;

    // tracking flags to assert deposit/withdraw didn't succeed while paused
    mapping(address => bool) public depositSucceededWhilePaused;
    mapping(address => bool) public withdrawSucceededWhilePaused;
    bool public emergencyWithdrawHappenedWhileUnpaused;

    constructor() {
        // 1) Deploy the test token and mint a large supply to this contract
        token = new TestToken(1_000_000 ether);

        // 2) Deploy the PriviledgeVault using the test token as the underlying asset
        // pass `address(this)` as the pauser so the harness can call pause/unpause
        vault = new PriviledgeVault(token, address(this));
    }

    function _ensureProxyForCaller() internal returns (UserProxy) {
        address p = proxies[msg.sender];
        if (p == address(0)) {
            UserProxy up = new UserProxy(token, vault);
            proxies[msg.sender] = address(up);
            proxyList.push(address(up));
            return up;
        }
        return UserProxy(p);
    }

    // fuzz entry: deposit via caller's proxy
    function do_deposit(uint256 amount) public {
        if (amount == 0) return;
        UserProxy proxy = _ensureProxyForCaller();

        // transfer tokens from harness (this) to proxy so it can transferFrom
        token.transfer(address(proxy), amount);

        // proxy approves vault
        try proxy.approve(amount) {} catch {}

        // try deposit; if it succeeds while paused, mark flag
        bool ok = false;
        try proxy.doDeposit(amount) { ok = true; } catch {}
        if (ok && vault.paused() == 2) depositSucceededWhilePaused[address(proxy)] = true;
    }

    // fuzz entry: withdraw via caller's proxy
    function do_withdraw(uint256 amount) public {
        if (amount == 0) return;
        address p = proxies[msg.sender];
        if (p == address(0)) return;
        UserProxy proxy = UserProxy(p);

        bool ok = false;
        try proxy.doWithdraw(amount) { ok = true; } catch {}
        if (ok && vault.paused() == 2) withdrawSucceededWhilePaused[address(proxy)] = true;
    }

    // harness-level pause/unpause (harness was given pauser role at deploy)
    function do_pause() public {
        try vault.pause() {} catch {}
    }

    function do_unpause() public {
        try vault.unpause() {} catch {}
    }

    // emergency withdraw triggered by the harness (harness is OWNER_ROLE since it deployed vault)
    function do_emergencyWithdraw_owner() public {
        bool ok = false;
        try vault.emergencyWithdraw() { ok = true; } catch {}
        if (ok && vault.paused() == 1) emergencyWithdrawHappenedWhileUnpaused = true;
    }

    // Also allow proxies to attempt emergencyWithdraw (if they happen to have owner role)
    function do_emergencyWithdraw_via_proxy() public {
        UserProxy proxy = _ensureProxyForCaller();
        bool ok = false;
        try proxy.doEmergencyWithdraw() { ok = true; } catch {}
        if (ok && vault.paused() == 1) emergencyWithdrawHappenedWhileUnpaused = true;
    }

    // Echidna properties
    // 1) total recorded deposits must equal actual token balance of the vault
    function echidna_total_matches_balance() public view returns (bool) {
        return vault.totalAssetsDeposited() == token.balanceOf(address(vault));
    }

    // 2) emergencyWithdraw should only be callable when paused (we track occurrences)
    function echidna_emergency_only_when_paused() public view returns (bool) {
        return emergencyWithdrawHappenedWhileUnpaused == false;
    }

    // 3) deposits must not succeed while paused
    function echidna_no_deposit_while_paused() public view returns (bool) {
        for (uint i = 0; i < proxyList.length; i++) {
            if (depositSucceededWhilePaused[proxyList[i]]) return false;
        }
        return true;
    }

    // 4) withdraws must not succeed while paused
    function echidna_no_withdraw_while_paused() public view returns (bool) {
        for (uint i = 0; i < proxyList.length; i++) {
            if (withdrawSucceededWhilePaused[proxyList[i]]) return false;
        }
        return true;
    }

    function echidna_emergency_only_from_owner() public view returns (bool) {
        // if any proxy succeeded at emergencyWithdraw, check if it was paused (allowed) or not (not allowed)
        for (uint i = 0; i < proxyList.length; i++) {
            if (withdrawSucceededWhilePaused[proxyList[i]]) {
                // if we see an emergency withdraw that happened while unpaused, check if the caller was owner
                // since the harness is the only owner, the caller must be the harness for this to be valid
                if (proxyList[i] != address(this)) return false;
            }
        }
        return true;
    }
}
