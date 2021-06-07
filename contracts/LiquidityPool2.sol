// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UnderlyingToken.sol";
import "./GovernanceToken.sol";
import "./LPToken.sol";

// for fixed Reward per block
// users will share reward because we have been fixing reward per block
contract LiquidityPool2 is LPToken {
    struct Checkpoint {
        uint256 blockNumber;
        uint256 avgTotalBalance;
    }
    mapping(address => Checkpoint) public checkpoints;
    Checkpoint public globalCheckpoint;
    uint256 public constant REWARD_PER_BLOCK = 1000 * 10**18;

    UnderlyingToken public underlyingToken;
    GovernanceToken public governanceToken;
    uint256 public genesisBlock;

    constructor(address _underlyingAddress, address _governanceAddress) {
        underlyingToken = UnderlyingToken(_underlyingAddress);
        governanceToken = GovernanceToken(_governanceAddress);
        genesisBlock = block.number;
        globalCheckpoint.blockNumber = block.number;
    }

    function deposit(uint256 amount) external {
        globalCheckpoint.avgTotalBalance = _getAverageTotalBalance();
        globalCheckpoint.blockNumber = block.number;

        _distributeReward(msg.sender);
        underlyingToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        globalCheckpoint.avgTotalBalance = _getAverageTotalBalance();
        checkpoints[msg.sender].avgTotalBalance = globalCheckpoint
            .avgTotalBalance;
        checkpoints[msg.sender].blockNumber = block.number;
    }

    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "LP Token not enough");
        globalCheckpoint.avgTotalBalance = _getAverageTotalBalance();
        globalCheckpoint.blockNumber = block.number;

        _distributeReward(msg.sender);

        checkpoints[msg.sender].avgTotalBalance = globalCheckpoint
            .avgTotalBalance;
        checkpoints[msg.sender].blockNumber = block.number;

        underlyingToken.transfer(msg.sender, amount);
        _burn(msg.sender, amount);

        globalCheckpoint.avgTotalBalance = _getAverageTotalBalance();
        checkpoints[msg.sender].avgTotalBalance = globalCheckpoint
            .avgTotalBalance;
        checkpoints[msg.sender].blockNumber = block.number;
    }

    function _getAverageTotalBalance()
        public
        view
        returns (uint256 avgBalance)
    {
        if (block.number - genesisBlock == 0) {
            return
                (globalCheckpoint.avgTotalBalance *
                    (globalCheckpoint.blockNumber - genesisBlock) +
                    totalSupply() *
                    (block.number - globalCheckpoint.blockNumber)) /
                (block.number - genesisBlock);
        }
    }

    function _distributeReward(address beneficiary) internal {
        Checkpoint storage userCheckpoint = checkpoints[beneficiary];
        if (block.number - userCheckpoint.blockNumber > 0) {
            uint256 avgTotalBalanceRewardPeriod =
                (globalCheckpoint.avgTotalBalance *
                    globalCheckpoint.blockNumber -
                    userCheckpoint.avgTotalBalance *
                    userCheckpoint.blockNumber) /
                    (block.number - userCheckpoint.blockNumber);
            if (avgTotalBalanceRewardPeriod > 0) {
                uint256 distributionAmount =
                    (balanceOf(beneficiary) *
                        (block.number - userCheckpoint.blockNumber) *
                        REWARD_PER_BLOCK) / avgTotalBalanceRewardPeriod;
                governanceToken.mint(beneficiary, distributionAmount);
            }
        }
    }
}
