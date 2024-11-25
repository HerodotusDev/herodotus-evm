#!/bin/bash

source .env

while IFS= read -r line; do
    echo "$line"

    if [[ "$line" =~ ^Deployed\ ApeChainMessageForwarder\ at:\ (0x[0-9A-Fa-f]+)$ ]]; then
        DEPLOYED_L2_MSG_FORWARDER="${BASH_REMATCH[1]}"
    fi
done < <(npx hardhat run script/Deploy_11155111_to_33111_part1.ts --network arbitrumSepolia)

if [ -z "$DEPLOYED_L2_MSG_FORWARDER" ]; then
    echo "Didn't find deployment address of ApeChainMessageForwarder"
    exit 1
fi

while IFS= read -r line; do
    echo "$line"

    if [[ "$line" =~ ^Deployed\ SimpleMessagesInbox\ at:\ (0x[0-9A-Fa-f]+)$ ]]; then
        DEPLOYED_L3_INBOX="${BASH_REMATCH[1]}"
    fi
done < <(DEPLOYED_L2_MSG_FORWARDER=$DEPLOYED_L2_MSG_FORWARDER npx hardhat run script/Deploy_11155111_to_33111_part2.ts --network apeChainSepolia)

if [ -z "$DEPLOYED_L3_INBOX" ]; then
    echo "Didn't find deployment address of SimpleMessagesInbox"
    exit 1
fi

while IFS= read -r line; do
    echo "$line"

    if [[ "$line" =~ ^Deployed\ L1ToApeChainMessagesSender\ at:\ (0x[0-9A-Fa-f]+)$ ]]; then
        DEPLOYED_L1_OUTBOX="${BASH_REMATCH[1]}"
    fi
done < <(DEPLOYED_L3_INBOX=$DEPLOYED_L3_INBOX DEPLOYED_L2_MSG_FORWARDER=$DEPLOYED_L2_MSG_FORWARDER npx hardhat run script/Deploy_11155111_to_33111_part3.ts --network sepolia)

if [ -z "$DEPLOYED_L1_OUTBOX" ]; then
    echo "Didn't find deployment address of L1ToApeChainMessagesSender"
    exit 1
fi

DEPLOYED_L2_MSG_FORWARDER=$DEPLOYED_L2_MSG_FORWARDER DEPLOYED_L1_OUTBOX=$DEPLOYED_L1_OUTBOX npx hardhat run script/Deploy_11155111_to_33111_part4.ts --network arbitrumSepolia
