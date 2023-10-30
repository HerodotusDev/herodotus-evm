// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ITurboInvoker} from "../interfaces/ITurboInvoker.sol";
import {IStorageLayoutsRepository, IStorageVariableToSlotMapper} from "../interfaces/IStorageLayoutsRepository.sol";
import {IQuerableTurboSwap} from "../interfaces/IQuerableTurboSwap.sol";


contract TurboStorageReader {
    IQuerableTurboSwap public immutable turboSwap;

    constructor(IQuerableTurboSwap _turboswap) {
        turboSwap = _turboswap;
    }

    function readVariable(
        uint256 chainId,
        address target,
        uint256 blockNumber,
        string memory variableName,
        bytes memory encodedKeys
    ) external returns(bytes32) {
        IStorageLayoutsRepository layoutsRepository = IStorageLayoutsRepository(
            ITurboInvoker(msg.sender).storageLayoutsRepository()
        );
        IStorageVariableToSlotMapper mapper = layoutsRepository.getVariableToSlotMapperForTarget(chainId, target);
        bytes32 slot = mapper.getSlotForVariableAndKeys(variableName, encodedKeys);
        return turboSwap.storageSlots(chainId, blockNumber, target, slot);
    }
}