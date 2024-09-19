source .env

echo -e "Please enter contract addresses for the following contracts:\n"

echo -n "HeadersStore: "
read HEADERS_STORE

echo -n "FactsRegistry: "
read FACTS_REGISTRY

echo -n "SimpleMessagesInbox: "
read SIMPLE_MESSAGES_INBOX

echo -n "OpStackParentHashesFetcher: "
read OP_STACK_PARENT_HASHES_FETCHER

echo -n "L1ToL1MessagesSender: "
read L1_TO_L1_MESSAGES_SENDER

HEADERS_STORE=$HEADERS_STORE \
    FACTS_REGISTRY=$FACTS_REGISTRY \
    SIMPLE_MESSAGES_INBOX=$SIMPLE_MESSAGES_INBOX \
    OP_STACK_PARENT_HASHES_FETCHER=$OP_STACK_PARENT_HASHES_FETCHER \
    L1_TO_L1_MESSAGES_SENDER=$L1_TO_L1_MESSAGES_SENDER \
    npx hardhat run script/Verify_4801_to_11155111.ts --network sepolia
