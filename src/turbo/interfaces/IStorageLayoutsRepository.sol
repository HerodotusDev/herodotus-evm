// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IStorageLayoutsRepository {
    function getVariableToSlotMapperForTarget(uint256 chainId, address target) external view returns (IStorageVariableToSlotMapper);
}

interface IStorageVariableToSlotMapper {
    function getSlotForVariableAndKeys(string memory variableName, bytes memory keys) external view returns (bytes32);
}