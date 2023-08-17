// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IValidityProofVerifier {
    function verifyProof(bytes memory proof, bytes memory publicInput, bytes memory signature) external view returns (bool);
}
