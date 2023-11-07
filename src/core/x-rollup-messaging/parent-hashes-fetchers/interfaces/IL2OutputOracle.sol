// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;


interface IL2OutputOracle {
    /**
     * @notice OutputProposal represents a commitment to the L2 state. The timestamp is the L1
     *         timestamp that the output root is posted. This timestamp is used to verify that the
     *         finalization period has passed since the output root was submitted.
     *
     * @custom:field outputRoot    Hash of the L2 output.
     * @custom:field timestamp     Timestamp of the L1 block that the output root was submitted in.
     * @custom:field l2BlockNumber L2 block number that the output corresponds to.
     */
    struct OutputProposal {
        bytes32 outputRoot;
        uint128 timestamp;
        uint128 l2BlockNumber;
    }

    function getL2Output(uint256 _l2OutputIndex) external view returns (OutputProposal memory);
}