// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";

import {IHeadersStorage} from "../src/interfaces/IHeadersStorage.sol";

import {FactsRegistry} from "../src/FactsRegistry.sol";

contract HeadersStorageMock is IHeadersStorage {
    function stateRoots(uint256) external pure returns (bytes32) {
        return 0x96e1a0f4e5cf9c0d134ac184c25c3f617cc89f8261314285d7c51981c57783b2;
    }

    function parentHashes(uint256) external pure returns (bytes32) {
        revert("MOCK_NOT_IMPLEMENTED");
    }

    function receiptsRoots(uint256) external pure returns (bytes32) {
        revert("MOCK_NOT_IMPLEMENTED");
    }

    function transactionsRoots(uint256) external pure returns (bytes32) {
        revert("MOCK_NOT_IMPLEMENTED");
    }

    function unclesHashes(uint256) external pure returns (bytes32) {
        revert("MOCK_NOT_IMPLEMENTED");
    }
}

contract FactsRegistry_Test is Test {
    FactsRegistry private factsRegistry;
    IHeadersStorage private headersStorage;

    constructor() {
        headersStorage = IHeadersStorage(address(new HeadersStorageMock()));
        factsRegistry = new FactsRegistry(headersStorage);
    }

    function test_proveAccount() public {
        string[] memory inputs = new string[](6);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_state_proof.js";
        inputs[2] = "7583802";
        inputs[3] = "0x456cb24d30eaa6affc2a6924dae0d2a0a8c99c73";
        inputs[4] = "0x54cdd369e4e8a8515e52ca72ec816c2101831ad1f18bf44102ed171459c9b4f8";
        inputs[5] = "account";
        bytes memory proof = vm.ffi(inputs);

        uint16 bitmap = 15; // 0b1111
        uint256 blockNumber = 7583802;
        address account = address(uint160(uint256(0x00456cb24d30eaa6affc2a6924dae0d2a0a8c99c73)));

        factsRegistry.proveAccount(bitmap, blockNumber, account, proof);
    }
}
