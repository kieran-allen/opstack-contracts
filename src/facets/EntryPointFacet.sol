// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IEntryPointFacet} from "../interfaces/IEntryPointFacet.sol";

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

contract EntryPointFacet is IEntryPointFacet {
    address constant entryPointAddress = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    function getEntryPoint() external pure returns (IEntryPoint) {
        return IEntryPoint(entryPointAddress);
    }
}
