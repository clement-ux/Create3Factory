// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract Counter {
    uint256 public count;

    constructor(uint256 _initialCount) {
        count = _initialCount;
    }

    function increment() external {
        count++;
    }

    function decrement() external {
        count--;
    }
}
