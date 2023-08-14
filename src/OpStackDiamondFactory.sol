// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IOpStackDiamond} from "./interfaces/IOpStackDiamond.sol";
import {OpStackDiamond} from "./OpStackDiamond.sol";

import {CREATE3} from "solady/src/utils/CREATE3.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";

contract OpStackDiamondFactory is OwnableRoles {
    address public diamondCutFacet;
    address public entryPointFacet;
    address public signatureFacet;

    mapping(address => bool) addresses;

    // Roles:
    // _ROLE_0: (Admin) can add and remove roles
    // _ROLE_1: (Writer) can update the facet addresses but cannot remove or add roles
    constructor(address _diamondCutFacet, address _entryPointFacet, address _signatureFacet) {
        _initializeOwner(msg.sender);
        _grantRoles(msg.sender, _ROLE_0 | _ROLE_1);

        diamondCutFacet = _diamondCutFacet;
        entryPointFacet = _entryPointFacet;
        signatureFacet = _signatureFacet;
    }

    /**
     *
     * Permission functions
     *
     * _ROLE_0: (Admin) can add and remove roles
     * _ROLE_1: (Writer) can update the facet addresses but cannot remove or add roles
     *
     */
    function grantAdminRoleToAddress(address addressToGrant) external onlyRoles(_ROLE_0) {
        _grantRoles(addressToGrant, _ROLE_0 | _ROLE_1);
    }

    function revokeAdminRoleFromAddress(address addressToRevoke) external onlyRoles(_ROLE_0) {
        _removeRoles(addressToRevoke, _ROLE_0 | _ROLE_1);
    }

    function grantWriterRoleToAddress(address addressToGrant) external onlyRoles(_ROLE_0) {
        _grantRoles(addressToGrant, _ROLE_1);
    }

    function revokeWriterRoleFromAddress(address addressToRevoke) external onlyRoles(_ROLE_0) {
        _removeRoles(addressToRevoke, _ROLE_1);
    }

    /**
     *
     * Entry point updator functions
     *
     */
    function updateDiamondCutFacet(address newDiamondCutFacet) external onlyRoles(_ROLE_0 | _ROLE_1) {
        diamondCutFacet = newDiamondCutFacet;
    }

    function updateEntryPointFacet(address newEntryPointFacet) external onlyRoles(_ROLE_0 | _ROLE_1) {
        entryPointFacet = newEntryPointFacet;
    }

    function updateSignatureFacet(address newSignatureFacet) external onlyRoles(_ROLE_0 | _ROLE_1) {
        signatureFacet = newSignatureFacet;
    }

    /**
     *
     * Factory functions
     *
     */
    function deploy(bytes32 salt, address owner) external returns (IOpStackDiamond) {
        address addr = getDeployed(salt);

        // address is already created.
        if (addresses[addr] == true) {
            return IOpStackDiamond(payable(addr));
        }

        // else we need to make a new address
        IOpStackDiamond opStackDiamond = IOpStackDiamond(
            payable(
                CREATE3.deploy(
                    salt,
                    abi.encodePacked(
                        type(OpStackDiamond).creationCode,
                        abi.encode(owner, diamondCutFacet, entryPointFacet, signatureFacet)
                    ),
                    0
                )
            )
        );

        // before returning add the address to the map.
        addresses[address(opStackDiamond)] = true;

        return opStackDiamond;
    }

    function getDeployed(bytes32 salt) public view returns (address) {
        return CREATE3.getDeployed(salt);
    }
}
