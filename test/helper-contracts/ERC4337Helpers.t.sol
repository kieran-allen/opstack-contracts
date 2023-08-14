// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DeployedOpStackDiamond} from "./DeployedOpStackDiamond.t.sol";

import {IDiamondCut} from "../../src/interfaces/IDiamondCut.sol";
import {IEntryPointFacet} from "../../src/interfaces/IEntryPointFacet.sol";

import {Test} from "forge-std/Test.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

contract ERC4337Helpers is Test, DeployedOpStackDiamond {
    IEntryPoint public entryPoint;

    UserOperation public mockUserOperation;

    // create the gas beneficiary address
    address payable public immutable gasBeneficiary = payable(makeAddr("gasBeneficiary"));

    constructor() {
        // create an entry point with a non entry point address;
        entryPoint = new EntryPoint();

        // set the entry point code on the expected address of the entry point facet
        // and reset the value of entryPoint to this addressed entry point
        vm.etch(address(diamondEntryPoint.getEntryPoint()), address(entryPoint).code);
        entryPoint = diamondEntryPoint.getEntryPoint();

        mockUserOperation = generateMockUserOperation();

        // give ether to our account
        vm.deal(accountOwnerPublicKey, 1000 ether);
        // and send this to the entry point as a deposit for our future operations
        vm.prank(accountOwnerPublicKey);
        entryPoint.depositTo{value: 1000 ether}(address(diamond));
    }

    function generateMockUserOperation() private view returns (UserOperation memory) {
        UserOperation memory op;
        op.sender = address(diamond);
        op.nonce = 0;
        op.initCode = "";
        op.callData = "";
        op.callGasLimit = 0.001 gwei;
        op.verificationGasLimit = 0.001 gwei;
        op.preVerificationGas = 0.001 gwei;
        op.maxFeePerGas = 0.3 gwei;
        op.maxPriorityFeePerGas = 0.3 gwei;
        op.paymasterAndData = "";
        op.signature = "";
        return op;
    }
}
