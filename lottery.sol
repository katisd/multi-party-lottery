// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract lottery is CommitReveal {
    // initiate variables
    address owner;
    uint256 N;
    uint256 T1;
    uint256 deadlineCommit = 0;
    uint256 T2;
    uint256 deadlineReveal = 0;
    uint256 T3;
    uint256 deadlineFindWinner = 0;

    constructor(uint256 n, uint256 t1, uint256 t2, uint256 t3) {
        owner = msg.sender;
        N = n;
        T1 = t1;
        T2 = t2;
        T3 = t3;
    }
}
