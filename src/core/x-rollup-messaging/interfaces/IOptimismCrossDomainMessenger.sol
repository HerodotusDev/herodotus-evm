// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;


interface IOptimismCrossDomainMessenger {
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _minGasLimit
    ) external;
}