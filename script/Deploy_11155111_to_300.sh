#!/bin/bash

source .env
while IFS= read -r line; do
    echo "$line"

    if [[ "$line" =~ ^Deployed\ SimpleMessagesInbox\ at:\ (0x[0-9A-Fa-f]+)$ ]]; then
        DEPLOYED_L2_INBOX="${BASH_REMATCH[1]}"
    fi
done < <(npx hardhat run script/Deploy_11155111_to_300_part1.ts --network zkSyncSepolia)

if [ -z "$DEPLOYED_L2_INBOX" ]; then
    echo "Didn't find deployment address of SimpleMessagesInbox"
    exit 1
fi

while IFS= read -r line; do
    echo "$line"

    if [[ "$line" =~ ^Deployed\ L1ToZkSyncMessagesSender\ at:\ (0x[0-9A-Fa-f]+)$ ]]; then
        DEPLOYED_L1_OUTBOX="${BASH_REMATCH[1]}"
    fi
done < <(DEPLOYED_L2_INBOX=$DEPLOYED_L2_INBOX npx hardhat run script/Deploy_11155111_to_300_part2.ts --network sepolia)

if [ -z "$DEPLOYED_L1_OUTBOX" ]; then
    echo "Didn't find deployment address of L1ToZkSyncMessagesSender"
    exit 1
fi

DEPLOYED_L2_INBOX=$DEPLOYED_L2_INBOX DEPLOYED_L1_OUTBOX=$DEPLOYED_L1_OUTBOX npx hardhat deploy-zksync --script Deploy_11155111_to_300_part3.ts --network zkSyncSepolia
