// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ISignatureFacet} from "../interfaces/ISignatureFacet.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

import {ECDSA} from "solady/src/utils/ECDSA.sol";

contract SignatureFacet is ISignatureFacet {
    function isValidSignature(bytes calldata userOpSignature, bytes32 userOpHash) external view returns (bool) {
        address owner = LibDiamond.contractOwner();
        address recovered = ECDSA.recover(userOpHash, userOpSignature);

        return owner == recovered;
    }
}
