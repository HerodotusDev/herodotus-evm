// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {GameType} from "../../../lib/Types.sol";
import {DisputeGameStatus} from "../../../lib/Types.sol";

interface IDisputeGameFactory {
    struct GameSearchResult {
        uint256 index;
        bytes32 metadata;
        uint64 timestamp;
        bytes32 rootClaim;
        bytes extraData;
        DisputeGameStatus status;
    }

    function findLatestGames(
        GameType gameType,
        uint256 start,
        uint256 n
    ) external view returns (GameSearchResult[] memory games);
}