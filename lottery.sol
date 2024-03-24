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

    function removePlayer() internal {
        bool checkPlayer;
        uint256 playerIndex;
        (checkPlayer, playerIndex) = isPlayer();
        require(playerIndex < players.length && checkPlayer == true);
        // move to last then pop last array
        players[playerIndex] = players[players.length - 1];
        players.pop();
    }

    function revealChoice(
        uint256 ans,
        string memory salt
    ) public returns (string memory) {
        // check time
        require(
            block.timestamp > deadlineCommit && block.timestamp < deadlineReveal
        );
        // check if the player is already in the game
        bool checkPlayer;
        uint256 playerIndex;
        (checkPlayer, playerIndex) = isPlayer();
        require(checkPlayer == true);
        // Reveal
        revealAnswer(ans, salt);
        if (ans > 999) {
            removePlayer();
            return
                "You are out of game, since your choice are out of range [0-999]";
        } else {
            players[playerIndex].choice = ans + 1;
            players[playerIndex].isReveal = true;
            return "Your answer are reveal successfully";
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function findWinner() public onlyOwner returns (string memory, uint) {
        // check time
        require(
            block.timestamp > deadlineReveal &&
                block.timestamp < deadlineFindWinner
        );
        bool isThereArePlayer = false;
        uint playerNum = 0;
        // find index of winner
        uint256 winner;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].choice == 0) {
                continue;
            }
            playerNum += 1;
            if (isThereArePlayer == false) {
                isThereArePlayer = true;
                winner = players[i].choice - 1;
                continue;
            }
            winner = winner & (players[i].choice - 1);
        }
        address payable ownerAddress = payable(owner);
        if (isThereArePlayer) {
            winner = uint(keccak256(abi.encodePacked(winner))) % playerNum;
            // find player that's not cheat and in (winner) position
            playerNum = 0;
            for (uint256 i = 0; i < players.length; i++) {
                if (players[i].choice == 0) {
                    continue;
                }
                if (playerNum == winner) {
                    winner = i;
                    break;
                }
                playerNum += 1;
            }
            address payable winnerAccount = payable(players[winner].addr);
            // winnerAccount.transfer(0.01*participants*0.98 ether);
            uint reward = ((participants * 98) * 1e18) / 1e5;
            uint ownerReward = ((participants * 2) * 1e18) / 1e5;

            resetGame();

            winnerAccount.transfer(reward);
            ownerAddress.transfer(ownerReward);
            return ("Winner is recieve", reward);
        }
        ownerAddress.transfer(address(this).balance);
        resetGame();
        return ("Owner reviev all", 0);
    }

    function resetGame() internal {
        deadlineCommit = 0;
        deadlineFindWinner = 0;
        deadlineReveal = 0;
        delete players;
        participants = 0;
    }
}
