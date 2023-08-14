// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

interface ISignatureFacet {
    function isValidSignature(bytes calldata userOpSignature, bytes32 userOpHash) external view returns (bool);
}
