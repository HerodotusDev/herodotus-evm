// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";
import {IL2OutputOracle} from "./interfaces/IL2OutputOracle.sol";

/// @title OpStackParentHashesFetcher
/// @notice Fetches parent hashes for the an OP stack based chain, settling to the chain where this contract is deployed
/// @notice for example if deployed on Ethereum, it will fetch parent hashes for Optimism/Base
contract OpStackParentHashesFetcher is IParentHashFetcher {
    IL2OutputOracle public immutable l2OutputOracle;

    constructor(IL2OutputOracle _l2OutputOracle) {
        l2OutputOracle = _l2OutputOracle;
    }

    function fetchParentHash(bytes memory ctx)
        external
        view
        override
        returns (uint256 fetchedForBlock, bytes32 parentHash)
    {
        (uint256 l2OutputIndex, bytes memory outputRootPreimage) = abi.decode(ctx, (uint256, bytes));
        IL2OutputOracle.OutputProposal memory outputProposal = l2OutputOracle.getL2Output(l2OutputIndex);

        // To see the preimage structure and why it is valid, see:
        // https://github.com/ethereum-optimism/optimism/blob/c24298e798f40003f752d12710aa1cad63ad66d1/packages/contracts-bedrock/src/libraries/Hashing.sol#L114
        // https://github.com/ethereum-optimism/optimism/blob/c24298e798f40003f752d12710aa1cad63ad66d1/packages/contracts-bedrock/src/libraries/Types.sol#L25

        // Ensure that the passed preimage matches the output proposal root
        require(outputProposal.outputRoot == keccak256(outputRootPreimage), "ERR_INVALID_OUTPUT_PROPOSAL");

        // Decode the values from the preimage
        (,,, bytes32 latestBlockhash) = abi.decode(outputRootPreimage, (bytes32, bytes32, bytes32, bytes32));

        fetchedForBlock = outputProposal.l2BlockNumber + 1;
        parentHash = latestBlockhash;
    }

    function chainId() external view override returns (uint256) {
        return block.chainid;
    }
}
