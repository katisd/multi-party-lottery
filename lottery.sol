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

    struct Player {
        address addr;
        uint256 choice;
        bool isReveal;
    }
    Player[] private players;

    uint256 participants;

    constructor(uint256 n, uint256 t1, uint256 t2, uint256 t3) {
        owner = msg.sender;
        N = n;
        T1 = t1;
        T2 = t2;
        T3 = t3;
    }

    function isPlayer() private view returns (bool ans, uint256 index) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].addr == msg.sender) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function commitChoice(bytes32 hashChoice) public payable {
        require(msg.value == 0.001 ether);
        // check if the player is already in the game
        bool checkPlayer;
        (checkPlayer, ) = isPlayer();
        require(checkPlayer == false);
        // If the deadline is not set, set the deadline
        if (deadlineCommit == 0) {
            deadlineCommit = block.timestamp + T1;
            deadlineReveal = deadlineCommit + T2;
            deadlineFindWinner = deadlineReveal + T3;
        }
        // check time
        require(block.timestamp <= deadlineCommit);
        // add player to the game
        participants++;
        players.push(Player(msg.sender, 0, false));
        commit(hashChoice);
    }
}
