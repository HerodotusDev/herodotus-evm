// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersStorage} from "./interfaces/IHeadersStorage.sol";

contract FactsRegistry {
    IHeadersStorage public immutable headersStorage;

    constructor(IHeadersStorage _headersStorage) {
        headersStorage = _headersStorage;
    }
}
