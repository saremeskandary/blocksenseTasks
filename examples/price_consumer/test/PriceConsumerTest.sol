// test/PriceConsumer.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {BlocksensePriceConsumer} from "../src/PriceConsumer.sol";

contract PriceConsumerTest is Test {
    BlocksensePriceConsumer public consumer;
    address constant BLOCKSENSE_PROXY = 0xc04b335A75C5Fa14246152178f6834E3eBc2DC7C;

    function setUp() public {
        // Deploy consumer contract with Blocksense proxy address
        consumer = new BlocksensePriceConsumer(BLOCKSENSE_PROXY);
    }

    function testGetBTCPrice() public {
        (uint256 price, uint256 timestamp) = consumer.getBTCPrice();
        console2.log("BTC Price:", price);
        console2.log("Timestamp:", timestamp);
        assertTrue(price > 0, "BTC price should be greater than 0");
        assertTrue(timestamp > 0, "Timestamp should be greater than 0");
    }

    function testGetETHPrice() public {
        (uint256 price, uint256 timestamp) = consumer.getETHPrice();
        console2.log("ETH Price:", price);
        console2.log("Timestamp:", timestamp);
        assertTrue(price > 0, "ETH price should be greater than 0");
        assertTrue(timestamp > 0, "Timestamp should be greater than 0");
    }

    function testGetEURPrice() public {
        (uint256 price, uint256 timestamp) = consumer.getEURPrice();
        console2.log("EUR Price:", price);
        console2.log("Timestamp:", timestamp);
        assertTrue(price > 0, "EUR price should be greater than 0");
        assertTrue(timestamp > 0, "Timestamp should be greater than 0");
    }

    function testGetAllPrices() public {
        (uint256[3] memory prices, uint256[3] memory timestamps) = consumer.getAllPrices();
        
        console2.log("BTC Price:", prices[0]);
        console2.log("ETH Price:", prices[1]);
        console2.log("EUR Price:", prices[2]);
        
        assertTrue(prices[0] > 0, "BTC price should be greater than 0");
        assertTrue(prices[1] > 0, "ETH price should be greater than 0");
        assertTrue(prices[2] > 0, "EUR price should be greater than 0");
    }

    function testGetETHBTCRatio() public {
        (uint256 ratio, uint256 timestamp) = consumer.getETHBTCRatio();
        console2.log("ETH/BTC Ratio:", ratio);
        console2.log("Timestamp:", timestamp);
        assertTrue(ratio > 0, "ETH/BTC ratio should be greater than 0");
        assertTrue(timestamp > 0, "Timestamp should be greater than 0");
    }
}