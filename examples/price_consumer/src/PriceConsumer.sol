// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ProxyCall.sol";

/**
 * @title BlocksensePriceConsumer
 * @notice Contract for consuming price feeds from the Blocksense Network
 * @dev Uses ProxyCall library to interact with the Blocksense Network's UpgradeableProxy contract
 */
contract BlocksensePriceConsumer {
    // Feed IDs as defined in config/feeds_config.json
    // Each ID corresponds to a specific price feed in the Blocksense Network
    uint32 private constant BTC_FEED_ID = 31;   // Bitcoin/USD price feed
    uint32 private constant ETH_FEED_ID = 47;   // Ethereum/USD price feed
    uint32 private constant EUR_FEED_ID = 253;  // Euro/USD price feed
    
    // Address of the Blocksense Network's UpgradeableProxy contract
    // This contract serves as the entry point for all price feed data
    address public immutable dataFeedStore;

    // Maximum allowed time difference between current time and last price update
    // If a price is older than this, it's considered stale
    uint256 public constant MAX_PRICE_DELAY = 1 hours;
    
    // Events for tracking price updates and stale prices
    event PriceUpdate(string indexed asset, uint256 price, uint256 timestamp);
    event StalePrice(string indexed asset, uint256 lastUpdate);
    
    /**
     * @notice Contract constructor
     * @param feedAddress Address of the Blocksense Network UpgradeableProxy contract
     * @dev Validates that a non-zero address is provided
     */
    constructor(address feedAddress) {
        require(feedAddress != address(0), "Invalid feed address");
        dataFeedStore = feedAddress;
    }

    /**
     * @notice Get the latest BTC/USD price
     * @return price The current BTC price in USD with 18 decimals
     * @return timestamp The timestamp of when this price was last updated
     * @dev Fetches price through ProxyCall library and validates it's positive
     */
    function getBTCPrice() public view returns (uint256 price, uint256 timestamp) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = 
            ProxyCall._latestRoundData(BTC_FEED_ID, dataFeedStore);
        require(answer > 0, "Invalid BTC price");
        return (uint256(answer), startedAt);
    }

    /**
     * @notice Get the latest ETH/USD price
     * @return price The current ETH price in USD with 18 decimals
     * @return timestamp The timestamp of when this price was last updated
     * @dev Fetches price through ProxyCall library and validates it's positive
     */
    function getETHPrice() public view returns (uint256 price, uint256 timestamp) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = 
            ProxyCall._latestRoundData(ETH_FEED_ID, dataFeedStore);
        require(answer > 0, "Invalid ETH price");
        return (uint256(answer), startedAt);
    }

    /**
     * @notice Get the latest EUR/USD price
     * @return price The current EUR price in USD with 18 decimals
     * @return timestamp The timestamp of when this price was last updated
     * @dev Fetches price through ProxyCall library and validates it's positive
     */
    function getEURPrice() public view returns (uint256 price, uint256 timestamp) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = 
            ProxyCall._latestRoundData(EUR_FEED_ID, dataFeedStore);
        require(answer > 0, "Invalid EUR price");
        return (uint256(answer), startedAt);
    }

    /**
     * @notice Get all prices in a single call
     * @return prices Array of prices [BTC/USD, ETH/USD, EUR/USD] with 18 decimals
     * @return timestamps Array of timestamps corresponding to each price
     * @dev Useful for reducing the number of blockchain calls when multiple prices are needed
     */
    function getAllPrices() external view returns (
        uint256[3] memory prices,
        uint256[3] memory timestamps
    ) {
        (prices[0], timestamps[0]) = getBTCPrice();
        (prices[1], timestamps[1]) = getETHPrice();
        (prices[2], timestamps[2]) = getEURPrice();
    }

    /**
     * @notice Calculate the ETH/BTC price ratio
     * @return ratio The ETH/BTC ratio with 18 decimals
     * @return timestamp The most recent timestamp between both price feeds
     * @dev Uses the most recent timestamp of the two feeds for the returned timestamp
     */
    function getETHBTCRatio() external view returns (uint256 ratio, uint256 timestamp) {
        (uint256 btcPrice, uint256 btcTs) = getBTCPrice();
        (uint256 ethPrice, uint256 ethTs) = getETHPrice();
        
        // Use the most recent timestamp
        timestamp = btcTs > ethTs ? btcTs : ethTs;
        require(btcPrice > 0, "Invalid BTC price for ratio");
        
        // Calculate ratio maintaining precision
        ratio = (ethPrice * 1e18) / btcPrice;
    }

    /**
     * @notice Check if any price feeds are stale
     * @return staleCount Number of stale price feeds
     * @return staleAssets Array of asset names with stale prices
     * @dev A price is considered stale if it's older than MAX_PRICE_DELAY
     */
    function checkStalePrices() external view returns (uint256 staleCount, string[] memory staleAssets) {
        // Get timestamps for all price feeds
        (, uint256 btcTs) = getBTCPrice();
        (, uint256 ethTs) = getETHPrice();
        (, uint256 eurTs) = getEURPrice();
        
        // Count how many prices are stale
        if (block.timestamp - btcTs > MAX_PRICE_DELAY) staleCount++;
        if (block.timestamp - ethTs > MAX_PRICE_DELAY) staleCount++;
        if (block.timestamp - eurTs > MAX_PRICE_DELAY) staleCount++;
        
        // If no stale prices, return early
        if (staleCount == 0) return (0, new string[](0));
        
        // Create array of stale asset names
        staleAssets = new string[](staleCount);
        uint256 index;
        
        // Add each stale asset to the array
        if (block.timestamp - btcTs > MAX_PRICE_DELAY) {
            staleAssets[index++] = "BTC/USD";
        }
        if (block.timestamp - ethTs > MAX_PRICE_DELAY) {
            staleAssets[index++] = "ETH/USD";
        }
        if (block.timestamp - eurTs > MAX_PRICE_DELAY) {
            staleAssets[index] = "EUR/USD";
        }
    }
}