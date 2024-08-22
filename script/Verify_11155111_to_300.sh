source .env

echo -e "Please enter contract addresses for the following contracts:\n"

echo -n "HeadersStore: "
read HEADERS_STORE

echo -n "FactsRegistry: "
read FACTS_REGISTRY

echo -n "SimpleMessagesInbox: "
read SIMPLE_MESSAGES_INBOX

echo -n "NativeParentHashesFetcher: "
read NATIVE_PARENT_HASHES_FETCHER

echo -n "L1ToZkSyncMessagesSender: "
read L1_TO_ZKSYNC_MESSAGES_SENDER

HEADERS_STORE=$HEADERS_STORE \
    FACTS_REGISTRY=$FACTS_REGISTRY \
    SIMPLE_MESSAGES_INBOX=$SIMPLE_MESSAGES_INBOX \
    npx hardhat run script/Verify_11155111_to_300_part1.ts --network zkSyncSepolia

SIMPLE_MESSAGES_INBOX=$SIMPLE_MESSAGES_INBOX \
    NATIVE_PARENT_HASHES_FETCHER=$NATIVE_PARENT_HASHES_FETCHER \
    L1_TO_ZKSYNC_MESSAGES_SENDER=$L1_TO_ZKSYNC_MESSAGES_SENDER \
    npx hardhat run script/Verify_11155111_to_300_part2.ts --network sepolia
