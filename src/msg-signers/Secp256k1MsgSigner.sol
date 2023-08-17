// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IMsgSigner} from "../interfaces/IMsgSigner.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract Secp256k1MsgSigner is IMsgSigner, Ownable {
    address public signer;

    constructor(address _signer, address _owner) {
        Ownable.transferOwnership(_owner);
        signer = _signer;
    }

    function updateSigner(address newSigner_) external onlyOwner {
        signer = newSigner_;
    }

    function verify(bytes32 hash, bytes calldata sig) external view {
        bool isValid = SignatureChecker.isValidSignatureNow(signer, hash, sig);
        require(isValid, "ERR_INVALID_SIGNATURE");
    }

    function signingKey() external view returns (bytes32) {
        return bytes32(uint256(uint160(signer)));
    }
}
