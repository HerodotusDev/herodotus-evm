#!/bin/bash

source .env
while IFS= read -r line; do
    echo "$line"

    if [[ "$line" =~ ^Deployed\ OpMessagesInbox\ at:\ (0x[0-9A-Fa-f]+)$ ]]; then
        DEPLOYED_L2_INBOX="${BASH_REMATCH[1]}"
    fi
done < <(npx hardhat run script/Deploy_84532_to_4801_part1.ts --network worldChainSepolia)

if [ -z "$DEPLOYED_L2_INBOX" ]; then
    echo "Didn't find deployment address of OpMessagesInbox"
    exit 1
fi

while IFS= read -r line; do
    echo "$line"

    if [[ "$line" =~ ^Deployed\ L1ToOptimismMessagesSender\ at:\ (0x[0-9A-Fa-f]+)$ ]]; then
        DEPLOYED_L1_OUTBOX="${BASH_REMATCH[1]}"
    fi
done < <(DEPLOYED_L2_INBOX=$DEPLOYED_L2_INBOX npx hardhat run script/Deploy_84532_to_4801_part2.ts --network sepolia)

if [ -z "$DEPLOYED_L1_OUTBOX" ]; then
    echo "Didn't find deployment address of L1ToOptimismMessagesSender"
    exit 1
fi

DEPLOYED_L2_INBOX=$DEPLOYED_L2_INBOX DEPLOYED_L1_OUTBOX=$DEPLOYED_L1_OUTBOX npx hardhat run script/Deploy_84532_to_4801_part3.ts --network worldChainSepolia