// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IValidityProofVerifier {
    function verifyProof(bytes memory proof, bytes memory publicInputs) external view returns (bool);
}
