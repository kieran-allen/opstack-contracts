// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

import {ERC4337Helpers} from "./helper-contracts/ERC4337Helpers.t.sol";

import {IOpStackDiamond} from "../src/interfaces/IOpStackDiamond.sol";

contract OpStackDiamondFactory is ERC4337Helpers {
    address public oldDiamondCutFacetAddress;
    address public oldEntryPointFacetAddress;

    address public newDiamondCutFacetAddress;
    address public newEntrypointFacetAddress;

    function setUp() external {
        oldDiamondCutFacetAddress = diamondLoupe.facetAddress(diamondCut.diamondCut.selector);
        oldEntryPointFacetAddress = diamondLoupe.facetAddress(diamondEntryPoint.getEntryPoint.selector);

        newDiamondCutFacetAddress = makeAddr("new_diamond_cut_facet");
        newEntrypointFacetAddress = makeAddr("new_entrypoint_facet");
    }

    function test_shouldReturnTheAlreadyCreatedDiamond() external {
        assertEq(address(diamondFactory.deploy(DEFAULT_SALT, accountOwnerPublicKey)), address(diamond));
    }

    function test_asTheOwnerICanUpdateTheEntryPointAndDiamondCutterFacets() external {
        assertEq(diamondFactory.diamondCutFacet(), oldDiamondCutFacetAddress);
        assertEq(diamondFactory.entryPointFacet(), oldEntryPointFacetAddress);

        vm.startPrank(factoryOwnerPublicKey);
        diamondFactory.updateDiamondCutFacet(newDiamondCutFacetAddress);
        diamondFactory.updateEntryPointFacet(newEntrypointFacetAddress);

        assertEq(diamondFactory.diamondCutFacet(), newDiamondCutFacetAddress);
        assertEq(diamondFactory.entryPointFacet(), newEntrypointFacetAddress);

        vm.stopPrank();
    }

    function test_shouldNotBeAbleToUpdateTheAddressesOfTheDiamondCutFacetAsANonOwner() external {
        assertEq(diamondFactory.diamondCutFacet(), oldDiamondCutFacetAddress);

        vm.expectRevert();
        diamondFactory.updateDiamondCutFacet(newDiamondCutFacetAddress);
    }

    function test_shouldNotBeAbleToUpdateTheAddressesOfTheEntryPointFacetAsANonOwner() external {
        assertEq(diamondFactory.entryPointFacet(), oldEntryPointFacetAddress);

        vm.expectRevert();
        diamondFactory.updateEntryPointFacet(newEntrypointFacetAddress);
    }

    function test_factoryAdminCanGrantTheWriterAndAdminRole() external {
        vm.prank(factoryOwnerPublicKey);
        diamondFactory.grantWriterRoleToAddress(externalPublicKey);

        // external account is now a writer
        assertEq(diamondFactory.rolesOf(externalPublicKey), 2);

        // external account can now update the entry point  facet address
        assertEq(diamondFactory.entryPointFacet(), oldEntryPointFacetAddress);

        vm.prank(externalPublicKey);
        diamondFactory.updateEntryPointFacet(newEntrypointFacetAddress);

        assertEq(diamondFactory.entryPointFacet(), newEntrypointFacetAddress);

        // external account can now update the diamond cut facet address
        assertEq(diamondFactory.diamondCutFacet(), oldDiamondCutFacetAddress);

        vm.prank(externalPublicKey);
        diamondFactory.updateDiamondCutFacet(newDiamondCutFacetAddress);

        assertEq(diamondFactory.diamondCutFacet(), newDiamondCutFacetAddress);

        // external account cannot remove anyone with an admin role from that position
        vm.prank(externalPublicKey);
        vm.expectRevert();
        diamondFactory.revokeAdminRoleFromAddress(factoryOwnerPublicKey);

        // external account cannot remove anyone with an admin role from that position
        vm.prank(externalPublicKey);
        vm.expectRevert();
        diamondFactory.revokeAdminRoleFromAddress(factoryOwnerPublicKey);

        // admin account can remove a writer
        vm.prank(factoryOwnerPublicKey);
        diamondFactory.revokeWriterRoleFromAddress(externalPublicKey);

        // writer can no longer change a facet
        vm.prank(externalPublicKey);
        vm.expectRevert();
        diamondFactory.updateDiamondCutFacet(newDiamondCutFacetAddress);
    }
}
