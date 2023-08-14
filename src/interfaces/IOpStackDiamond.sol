// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

interface IOpStackDiamond {
    receive() external payable;
    fallback() external payable;

    function validateUserOp(UserOperation calldata op, bytes32, uint256) external returns (uint256 validationData);
}
