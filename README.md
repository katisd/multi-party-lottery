# multi-party-lottery

A multiple party lottery implemented in Solidity. Players contribute 0.001 ether along with a number between 0-999, and the winner receives all the contributed funds (after deducting a 2% charge and gas fees).

| **Note**: This repository serves as an assignment workshop for a class at Kasetsart University.

# Table of Contents

1. [How to Play](#how-to-play)
   - [Deploying the Contract](#deploying-the-contract)
   - [Commit Stage](#commit-stage)
   - [Reveal Stage](#reveal-stage)
   - [Find Winner Stage](#find-winner-stage)
   - [Retrieve Money Stage](#retrieve-money-stage)
2. [More About the Code](#more-about-the-code)
   - [Commit Stage](#commit-stage-1)
   - [Reveal Stage](#reveal-stage-1)
   - [Find Winner Stage](#find-winner-stage-1)
   - [Retrieve Money Stage](#retrieve-money-stage-1)
3. [Conclusion](#conclusion)

## How to Play

1. **Deploying the Contract**: Deploy the contract with the desired parameters:

   - Number of players (n)
   - Interval time for committing (n1)
   - Interval time for revealing (n2)
   - Interval time for finding the winner (n3)

2. **Commit Stage**:

   - Players commit their hashed choice (a number between 0-999) along with 0.001 ether.
   - After n1 time, the contract enters the reveal stage, and no more players can join.
   - Each player can commit only once per game.

3. **Reveal Stage**:

   - Players reveal their committed choices.
   - Players who fail to reveal their answer in time (t1+t2 after the first player commits) will not be considered as winner candidates.
   - Invalid choices (not a number between 0-999) will disqualify players from winning.

4. **Find Winner Stage**:

   - The contract owner calls the `findWinner` function to determine the winner and transfer the funds.
   - The owner receives a 2% fee, and the remaining 98% goes to the winner.
   - If the owner fails to call the function in time (t1+t2+t3 after the first player commits), the game proceeds to the next stage.

5. **Retrieve Money Stage**:
   - Players (including those who didn't reveal or provided invalid choices) can call `retrieveMoney` to reclaim their 0.001 ether.
   - The game resets after all players retrieve their funds.

## More About the Code

1. **Commit Stage**:
   - Players call `commitChoice` to commit their choice.
   - Deadlines for each stage are set after the first player commits.

```js
    function commitChoice(bytes32 hashChoice) public payable {
        require(msg.value == 0.001 ether);
        // user is not player
        bool checkPlayer;
        (checkPlayer, ) = isPlayer();
        require(checkPlayer == false);
        // check if is first player
        if (deadlineCommit == 0) {
            deadlineCommit = block.timestamp + T1;
            deadlineReveal = deadlineCommit + T2;
            deadlineFindWinner = deadlineReveal + T3;
        }
        // check time
        require(block.timestamp <= deadlineCommit);
        // then add to player
        participants++;
        players.push(Player(msg.sender, 0, false));
        commit(hashChoice);
    }
```

2. **Reveal Stage**:

   - Players call revealChoice with their answer and salt.
   - Invalid answers disqualify players from winning.

```js
    function revealChoice(
        uint256 ans,
        string memory salt
    ) public returns (string memory) {
        // check time
        require(
            block.timestamp > deadlineCommit && block.timestamp < deadlineReveal
        );
        // user is Player
        bool checkPlayer;
        uint256 playerIndex;
        (checkPlayer, playerIndex) = isPlayer();
        require(checkPlayer == true);
        // Reveal
        revealAnswer(ans, salt);
        if (ans > 999) {
            return
                "You are out of game, since your choice are out of range [0-999]";
        } else {
            players[playerIndex].choice = ans + 1;
            players[playerIndex].isReveal = true;
            return "Your answer are reveal successfully";
        }
    }
```

3. **Find Winner Stage:**:

   - The contract owner calls findWinner to determine the winner.
   - The winner receives 98% of the funds, and the owner receives 2%.
   - If no valid winner is found, funds are transferred to the owner.

```js
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
            if (players[i].isReveal == false) {
                continue;
            }
            playerNum += 1;
            if (isThereArePlayer == false) {
                isThereArePlayer = true;
                winner = players[i].choice;
                continue;
            }
            winner = winner & players[i].choice;
        }
        address payable ownerAddress = payable(owner);
        if (isThereArePlayer) {
            winner = uint(keccak256(abi.encodePacked(winner))) % playerNum;
            // find player that's not cheat and in (winner) position
            playerNum = 0;
            for (uint256 i = 0; i < players.length; i++) {
                if (players[i].isReveal == false) {
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

```

4. **Retrieve Money Stage:**:

   - Players call retrieveMoney to reclaim their funds.

```js
    function retrieveMoney() public {
        // check time
        require(block.timestamp > deadlineFindWinner);
        // check is player
        uint256 index;
        (, index) = isPlayer();

        removePlayer();
        if (players.length == 0) {
            resetGame();
        }

        address payable account = payable(msg.sender);
        account.transfer(0.001 ether);
    }
```

## Conclusion

The multi-party lottery contract provides an engaging and transparent way for multiple players to participate in a lottery game on the Ethereum blockchain. Players can easily interact with the contract using the provided functions, and the code is designed to ensure fairness and security throughout the game.
