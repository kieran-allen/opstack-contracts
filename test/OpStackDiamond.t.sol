// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../lib/forge-std/src/Test.sol";

import {UserOperation} from "../lib/account-abstraction/contracts/interfaces/UserOperation.sol";

import {ERC4337Helpers} from "./helper-contracts/ERC4337Helpers.t.sol";

contract OpStackDiamond is ERC4337Helpers {
    function test_entryPointAddressIsCorrect() external {
        assertEq(address(diamondEntryPoint.getEntryPoint()), 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
    }

    function test_canHandleOneSimpleUserOperation() external {
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = mockUserOperation;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(accountOwnerPrivateKey, entryPoint.getUserOpHash(ops[0]));
        ops[0].signature = abi.encodePacked(r, s, v);
        entryPoint.handleOps(ops, gasBeneficiary);
    }

    function test_willRevertIfNonceIsNotCorrectlySetOnUserOperation() external {
        UserOperation[] memory ops = new UserOperation[](2);
        ops[0] = mockUserOperation;
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(accountOwnerPrivateKey, entryPoint.getUserOpHash(ops[0]));
        ops[0].signature = abi.encodePacked(r1, s1, v1);

        // ops[1] should have nonce == 1 but does not so should revert
        ops[1] = mockUserOperation;
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(accountOwnerPrivateKey, entryPoint.getUserOpHash(ops[1]));
        ops[1].signature = abi.encodePacked(r2, s2, v2);

        vm.expectRevert();
        entryPoint.handleOps(ops, gasBeneficiary);
    }

    function test_canHandleTwoSimpleUserOperationsCorrectly() external {
        UserOperation[] memory ops = new UserOperation[](2);
        ops[0] = mockUserOperation;
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(accountOwnerPrivateKey, entryPoint.getUserOpHash(ops[0]));
        ops[0].signature = abi.encodePacked(r1, s1, v1);

        ops[1] = mockUserOperation;
        ops[1].nonce = 1;
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(accountOwnerPrivateKey, entryPoint.getUserOpHash(ops[1]));
        ops[1].signature = abi.encodePacked(r2, s2, v2);

        entryPoint.handleOps(ops, gasBeneficiary);
    }

    function test_canHandleThreeSimpleUserOperationsCorrectlyWhereOneFails() external {
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = mockUserOperation;
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(accountOwnerPrivateKey, entryPoint.getUserOpHash(ops[0]));
        ops[0].signature = abi.encodePacked(r1, s1, v1);
        entryPoint.handleOps(ops, gasBeneficiary);

        ops[0] = mockUserOperation;
        ops[0].nonce = 1;
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(accountOwnerPrivateKey, "uh-oh");
        ops[0].signature = abi.encodePacked(r2, s2, v2);
        vm.expectRevert();
        entryPoint.handleOps(ops, gasBeneficiary);

        ops[0] = mockUserOperation;
        ops[0].nonce = 1;
        (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(accountOwnerPrivateKey, entryPoint.getUserOpHash(ops[0]));
        ops[0].signature = abi.encodePacked(r3, s3, v3);
        entryPoint.handleOps(ops, gasBeneficiary);
    }

    function test_canReceiveEth() external {
        vm.deal(externalPublicKey, 3 ether);

        vm.prank(externalPublicKey);
        (bool success,) = address(diamond).call{value: 1 ether}("");

        assertEq(success, true);
        assertEq(address(diamond).balance, 1 ether);
        assertEq(externalPublicKey.balance, 2 ether);
    }

    function test_canSendEth() external {
        vm.deal(address(diamond), 3 ether);

        vm.prank(address(diamond));
        (bool success,) = externalPublicKey.call{value: 1 ether}("");

        assertEq(success, true);
        assertEq(address(diamond).balance, 2 ether);
        assertEq(externalPublicKey.balance, 1 ether);
    }
}
