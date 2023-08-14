// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {LibDiamond} from "./libraries/LibDiamond.sol";

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IEntryPointFacet} from "./interfaces/IEntryPointFacet.sol";
import {ISignatureFacet} from "./interfaces/ISignatureFacet.sol";
import {IOpStackDiamond} from "./interfaces/IOpStackDiamond.sol";

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

contract OpStackDiamond is IOpStackDiamond {
    uint256 internal constant SIG_VALIDATION_FAILURE = 1;
    uint256 internal constant SIG_VALIDATION_SUCCESS = 0;

    uint256 private nonce;

    constructor(address _contractOwner, address _diamondCutFacet, address _entryPointFacet, address _signatureFacet)
        payable
    {
        nonce = 0;

        LibDiamond.setContractOwner(_contractOwner);

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);

        // Add the diamondCut external function from the diamondCutFacet.
        bytes4[] memory diamondCutFunctionSelectors = new bytes4[](1);
        diamondCutFunctionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: diamondCutFunctionSelectors
        });

        // Add the entry point facet by default.
        bytes4[] memory entryPointFunctionSelectors = new bytes4[](1);
        entryPointFunctionSelectors[0] = IEntryPointFacet.getEntryPoint.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _entryPointFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: entryPointFunctionSelectors
        });

        // Add the basic signature facet by default.
        bytes4[] memory signatureFunctionSelectors = new bytes4[](1);
        signatureFunctionSelectors[0] = ISignatureFacet.isValidSignature.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _signatureFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: signatureFunctionSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}

    function _enforceIsFromEntryPoint() internal view {
        IEntryPoint entryPoint = IEntryPointFacet(address(this)).getEntryPoint();
        require(msg.sender == address(entryPoint), "AccountFacet: msg sender is not equal to entry point facet address");
    }

    function _enforceIsNonceValid(uint256 userOpNonce) internal view {
        require(userOpNonce == nonce, "OpStackDiamond: user operation nonce is not equal to OpStackDiamond nonce");
    }

    function validateUserOp(UserOperation calldata op, bytes32 userOpHash, uint256)
        external
        returns (uint256 validationData)
    {
        _enforceIsFromEntryPoint();
        _enforceIsNonceValid(op.nonce);

        bool isValidSignature = ISignatureFacet(address(this)).isValidSignature(op.signature, userOpHash);

        if (!isValidSignature) {
            return SIG_VALIDATION_FAILURE;
        }

        nonce++;
        return SIG_VALIDATION_SUCCESS;
    }
}
