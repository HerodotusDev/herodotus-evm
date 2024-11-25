source .env

echo -e "Please enter contract addresses for the following contracts:\n"

echo -n "SimpleMessagesInbox: "
read SIMPLE_MESSAGES_INBOX

echo -n "HeadersStore: "
read HEADERS_STORE

echo -n "FactsRegistry: "
read FACTS_REGISTRY

echo -n "ApeChainMessageForwarder: "
read APE_CHAIN_MESSAGE_FORWARDER

echo -n "NativeParentHashesFetcher: "
read NATIVE_PARENT_HASHES_FETCHER

echo -n "L1ToApeChainMessagesSender: "
read L1_TO_APE_CHAIN_MESSAGES_SENDER

HEADERS_STORE=$HEADERS_STORE \
    FACTS_REGISTRY=$FACTS_REGISTRY \
    SIMPLE_MESSAGES_INBOX=$SIMPLE_MESSAGES_INBOX \
    npx hardhat run script/Verify_11155111_to_33111_part1.ts --network apeChainSepolia

APE_CHAIN_MESSAGE_FORWARDER=$APE_CHAIN_MESSAGE_FORWARDER \
    npx hardhat run script/Verify_11155111_to_33111_part2.ts --network arbitrumSepolia

APE_CHAIN_MESSAGE_FORWARDER=$APE_CHAIN_MESSAGE_FORWARDER \
    SIMPLE_MESSAGES_INBOX=$SIMPLE_MESSAGES_INBOX \
    NATIVE_PARENT_HASHES_FETCHER=$NATIVE_PARENT_HASHES_FETCHER \
    L1_TO_APE_CHAIN_MESSAGES_SENDER=$L1_TO_APE_CHAIN_MESSAGES_SENDER \
    npx hardhat run script/Verify_11155111_to_33111_part3.ts --network sepolia
