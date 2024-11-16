// src/PriceConsumer.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ProxyCall} from "./ProxyCall.sol";

/**
 * @title BlocksensePriceConsumer
 * @notice Smart contract for consuming price feeds from Blocksense Network
 * @dev Uses the ProxyCall library to interact with the Blocksense Network's UpgradeableProxy contract
 */
contract BlocksensePriceConsumer {
    // Feed IDs from config/feeds_config.json
    uint32 private constant BTC_FEED_ID = 31;
    uint32 private constant ETH_FEED_ID = 47;
    uint32 private constant EUR_FEED_ID = 253;
    
    // Immutable storage of the Blocksense Network proxy address
    address public immutable dataFeedStore;
    
    // Minimum time between price updates to consider them valid
    uint256 public constant MAX_PRICE_DELAY = 1 hours;
    
    // Events for tracking
    event PriceUpdate(string indexed asset, uint256 price, uint256 timestamp);
    event StalePrice(string indexed asset, uint256 lastUpdate);
    
    /**
     * @notice Contract constructor
     * @param feedAddress Address of the Blocksense Network UpgradeableProxy contract
     */
    constructor(address feedAddress) {
        require(feedAddress != address(0), "Invalid feed address");
        dataFeedStore = feedAddress;
    }

    /**
     * @notice Get the latest BTC/USD price and timestamp
     */
    function getBTCPrice() public view returns (uint256 price, uint256 timestamp) {
        (int256 value, uint256 ts,) = ProxyCall._latestRoundData(BTC_FEED_ID, dataFeedStore);
        require(value > 0, "Invalid BTC price");
        return (uint256(value), ts);
    }

    /**
     * @notice Get the latest ETH/USD price and timestamp
     */
    function getETHPrice() public view returns (uint256 price, uint256 timestamp) {
        (int256 value, uint256 ts,) = ProxyCall._latestRoundData(ETH_FEED_ID, dataFeedStore);
        require(value > 0, "Invalid ETH price");
        return (uint256(value), ts);
    }

    /**
     * @notice Get the latest EUR/USD price and timestamp
     */
    function getEURPrice() public view returns (uint256 price, uint256 timestamp) {
        (int256 value, uint256 ts,) = ProxyCall._latestRoundData(EUR_FEED_ID, dataFeedStore);
        require(value > 0, "Invalid EUR price");
        return (uint256(value), ts);
    }

    /**
     * @notice Get all prices in a single call
     * @return prices Array of prices [BTC, ETH, EUR]
     * @return timestamps Array of timestamps for each price
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
     * @notice Get the ETH/BTC ratio with 18 decimal precision
     */
    function getETHBTCRatio() external view returns (uint256 ratio, uint256 timestamp) {
        (uint256 btcPrice, uint256 btcTs) = getBTCPrice();
        (uint256 ethPrice, uint256 ethTs) = getETHPrice();
        
        timestamp = btcTs > ethTs ? btcTs : ethTs;
        require(btcPrice > 0, "Invalid BTC price for ratio");
        
        ratio = (ethPrice * 1e18) / btcPrice;
    }

    /**
     * @notice Check for stale prices
     * @return staleCount Number of stale prices found
     * @return staleAssets Names of assets with stale prices
     */
    function checkStalePrices() external view returns (uint256 staleCount, string[] memory staleAssets) {
        (, uint256 btcTs) = getBTCPrice();
        (, uint256 ethTs) = getETHPrice();
        (, uint256 eurTs) = getEURPrice();
        
        // Count stale prices
        if (block.timestamp - btcTs > MAX_PRICE_DELAY) staleCount++;
        if (block.timestamp - ethTs > MAX_PRICE_DELAY) staleCount++;
        if (block.timestamp - eurTs > MAX_PRICE_DELAY) staleCount++;
        
        if (staleCount == 0) return (0, new string[](0));
        
        // Build array of stale asset names
        staleAssets = new string[](staleCount);
        uint256 index;
        
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