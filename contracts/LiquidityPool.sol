// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UnderlyingToken.sol";
import "./GovernanceToken.sol";
import "./LPToken.sol";

contract LiquidityPool is LPToken {
    mapping(address => uint256) public checkpoints;
    UnderlyingToken public underlyingToken;
    GovernanceToken public governanceToken;
    /**
    for reward 
    one person will get 10GovToken * LPToken per block
     */
    uint256 public constant REWARD_PER_BLOCK = 10;

    constructor(address _underlyingAddress, address _governanceAddress) {
        underlyingToken = UnderlyingToken(_underlyingAddress);
        governanceToken = GovernanceToken(_governanceAddress);
    }

    function deposit(uint256 amount) external {
        if (checkpoints[msg.sender] == 0) {
            checkpoints[msg.sender] = block.number;
        }
        _distributeReward(msg.sender);
        underlyingToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Not Enough LPToken");
        _distributeReward(msg.sender);
        underlyingToken.transfer(msg.sender, amount);
        _burn(msg.sender, amount);
    }

    function _distributeReward(address beneficiary) internal {
        require(checkpoints[beneficiary] != 0, "No checkpoinst found");
        uint256 checkpoint = checkpoints[beneficiary];
        if (block.number - checkpoint > 0) {
            uint256 distributionAmount =
                balanceOf(beneficiary) *
                    (block.number - checkpoint) *
                    REWARD_PER_BLOCK;
            governanceToken.mint(beneficiary, distributionAmount);
            checkpoints[beneficiary] = block.number;
        }
    }
}
