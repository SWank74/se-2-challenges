// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	mapping(address => uint256) public balances; //maintain the staked balance of stakers
	uint256 public constant threshold = 1 ether;
	uint public deadline = block.timestamp + 72 hours;
	address[] stakers;

	ExampleExternalContract public exampleExternalContract;

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
	}

	modifier notCompleted() {
		require(
			!exampleExternalContract.completed(),
			"Staking already executed!"
		);
		_;
	}

	modifier deadlineOpen() {
		require(block.timestamp <= deadline, "Deadline is over");
		_;
	}

	// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
	// (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
	event Stake(address, uint256);

	function stake() public payable notCompleted {
		balances[msg.sender] += msg.value;
		emit Stake(msg.sender, msg.value);
		stakers.push(msg.sender);
	}

	// After some `deadline` allow anyone to call an `execute()` function
	// If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
	//Reset the stakers balances
	function execute() external notCompleted {
		if (block.timestamp > deadline && address(this).balance >= threshold) {
			exampleExternalContract.complete{ value: address(this).balance }();
			for (uint256 i; i < stakers.length; i++) {
				balances[stakers[i]] = 0;
			}
		}
	}

	// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
	// User should wait for deadline
	// User should be allowed to withdraw only if had staked
	// Set the balance of the user to 0 once withdrawn
	function withdraw() external notCompleted {
		if (
			block.timestamp > deadline &&
			address(this).balance < threshold &&
			balances[msg.sender] > 0
		) {
			payable(msg.sender).transfer(balances[msg.sender]);
			balances[msg.sender] = 0;
		}
	}

	// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
	function timeLeft() external view returns (uint256) {
		return block.timestamp < deadline ? (deadline - block.timestamp) : 0;
	}

	// Add the `receive()` special function that receives eth and calls stake()

	receive() external payable {
		this.stake();
	}
}
