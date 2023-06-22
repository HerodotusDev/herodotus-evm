// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IValidityProofVerifier} from "../interfaces/IValidityProofVerifier.sol";
import {IMsgSigner} from "../interfaces/IMsgSigner.sol";

contract ValidityProofVerifier is IValidityProofVerifier {
    IMsgSigner public immutable signer;

    constructor(IMsgSigner _signer) {
        signer = _signer;
    }

    /**
     * verifyProof verifies a zero-knowledge proof
     * @param proof zero-knowledge proof
     * @param publicInput public input of the ZKP
     * @param signature signature from authorized signer to call this function
     */
    function verifyProof(bytes calldata proof, bytes memory publicInput, bytes calldata signature) external view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(msg.sig, proof, publicInput, address(this)));
        signer.verify(msgHash, signature);

        // TODO: verify proof

        return true;
    }
}
