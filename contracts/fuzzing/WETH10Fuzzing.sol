// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.6;
import "../WTLOS10.sol";


/// @dev A contract that will receive weth, and allows for it to be retrieved.
contract MockHolder {
    constructor (address payable wtlos, address retriever) {
        WTLOS10(wtlos).approve(retriever, type(uint).max);
    }
}

/// @dev Invariant testing
contract WTLOS10Fuzzing {

    WTLOS10 internal wtlos;
    address internal holder;

    /// @dev Instantiate the WETH10 contract, and a holder address that will return weth when asked to.
    constructor () {
        wtlos = new WTLOS10();
        holder = address(new MockHolder(address(wtlos), address(this)));
    }

    /// @dev Receive ETH when withdrawing.
    receive () external payable { }

    /// @dev Add two numbers, but return 0 on overflow
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a); // Normally it would be a `require`, but we want the test to fail if there is an overflow, not to be ignored.
    }

    /// @dev Subtract two numbers, but return 0 on overflow
    function sub(uint a, uint b) internal pure returns (uint c) {
        c = a - b;
        assert(c <= a); // Normally it would be a `require`, but we want the test to fail if there is an overflow, not to be ignored.
    }

    /// @dev Test that supply and balance hold on deposit.
    function deposit(uint tlosAmount) public {
        uint supply = address(wtlos).balance;
        uint balance = wtlos.balanceOf(address(this));
        wtlos.deposit{value: tlosAmount}(); // It seems that echidna won't let the total value sent go over type(uint256).max
        assert(address(wtlos).balance == add(supply, tlosAmount));
        assert(wtlos.balanceOf(address(this)) == add(balance, tlosAmount));
        assert(address(wtlos).balance == address(wtlos).balance);
    }

    /// @dev Test that supply and balance hold on withdraw.
    function withdraw(uint tlosAmount) public {
        uint supply = address(wtlos).balance;
        uint balance = wtlos.balanceOf(address(this));
        wtlos.withdraw(tlosAmount);
        assert(address(wtlos).balance == sub(supply, tlosAmount));
        assert(wtlos.balanceOf(address(this)) == sub(balance, tlosAmount));
        assert(address(wtlos).balance == address(wtlos).balance);
    }

    /// @dev Test that supply and balance hold on transfer.
    function transfer(uint tlosAmount) public {
        uint thisBalance = wtlos.balanceOf(address(this));
        uint holderBalance = wtlos.balanceOf(holder);
        wtlos.transfer(holder, tlosAmount);
        assert(wtlos.balanceOf(address(this)) == sub(thisBalance, tlosAmount));
        assert(wtlos.balanceOf(holder) == add(holderBalance, tlosAmount));
        assert(address(wtlos).balance == address(wtlos).balance);
    }

    /// @dev Test that supply and balance hold on transferFrom.
    function transferFrom(uint tlosAmount) public {
        uint thisBalance = wtlos.balanceOf(address(this));
        uint holderBalance = wtlos.balanceOf(holder);
        wtlos.transferFrom(holder, address(this), tlosAmount);
        assert(wtlos.balanceOf(address(this)) == add(thisBalance, tlosAmount));
        assert(wtlos.balanceOf(holder) == sub(holderBalance, tlosAmount));
        assert(address(wtlos).balance == address(wtlos).balance);
    }
}