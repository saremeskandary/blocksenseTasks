// script/DeployPriceConsumer.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {BlocksensePriceConsumer} from "../src/PriceConsumer.sol";

contract DeployPriceConsumer is Script {
    function run() public {
        // Get deployer private key - in local anvil it would be one of the test accounts
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address blocksenseProxy = vm.envAddress("BLOCKSENSE_PROXY");

        vm.startBroadcast(deployerPrivateKey);

        BlocksensePriceConsumer consumer = new BlocksensePriceConsumer(blocksenseProxy);
        console2.log("PriceConsumer deployed at:", address(consumer));

        vm.stopBroadcast();
    }
}