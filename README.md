# multi-party-lottery

A multiple party lottery in solidity language. Each players put a number between 0-999 with 0.001 ether in this contract, and the lucky one will get all the money.(after 2% charge and gas fee)

| **Note**: This repository is a assignment workshop for class in Kasetsart university.

## How to Play

1. Deploy a contracts. With maximum number of player(n), interval time for commit(n1), reveal(n2) and find winner(n3)

2. Commit stage: Each player commit their hashed choice(number between 0-999) along with their bid 0.001 ether.

   - After n1 time the contract will enter reveal stage so player can't enter game anymore.
   - Each player can commit 1 choice in each game.

3. Reveal Stage: Each player reveal the choice they've committed.

   - Those who didn't reveal their answer in time(t1+t2 after first player commit) will not be considered as winner candidate.
   - Those who enter an invalid choice(not a number between 0-999) will not be considered as winner candidate.

4. Find Winner Stage: The contract owner will call function to find winner and transfer money with 2% fee to owner.

   - If the contract owner don't call function in time(t1+t2+t3 after first player commit) game will enter stage 5.

5. Retrieve Money stage: Each player(Include those who didn't reveal or put an invalid choice) can call `retriveMoney` to get their 0.001 ether back.

   - This contract will reset game after every player retrieve their money back

## More About Code

1. In commit stage. Player will call `commitChoice`
   - Each player can commit once in each game
   - After first player commit their choice, deadline for each stage will be set

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

2. In reveal stage. Player will call `revealChoice` along with their answer and salt.
   - If answer is invalid (ans>999). Player will not be considered as winner candidate.

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

3. In find winner stage. Contract owner have to call a `findWinner`
   - This function find a winner by using hash of xor of choice from player. Owner will get 2% of reward and the winner will be get 98% of reward.
   - If there are no winner since every player are nor winner candidate. Reward will be transfer to contract owner.

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
