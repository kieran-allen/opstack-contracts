// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

interface IEntryPointFacet {
    struct FacetState {
        IEntryPoint entryPoint;
    }

    function getEntryPoint() external view returns (IEntryPoint);
}
