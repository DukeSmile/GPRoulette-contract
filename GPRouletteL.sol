// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Roulette {
  struct Bet {
    address player;
    uint8 betType; // 0: straight, 1: column, 2: dozen, 3: modulus, 4:color, 5:eighteen
    uint8 number; // [36, 2, 2, 1, 1, 1]
    uint256 amount;
  }
  /*      
    Depending on the BetType, number will be:
      color: 0 for black, 1 for red
      column: 0 for left, 1 for middle, 2 for right
      dozen: 0 for first, 1 for second, 2 for third
      eighteen: 0 for low, 1 for high
      modulus: 0 for even, 1 for odd
      number: number
  */
  
  uint necessaryBalance;
  uint nextRoundTimestamp;
  address creator;
  uint256 maxAmountAllowedInTheBank;
  uint256 totalBetAmount;
  mapping (address => uint256) winnings;
  uint8[] payouts;
  uint8[] numberRange;
  
  bool[37] isNumberRed;
  bool[37] isNumberBlack;
  Bet[] public bets;

  constructor(uint256 maxBankAmount) {
    creator = msg.sender;
    necessaryBalance = 0;
    totalBetAmount = 0;
    nextRoundTimestamp = block.timestamp;
    payouts = [36, 3, 3, 2, 2, 2];
    numberRange = [36, 2, 2, 1, 1, 1];
    isNumberRed= [false, true, false, true, false, true, false, true, false, true, false, false, true, false, true, false, true, false, true, true, false, true, false, true, false, true, false, true, false, false, true, false, true, false, true, false, true];
    isNumberBlack = [false, false, true, false, true, false, true, false, true, false, true, true, false, true, false, true, false, true, false, false, true, false, true, false, true, false, true, false, true, true, false, true, false, true, false, true, false];
    maxAmountAllowedInTheBank = maxBankAmount; /* 2 ether */
  }

  event RandomNumber(uint256 number);
  function getStatus() public view returns(uint, uint, uint, uint, uint) {
    return (
      bets.length,             // number of active bets
      totalBetAmount,         // value of active bets
      nextRoundTimestamp,      // when can we play again
      address(this).balance,   // roulette balance
      winnings[msg.sender]     // winnings of player
    ); 
  }

  function bet(uint8 number, uint8 betType) payable public {
    // require(msg.value == betAmount, 'the value of the bet is correct');
    require(betType >= 0 && betType <= 5, 'betType is unknown');
    require(number >= 0 && number <= numberRange[betType], 'Your bet number is out of range');
    uint payoutForThisBet = payouts[betType] * msg.value;
    uint provisionalBalance = necessaryBalance + payoutForThisBet;
    require(provisionalBalance < address(this).balance, 'The Contract has not sufficient funds');
    
    necessaryBalance += payoutForThisBet;
    bets.push(Bet({
      player: msg.sender,
      betType: betType,
      number: number,
      amount: msg.value
    }));
    totalBetAmount += msg.value;
  }

  function spinWheel() public {
    require(bets.length > 0, 'There is no bet');
    require(block.timestamp > nextRoundTimestamp, 'We are not allowed to spin the wheel');
    nextRoundTimestamp = block.timestamp; // reset nextRoundTime
    
    //generating random
    uint diff = block.difficulty;
    bytes32 hash = blockhash(block.number-1);
    Bet memory lb = bets[bets.length-1];
    uint number = uint(keccak256(abi.encodePacked(block.timestamp, diff, hash, lb.betType, lb.player, lb.number))) % 37;
    
    //check every bet for this number
    for (uint i = 0; i < bets.length; i++) {
      bool won = false;
      Bet memory b = bets[i];
      if (number == 0) {                        //bets on number 0
        won = (b.betType == 0 && b.number == 0);
      } else {
        if (b.betType == 0) { 
          won = (b.number == number);           //bets on straight number
        }
        else if (b.betType == 1) {               
          if (b.number == 0) won = (number % 3 == 1);              /* bet on left column */
          if (b.number == 1) won = (number % 3 == 2);              /* bet on middle column */
          if (b.number == 2) won = (number % 3 == 0);              /* bet on right column */
        }
        else if (b.betType == 2) {                               
          if (b.number == 0) won = (number <= 12);                 /* bet on 1st dozen */
          if (b.number == 1) won = (number > 12 && number <= 24);  /* bet on 2nd dozen */
          if (b.number == 2) won = (number > 24);                  /* bet on 3rd dozen */
        }
        else if (b.betType == 3) {
          won = (number % 2 == b.number);       //bets on modulus
        }
        else if (b.betType == 4) {
          if (b.number == 0) {                                     /* bet on red */
            won = isNumberRed[number];
          } else {                                                 /* bet on black */
            won = isNumberBlack[number];
          }
        }
        else if (b.betType == 5) {                                 // bets on eighteen
          if (b.number == 0) won = (number <= 18);                 /* bet on low 18s */
          if (b.number == 1) won = (number >= 19);                 /* bet on high 18s */
        }
      }
      /* if winning bet, add to player winnings balance */
      if (won) {
        winnings[b.player] += b.amount * payouts[b.betType];
      }
    }
    delete bets;
    necessaryBalance = 0;
    totalBetAmount = 0;
    /* check if to much money in the bank */
    if (address(this).balance > maxAmountAllowedInTheBank) takeProfits();
    emit RandomNumber(number);
  }
    
  function withdrawFunds() external {
      require(winnings[msg.sender] > 0, 'You dont have enough amount');
      require(winnings[msg.sender] <= address(this).balance, 'The Contract has not sufficient funds' );
      uint256 funds = winnings[msg.sender];
      winnings[msg.sender] = 0;
      
      (bool success, ) = msg.sender.call{value: funds}("");
      require(success, "ETH transfer failed");
      // msg.sender.transfer(funds);
  }

  function takeProfits() internal {
    uint amount = address(this).balance - maxAmountAllowedInTheBank;
    // if (amount > 0) creator.transfer(amount);
    if (amount > 0) {
      (bool success, ) = creator.call{value: amount}("");
      require(success, "ETH transfer failed");
    }
  }
}