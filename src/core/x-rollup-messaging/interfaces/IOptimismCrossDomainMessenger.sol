// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.20;


interface IOptimismCrossDomainMessenger {
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _minGasLimit
    ) external;
}