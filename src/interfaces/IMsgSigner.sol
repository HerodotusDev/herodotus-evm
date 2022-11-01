// SPDX-License-Identifier: UNLICENSED

interface IMsgSigner {
    function verify(bytes32 hash, bytes calldata sig) external view;

    function signingKey() external view returns (bytes32);
}
