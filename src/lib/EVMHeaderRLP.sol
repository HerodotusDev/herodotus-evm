// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

// This library extracts data from Block header encoded in RLP format.
// 0    RLP length              1+2
// 1    parentHash              1+32
// 2    ommersHash              1+32
// 3    beneficiary             1+20
// 4    stateRoot               1+32
// 5    TransactionRoot         1+32
// 6    receiptsRoot            1+32
//      logsBloom length        1+2
// 7    logsBloom               256
//  Total static elements size: 448 bytes
// 8	difficulty  - starts at pos 448
// 9	number      - blockNumber
// 10	gasLimit
// 11	gasUsed
// 12	timestamp
// 13	extraData
// 14	mixHash
// 15	nonce
// 16	baseFee
// 17   withdrawalsRoot

library EVMHeaderRLP {
    function nextElementJump(uint8 prefix) public pure returns (uint8) {
        if (prefix <= 128) {
            return 1;
        } else if (prefix <= 183) {
            return prefix - 128 + 1;
        }
        revert("EVMHeaderRLP.nextElementJump: Given element length not implemented");
    }

    // no loop saves ~300 gas
    function getBlockNumberPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    // no loop saves ~300 gas
    function getGasLimitPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    // no loop saves ~300 gas
    function getTimestampPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        //4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        //timestamp - jackpot!
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function getMixHashPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        //4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        // 5th element - timestamp
        pos += nextElementJump(uint8(rlp[pos]));
        // 6th element - extradata
        pos += nextElementJump(uint8(rlp[pos]));
        // 7th element - mixhash
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function getBaseFeePositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        //jumping straight to the 1st dynamic element at pos 448 - difficulty
        uint256 pos = 448;

        // 2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        // 3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        // 4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        // timestamp
        pos += nextElementJump(uint8(rlp[pos]));
        // extradata
        pos += nextElementJump(uint8(rlp[pos]));
        // mixhash
        pos += nextElementJump(uint8(rlp[pos]));
        // nonce
        pos += nextElementJump(uint8(rlp[pos]));
        // nonce
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function extractFromRLP(bytes calldata rlp, uint256 elementPosition) public pure returns (uint256 element) {
        // RLP hint: If the byte is less than 128 - than this byte IS the value needed - just return it.
        if (uint8(rlp[elementPosition]) < 128) {
            return uint256(uint8(rlp[elementPosition]));
        }

        // RLP hint: Otherwise - this byte stores the length of the element needed (in bytes).
        uint8 elementSize = uint8(rlp[elementPosition]) - 128;

        // ABI Encoding hint for dynamic bytes element:
        //  0x00-0x04 (4 bytes): Function signature
        //  0x05-0x23 (32 bytes uint): Offset to raw data of RLP[]
        //  0x24-0x43 (32 bytes uint): Length of RLP's raw data (in bytes)
        //  0x44-.... The RLP raw data starts here
        //  0x44 + elementPosition: 1 byte stores a length of our element
        //  0x44 + elementPosition + 1: Raw data of the element

        // Copies the element from calldata to uint256 stored in memory
        assembly {
            calldatacopy(
                add(mload(0x40), sub(32, elementSize)), // Copy to: Memory 0x40 (free memory pointer) + 32bytes (uint256 size) - length of our element (in bytes)
                add(0x44, add(elementPosition, 1)), // Copy from: Calldata 0x44 (RLP raw data offset) + elementPosition + 1 byte for the size of element
                elementSize
            )
            element := mload(mload(0x40)) // Load the 32 bytes (uint256) stored at memory 0x40 pointer - into return value
        }
        return element;
    }

    function getBlockNumber(bytes calldata rlp) public pure returns (uint256) {
        return extractFromRLP(rlp, getBlockNumberPositionNoLoop(rlp));
    }

    function getTimestamp(bytes calldata rlp) public pure returns (uint256) {
        return extractFromRLP(rlp, getTimestampPositionNoLoop(rlp));
    }

    function getDifficulty(bytes calldata rlp) public pure returns (uint256) {
        return extractFromRLP(rlp, 448);
    }

    function getGasLimit(bytes calldata rlp) public pure returns (uint256) {
        return extractFromRLP(rlp, getGasLimitPositionNoLoop(rlp));
    }

    function getBaseFee(bytes calldata rlp) public pure returns (uint256) {
        return extractFromRLP(rlp, getBaseFeePositionNoLoop(rlp));
    }

    function getParentHash(bytes calldata rlp) public pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 3));
    }

    function getUnclesHash(bytes calldata rlp) public pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 36));
    }

    function getBeneficiary(bytes calldata rlp) public pure returns (address) {
        return address(uint160(extractFromRLP(rlp, 70)));
    }

    function getStateRoot(bytes calldata rlp) public pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 90));
    }

    function getTransactionsRoot(bytes calldata rlp) public pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 123));
    }

    function getReceiptsRoot(bytes calldata rlp) public pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 156));
    }

    function getMixHash(bytes calldata rlp) public pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, getMixHashPositionNoLoop(rlp)));
    }
}
