// test/PriceConsumer.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PriceConsumer.sol";

contract PriceConsumerTest is Test {
    BlocksensePriceConsumer public consumer;
    address constant BLOCKSENSE_PROXY = 0xc04b335A75C5Fa14246152178f6834E3eBc2DC7C;

    function setUp() public {
        consumer = new BlocksensePriceConsumer(BLOCKSENSE_PROXY);
    }

    function testGetBTCPrice() public {
        (uint256 price, uint256 timestamp) = consumer.getBTCPrice();
        console.log("BTC Price:", price);
        console.log("Timestamp:", timestamp);
        assertTrue(price > 0, "BTC price should be greater than 0");
        assertTrue(timestamp > 0, "Timestamp should be greater than 0");
    }

    function testGetETHPrice() public {
        (uint256 price, uint256 timestamp) = consumer.getETHPrice();
        console.log("ETH Price:", price);
        console.log("Timestamp:", timestamp);
        assertTrue(price > 0, "ETH price should be greater than 0");
    }

    function testGetAllPrices() public {
        (uint256[3] memory prices, uint256[3] memory timestamps) = consumer.getAllPrices();
        assertTrue(prices[0] > 0, "BTC price should be greater than 0");
        assertTrue(prices[1] > 0, "ETH price should be greater than 0");
        assertTrue(prices[2] > 0, "EUR price should be greater than 0");
    }
}