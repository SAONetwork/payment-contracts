# SAO Network multi-chain payment contract

SAO Network introduced a new role, Payment Gateway, to help users to use any EVM-based chain’s native tokens to pay for the storage services. For example, on the Polygon chain, users can pay MATIC to use SAO Network storage service, and the Payee contract will receive MATIC and generate storage payment events. Then SAO Payment Gateway will send the storage request to the network.


Get PORTAL CONTRACT address, Portal contract is Chainlink CCIP Receiver to receive cross chain message from CCIP Sender
```shell
npx hardhat deploy-portal —network polygonMumbai  
```




Get PAYEE CONTRACT address, Payee contract integrate Chainlink PriceFeed to verify payment amount and use Chainlink Functions to query data status on SAO consensus layer

0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C is the Chainlink Functions router on polygonMumbai network
```shell
npx hardhat deploy-payee --portal <PORTAL CONTRACT> --router 0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C  --network polygonMumbai 
```


Get PAYEEX CONTRACT address, PayeeX contract is CCIP Sender to accept payment request and send cross chain message to portal contract

0x79fd262B2773966b4a42e7d2040db168Ab43ce49 is the wrapped native token of payee contract chain
```shell
npx npx hardhat deploy-payeex --token 0x79fd262B2773966b4a42e7d2040db168Ab43ce49 --portal <PORTAL CONTRACT> --payee <PAYEE CONTRACT> —network bnbTestnet
```







