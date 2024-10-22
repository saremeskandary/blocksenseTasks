# Writing a Smart Contract that calls FeedRegistry 

In the [README.md](README.md) there are instructions on how to call
`UpgradeableProxy`. This document contains similar instructions on how to call
`FeedRegistry`. The difference between the two Smart Contracts is that
`UpgradeableProxy` can be used to get data from any data feed, as long as the
data feed id is known. `FeedRegistry` can be used to get data from price feeds
that have a base and quote addresses. Not all currencies have addresses, so
`UpgdarableProxy` is more general, but using it is slightly less convenient,
since one needs to encode the feed id in a special format.

Here is a step-by-step guide. It uses `foundry`. It assumes that you have not
changed the repo and are still running the revolut example.

**step 1.** Create a new `foundry` project in a directory that is not inside a git repo:

```
forge init touch-bsn && cd touch-bsn
```

**step 2.** Write a contract that calls the BlockSense Network [FeedRegistry](https://docs.blocksense.network/docs/contracts/integration-guide/using-data-feeds/feed-registry):

```
cat > src/RegistryConsumer.sol
```

Paste the following:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import 'interfaces/IFeedRegistry.sol';

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract RegistryConsumer {
  IFeedRegistry public immutable registry;

  constructor(address _registry) {
    registry = IFeedRegistry(_registry);
  }

  function getDecimals(
    address base,
    address quote
  ) external view returns (uint8 decimals) {
    return registry.decimals(base, quote);
  }

  function getDescription(
    address base,
    address quote
  ) external view returns (string memory description) {
    return registry.description(base, quote);
  }

  function getLatestAnswer(
    address base,
    address quote
  ) external view returns (uint256 asnwer) {
    return uint256(registry.latestAnswer(base, quote));
  }

  function getLatestRound(
    address base,
    address quote
  ) external view returns (uint256 roundId) {
    return registry.latestRound(base, quote);
  }

  function getRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 roundId_,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return registry.getRoundData(base, quote, roundId);
  }

  function getLatestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return registry.latestRoundData(base, quote);
  }

  function getFeed(
    address base,
    address quote
  ) external view returns (IChainlinkAggregator feed) {
    return registry.getFeed(base, quote);
  }
}
```

**interfaces**

For this to work, you would also need these three interface files:

```
mkdir interfaces && mkdir interfaces/chainlink
cat > interfaces/IFeedRegistry.sol
```

**interface 1.** Paste the following:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IChainlinkFeedRegistry, IChainlinkAggregator} from './chainlink/IChainlinkFeedRegistry.sol';

interface IFeedRegistry is IChainlinkFeedRegistry {
  struct FeedData {
    IChainlinkAggregator aggregator;
    uint32 key;
    uint8 decimals;
    string description;
  }

  struct Feed {
    address base;
    address quote;
    address feed;
  }

  error OnlyOwner();

  /// @notice Contract owner
  /// @return owner The address of the owner
  function OWNER() external view returns (address);

  /// @notice Set the feed for a given pair
  /// @dev Stores immutable values (decimals, key, description) and contract address from ChainlinkProxy
  /// @param feeds Array of base, quote and feed address data
  function setFeeds(Feed[] calldata feeds) external;
}
```

**interface 2.** 

```
cat > interfaces/chainlink/IChainlinkFeedRegistry.sol
```

Paste the following:

```solidity
/**
 * SPDX-FileCopyrightText: Copyright (c) 2021 SmartContract ChainLink Limited SEZC
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.24;

import {IChainlinkAggregator} from './IChainlinkAggregator.sol';

interface IChainlinkFeedRegistry {
  /// @notice Get decimals for a feed pair
  /// @param base The base asset of the feed
  /// @param quote The quote asset of the feed
  /// @return decimals The decimals of the feed pair
  function decimals(address base, address quote) external view returns (uint8);

  /// @notice Get description for a feed pair
  /// @param base The base asset of the feed
  /// @param quote The quote asset of the feed
  /// @return description The description of the feed pair
  function description(
    address base,
    address quote
  ) external view returns (string memory);

  /// @notice Get the latest answer for a feed pair
  /// @param base The base asset of the feed
  /// @param quote The quote asset of the feed
  /// @return answer The value sotred for the feed pair
  function latestAnswer(
    address base,
    address quote
  ) external view returns (int256 answer);

  /// @notice Get the latest round ID for a feed pair
  /// @param base The base asset of the feed
  /// @param quote The quote asset of the feed
  /// @return roundId The latest round ID
  function latestRound(
    address base,
    address quote
  ) external view returns (uint256 roundId);

  /// @notice Get the round data for a feed pair at a given round ID
  /// @param base The base asset of the feed
  /// @param quote The quote asset of the feed
  /// @param _roundId The round ID to retrieve data for
  /// @return roundId The round ID
  /// @return answer The value stored for the feed at the given round ID
  /// @return startedAt The timestamp when the value was stored
  /// @return updatedAt Same as startedAt
  /// @return answeredInRound Same as roundId
  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  /// @notice Get the latest round data for a feed pair
  /// @param base The base asset of the feed
  /// @param quote The quote asset of the feed
  /// @return roundId The latest round ID stored for the feed pair
  /// @return answer The latest value stored for the feed pair
  /// @return startedAt The timestamp when the value was stored
  /// @return updatedAt Same as startedAt
  /// @return answeredInRound Same as roundId
  function latestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  /// @notice Get the ChainlinkProxy contract for a feed pair
  /// @param base The base asset of the feed
  /// @param quote The quote asset of the feed
  /// @return aggregator The ChainlinkProxy contract given pair
  function getFeed(
    address base,
    address quote
  ) external view returns (IChainlinkAggregator aggregator);
}
```

**interface 3.** 

```
cat > interfaces/chainlink/IChainlinkAggregator.sol
```

Paste the following:

```solidity
/**
 * SPDX-FileCopyrightText: Copyright (c) 2021 SmartContract ChainLink Limited SEZC
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.24;

interface IChainlinkAggregator {
  /// @notice Decimals for the feed data
  /// @return decimals The decimals of the feed
  function decimals() external view returns (uint8);

  /// @notice Description text for the feed data
  /// @return description The description of the feed
  function description() external view returns (string memory);

  /// @notice Get the latest answer for the feed
  /// @return answer The latest value stored
  function latestAnswer() external view returns (int256);

  /// @notice Get the latest round ID for the feed
  /// @return roundId The latest round ID
  function latestRound() external view returns (uint256);

  /// @notice Get the data for a round at a given round ID
  /// @param _roundId The round ID to retrieve the data for
  /// @return roundId The round ID
  /// @return answer The value stored for the round
  /// @return startedAt Timestamp of when the value was stored
  /// @return updatedAt Same as startedAt
  /// @return answeredInRound Same as roundId
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  /// @notice Get the latest round data available
  /// @return roundId The latest round ID for the feed
  /// @return answer The value stored for the round
  /// @return startedAt Timestamp of when the value was stored
  /// @return updatedAt Same as startedAt
  /// @return answeredInRound Same as roundId
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
```

**step 3.** Build your smart contract:

```
forge build
```

This should work and the output should looks something like this:

```
[⠊] Compiling...
[⠃] Installing Solc version 0.8.24
[⠊] Successfully installed Solc 0.8.24
[⠃] Installing Solc version 0.8.24
[⠊] Successfully installed Solc 0.8.24
[⠃] Compiling 31 files with 0.8.24
[⠒] Solc 0.8.24 finished in 1.84s
Compiler run successful!
```

**step 4.** Register your smart contract:

Before you can register your smart contract, you need to have a place to register it to. Run the sandbox environment and inspect the output:

```
docker compose up
```

The anvil logs contain a list of private keys. Pick the seventh one, because seven is your lucky number (PRIVATE_KEY_FROM_ANVIL).

```
anvil-a-1     | Private Keys
anvil-a-1     | ==================
anvil-a-1     |
anvil-a-1     | (0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
anvil-a-1     | (1) 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
anvil-a-1     | (2) 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
anvil-a-1     | (3) 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
anvil-a-1     | (4) 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
anvil-a-1     | (5) 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
anvil-a-1     | (6) 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
anvil-a-1     | (7) 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356 # PRIVATE_KEY_FROM_ANVIL
anvil-a-1     | (8) 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
anvil-a-1     | (9) 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
```

Also, inspect the logs and look for the address at which `scdeploy` deploys FeedRegistry (ADDRESS_OF_FEED_REGISTRY). The text looks something like this:

```
scdeploy-a-1  | Predicted address for 'FeedRegistry':  0x315980541F03c5d2a32813F66AdF07b13D09dd40 # ADDRESS_OF_FEED_REGISTRY
```

Now, take these two numbers and plug them in the correct places for the `forge create` command:

```
forge create --rpc-url http://0.0.0.0:8545 --private-key <PRIVATE_KEY_FROM_ANVIL> src/RegistryConsumer.sol:RegistryConsumer --constructor-args <ADDRESS_OF_FEED_REGISTRY>
```

Your smart contract should now be registered! You are given the address where it lives:

```
[⠊] Compiling...
[⠒] Installing Solc version 0.8.24
[⠘] Successfully installed Solc 0.8.24
No files changed, compilation skipped
Deployer: 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955
Deployed to: 0x81911707ED6aAe1fD5ee010dA4159c08fE4E850B # MY_CONTRACT_ADDRESS
Transaction hash: 0xd4edced4e4333b3ff3432807e30b9c6205f52c1e7e5e0da31d37508551ad796e
```

**step 5.** Call your smart contract:

Use `cast call` to call your smart contract:

```
cast call <MY_CONTRACT_ADDRESS> "getLatestRoundData(address,address)(uint80,int256,uint256,uint256,uint80)" <BTC_REF> <USD_REF> --rpc-url http://0.0.0.0:8545
```

BTC_REF is 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB. USD_REF is 0x0000000000000000000000000000000000000348, because fiat currencies follow [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217).

You should now see latest round data for the BTC/USD pair stored in your Blocksense Network sandbox setup! It should look something like this:

```
$ cast call 0x81911707ED6aAe1fD5ee010dA4159c08fE4E850B "getLatestRoundData(address,address)(uint80,int256,uint256,uint256,uint80)" 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB 0x0000000000000000000000000000000000000348 --rpc-url http://0.0.0.0:8545
1
66525006260781620000000 [6.652e22]
1729530081 [1.729e9]
1729530081 [1.729e9]
1
```

## Creating your own new Oracle Script

This is the main task of this hackaton - to create your oracle script, feed data to the blockchain and do something interesting or useful with it. To achieve your goal we suggest to use copy-paste-edit strategy with one of our existing oracles.

For example:

```bash
cd examples && cp -r revolut my_oracle
```

edit `my_oracle/spin.toml`:

```toml
spin_manifest_version = 2

[application]
authors = ["Your names"]
name = "Blocksense Oracle Hackaton"
version = "0.1.0"

[application.trigger.settings]
interval_time_in_seconds = 10 # reporting interval in seconds. Adjust if necessary
sequencer = "http://sequencer:8877/post_report"
secret_key = "536d1f9d97166eba5ff0efb8cc8dbeb856fb13d2d126ed1efc761e9955014003"
reporter_id = 0

[[trigger.oracle]]
component = "your-awesome-script"

[[trigger.oracle.data_feeds]]
id = "47" #UPDATE DATA FEEDS IF NEEDED
data = "USD/ETH"

[[trigger.oracle.data_feeds]]
id = "31"
data = "USD/BTC"

[component.your-awesome-script]
source = "target/wasm32-wasi/release/my-awesome-oracle.wasm"
allowed_outbound_hosts = [
"https://awesome-data-feed.com",
]
[component.your-awesome-script.build]
command = "cargo build --target wasm32-wasi --release"
```

Edit `my_oracle/Cargo.toml`:

```toml
[package]
name = "my-awesome-oracle"
authors = ["Your name"]
description = ""
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
wit-bindgen = "0.16.0"
blocksense-sdk = { git = "https://github.com/blocksense-network/sdk.git" }
anyhow = "1.0.82"
serde_json = "1.0"
url = "2.5"
serde = { version = "1.0", features = ["derive"] }

# Add extra dependencies here, if needed

```

If you need a new data feed for your application you can appended to
`config/feed_config.json`

```json
    {
      "id": 42, # Pick some ID that is not occupied, or you can reuse existing one ( but let it be between 0 and 257 )
      "name": "MyToken",
      "fullName": "",
      "description": "MyToken / USD",
      "decimals": 8,
      "report_interval_ms": 30000,
      "quorum_percentage": 1, # Leave unchannged
      "type": "Crypto",
      "script": "CoinMarketCap",
      "pair": {
        "base": "MyToken",
        "quote": "USD"
      },
      "first_report_start_time": {
        "secs_since_epoch": 0,
        "nanos_since_epoch": 0
      },
      "resources": {
        "cmc_id": 123456,
        "cmc_quote": "MyToken"
      }
    },
```

Write the code for your oracle and build it.

Edit `docker-compose.yaml` to start your oracle script:

```yaml
  reporter:
    image: ymadzhunkov/blocksense_hackaton:reporter
    networks:
      - backend
    volumes:
      - ./examples/yahoo:/usr/local/blocksense/oracles/yahoo
      - ./examples/revolut:/usr/local/blocksense/oracles/revolut
      - ./examples/cmc:/usr/local/blocksense/oracles/cmc
      - ./examples/my_oracle:/usr/local/blocksense/oracles/my_oracle
entrypoint: ['/bin/sh', '-c', 'cd /usr/local/blocksense/oracles/my_oracle && /spin up']
    depends_on:
      sequencer:
        condition: service_healthy
```

Restart the entire setup:

```bash
docker compose down
docker compose up
```
