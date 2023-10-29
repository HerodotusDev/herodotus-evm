// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;


enum HeaderProperty {
  TIMESTAMP,
  STATE_ROOT,
  RECEIPTS_ROOT,
  TRANSACTIONS_ROOT,
  GAS_USED,
  BASE_FEE_PER_GAS,
  PARENT_HASH,
  MIX_HASH
}

import {Types} from "../../lib/Types.sol";

interface IQuerableTurboSwap {
  function storageSlots(
    uint256 chainId,
    uint256 blockNumber,
    address account,
    bytes32 slot
  ) external returns (bytes32);

  function accounts(
    uint256 chainId,
    uint256 blockNumber,
    address account,
    Types.AccountFields field
  ) external returns (bytes32);

  function headers(
    uint256 chainId,
    uint256 blockNumber,
    HeaderProperty property
  ) external returns (bytes32);
}