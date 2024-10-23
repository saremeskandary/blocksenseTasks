#!/bin/bash

CONTACT=$(docker compose logs scdeploy  | grep 'UpgradeableProxy' | awk '{print $NF}')
echo "UpgradeableProxy contract address $CONTACT"

ANVIL_CONTAINER=$(docker ps | grep foundry | awk '{ print $1}')
echo "Anvil container id $ANVIL_CONTAINER"

BTC_FEED_ID="1f" # 31 feed id in HEX
echo "BTC Price from contarct"
docker exec -it $ANVIL_CONTAINER sh -c "cast call ${CONTACT} --data 0x800000${BTC_FEED_ID} --rpc-url http://127.0.0.1:8545 |  cut -c1-50 | cast to-dec" | awk '{print $1*1e-18}' && echo '' 

TEXT_FEED_ID="de" # 222 feed id in HEX
echo "Raw bytes from contarct"
docker exec -it $ANVIL_CONTAINER sh -c "cast call ${CONTACT} --data 0x800000${TEXT_FEED_ID} --rpc-url http://127.0.0.1:8545 |  cut -c1-50 " && echo '' 
echo "Text from contarct"
docker exec -it $ANVIL_CONTAINER sh -c "cast call ${CONTACT} --data 0x800000${TEXT_FEED_ID} --rpc-url http://127.0.0.1:8545 |  cut -c1-50 " |  xxd -r -p && echo '' 
