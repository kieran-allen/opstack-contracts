// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DiamondCutFacet} from "../../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/facets/DiamondLoupeFacet.sol";
import {EntryPointFacet} from "../../src/facets/EntryPointFacet.sol";
import {IDiamondCut} from "../../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../src/interfaces/IDiamondLoupe.sol";
import {IEntryPointFacet} from "../../src/interfaces/IEntryPointFacet.sol";
import {IERC165} from "../../src/interfaces/IERC165.sol";
import {IERC173} from "../../src/interfaces/IERC173.sol";
import {IOpStackDiamond} from "../../src/interfaces/IOpStackDiamond.sol";
import {ISignatureFacet} from "../../src/interfaces/ISignatureFacet.sol";
import {OpStackDiamond} from "../../src/OpStackDiamond.sol";
import {OpStackDiamondFactory} from "../../src/OpStackDiamondFactory.sol";
import {OwnershipFacet} from "../../src/facets/OwnershipFacet.sol";
import {SignatureFacet} from "../../src/facets/SignatureFacet.sol";

import {Test} from "forge-std/Test.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

abstract contract DeployedOpStackDiamond is Test {
    bytes32 public constant DEFAULT_SALT = "A salt!";

    DiamondCutFacet private immutable diamondCutFacet = new DiamondCutFacet();
    DiamondLoupeFacet private immutable diamondLoupeFacet = new DiamondLoupeFacet();
    OwnershipFacet private immutable ownershipFacet = new OwnershipFacet();
    EntryPointFacet private immutable entryPointFacet = new EntryPointFacet();
    SignatureFacet private immutable signatureFacet = new SignatureFacet();

    IDiamondCut public diamondCut;
    IERC173 public diamondOwnership;
    IDiamondLoupe public diamondLoupe;
    IERC165 public diamondIERC165;
    IEntryPointFacet public diamondEntryPoint;
    ISignatureFacet public diamondSignature;

    IOpStackDiamond public diamond;
    OpStackDiamondFactory public diamondFactory;

    address public accountOwnerPublicKey;
    uint256 public accountOwnerPrivateKey;

    address public factoryOwnerPublicKey;
    uint256 public factoryOwnerPrivateKey;

    address public externalPublicKey;
    uint256 public externalPrivateKey;

    constructor() {
        (address pub, uint256 priv) = makeAddrAndKey("account_owner");
        (address pubExternal, uint256 privExternal) = makeAddrAndKey("external_user");
        (address factoryPub, uint256 factoryPriv) = makeAddrAndKey("factory_owner");

        accountOwnerPublicKey = pub;
        accountOwnerPrivateKey = priv;

        externalPublicKey = pubExternal;
        externalPrivateKey = privExternal;

        factoryOwnerPublicKey = factoryPub;
        factoryOwnerPrivateKey = factoryPriv;

        vm.prank(factoryOwnerPublicKey);
        diamondFactory =
            new OpStackDiamondFactory(address(diamondCutFacet), address(entryPointFacet), address(signatureFacet));

        diamond = diamondFactory.deploy(DEFAULT_SALT, accountOwnerPublicKey);

        diamondCut = IDiamondCut(address(diamond));
        diamondOwnership = IERC173(address(diamond));
        diamondLoupe = IDiamondLoupe(address(diamond));
        diamondIERC165 = IERC165(address(diamond));
        diamondEntryPoint = IEntryPointFacet(address(diamond));

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);
        cuts[0] = getOwnershipFacetCut();
        cuts[1] = getLoupeFacetCut();

        vm.prank(accountOwnerPublicKey);
        diamondCut.diamondCut(cuts, address(0), "");
    }

    function getOwnershipFacetCut() private view returns (IDiamondCut.FacetCut memory) {
        IDiamondCut.FacetCut memory ownershipFacetCut;
        ownershipFacetCut.facetAddress = address(ownershipFacet);
        ownershipFacetCut.action = IDiamondCut.FacetCutAction.Add;

        bytes4[] memory ownershipFunctionSelectors = new bytes4[](2);
        ownershipFunctionSelectors[0] = IERC173.transferOwnership.selector;
        ownershipFunctionSelectors[1] = IERC173.owner.selector;

        ownershipFacetCut.functionSelectors = ownershipFunctionSelectors;

        return ownershipFacetCut;
    }

    function getLoupeFacetCut() private view returns (IDiamondCut.FacetCut memory) {
        IDiamondCut.FacetCut memory loupeFacetCut;
        loupeFacetCut.facetAddress = address(diamondLoupeFacet);
        loupeFacetCut.action = IDiamondCut.FacetCutAction.Add;

        bytes4[] memory loupeFunctionSelectors = new bytes4[](4);
        loupeFunctionSelectors[0] = IDiamondLoupe.facets.selector;
        loupeFunctionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeFunctionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeFunctionSelectors[3] = IDiamondLoupe.facetAddress.selector;

        loupeFacetCut.functionSelectors = loupeFunctionSelectors;

        return loupeFacetCut;
    }
}
