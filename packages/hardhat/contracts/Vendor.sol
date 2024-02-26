// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";
import "hardhat/console.sol";

contract Vendor is Ownable {
	uint256 public tokensPerEth = 100;
	event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
	event SellTokens(
		address seller,
		uint256 amountOfTokens,
		uint256 amountOfETH
	);

	YourToken public yourToken;

	constructor(address tokenAddress) {
		yourToken = YourToken(tokenAddress);
	}

	// ToDo: create a payable buyTokens() function:
	function buyTokens() public payable {
		uint256 numOfTokens = msg.value * tokensPerEth;
		bool success = yourToken.transfer(msg.sender, numOfTokens);
		require(success, "failed to transfer tokens");
		emit BuyTokens(msg.sender, msg.value, numOfTokens);
	}

	// ToDo: create a withdraw() function that lets the owner withdraw ETH
	function withdraw() public onlyOwner {
		address contractAddress = address(this);
		(bool sent, ) = payable(msg.sender).call{
			value: contractAddress.balance
		}("");
		require(sent, "Error is sending balance");
	}

	// ToDo: create a sellTokens(uint256 _amount) function:
	function sellTokens(uint256 _amount) public {
		address contractAddress = address(this);
		require(
			yourToken.allowance(msg.sender, contractAddress) >= _amount,
			"approve tokens for sell first"
		);
		bool resultOfTokenTransfer = yourToken.transferFrom(
			msg.sender,
			contractAddress,
			_amount
		);
		require(resultOfTokenTransfer, "Tokens not sold to vendor");
		uint256 _value = (_amount) / tokensPerEth;
		console.log("buyback value = %s", _value);
		(bool resultOfEthTransfer, ) = payable(msg.sender).call{
			value: _value
		}("");
		require(resultOfEthTransfer, "Transfer of ETH failed");
		emit SellTokens(msg.sender, _amount, _value);
	}
}
