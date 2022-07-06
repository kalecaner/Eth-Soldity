//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  // Address balances
  mapping(address => uint256) public balances;

  // Threshold
  uint256 public constant threshold = 1 ether;

  // Deadline
  uint256 public deadline = block.timestamp + 72 hours;

  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }


  modifier deadlineReached( bool reached ) {
    uint256 timeRemaining = timeLeft();
    if(reached) {
      require(timeRemaining > 0);
    } else {
      require(timeRemaining == 0);
    }
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )


  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }


  event Stake(address, uint256);


  function stake() public payable deadlineReached(true) stakeNotCompleted {
    address sender = msg.sender;
    balances[sender] += msg.value;
    
    emit Stake(sender, balances[sender]);
  }

function execute() public stakeNotCompleted deadlineReached(false) {
  uint256 contractBalance = address(this).balance;
  if(contractBalance >= threshold)
  { 
  (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
  require(sent, "could not send");
  }
 
}

function withdraw() public deadlineReached(false) stakeNotCompleted {
  uint256 userBalance = balances[msg.sender];
  require(userBalance >= 0, "no coins");

  balances[msg.sender] = 0;

  (bool sent,) = msg.sender.call{value: userBalance}("");
  require(sent, "withdraw failed");
}


function timeLeft() public view returns (uint256 timeleft) {
  // block.timestamp does not seem like the right thing to use
    if( block.timestamp >= deadline ) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

receive() external payable{
  stake();
}
}