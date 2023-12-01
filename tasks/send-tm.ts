import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";
import { getPrivateKey, getProviderRpcUrl, getRouterConfig } from "./utils";
import {Wallet, providers, ethers} from "ethers";
import { IERC20, IERC20__factory, IRouterClient, IRouterClient__factory, PaymentEntrance, PaymentEntrance__factory, Portal, Portal__factory } from "../typechain-types";
import { Spinner } from "../utils/spinner";

task(`send-tm`, `Sends token and data using ProgrammableTokenTransfers.sol`)
    .addParam(`sourceBlockchain`, `The name of the source blockchain (for example ethereumSepolia)`)
    .addParam(`sender`, `The address of the sender ProgrammableTokenTransfers.sol on the source blockchain`)
    .addParam(`destinationBlockchain`, `The name of the destination blockchain (for example polygonMumbai)`)
    .addParam(`receiver`, `The address of the receiver ProgrammableTokenTransfers.sol on the destination blockchain`)
    // .addParam(`message`, `The string message to be sent (for example "Hello, World")`)
    .addParam(`tokenAddress`, `The address of a token to be sent on the source blockchain`)
    .addParam(`saoAmount`, `The amount of sao to be paid`)
    .addParam(`tokenAmount`, `The amount of token to be sent`)
    .addOptionalParam("router", `The address of the Router contract on the source blockchain`)
    .setAction(async (taskArguments: TaskArguments) => {
        const { sourceBlockchain, sender, destinationBlockchain, receiver,  tokenAddress, saoAmount, tokenAmount } = taskArguments;

        const privateKey = getPrivateKey();
        const sourceRpcProviderUrl = getProviderRpcUrl(sourceBlockchain);

        const sourceProvider = new providers.JsonRpcProvider(sourceRpcProviderUrl);
        const wallet = new Wallet(privateKey);
        const signer = wallet.connect(sourceProvider);
        const tokenContract: IERC20 = IERC20__factory.connect(tokenAddress,signer);
        const senderContract: PaymentEntrance = PaymentEntrance__factory.connect(sender, signer);

        const routerAddress = taskArguments.router ? taskArguments.router : getRouterConfig(sourceBlockchain).address;
        const destinationChainSelector = getRouterConfig(destinationBlockchain).chainSelector;

        const router: IRouterClient = IRouterClient__factory.connect(routerAddress, signer);
        const supportedTokens = await router.getSupportedTokens(destinationChainSelector);

        if (!supportedTokens.includes(tokenAddress)) {
            throw Error(`Token address ${tokenAddress} not in the list of supportedTokens ${supportedTokens}`);
        }

        const spinner: Spinner = new Spinner();

        console.log(`ℹ️  Attempting to call the sendMessage function of ProgrammableTokenTransfers smart contract on the ${sourceBlockchain} blockchain using ${signer.address} address`);
        spinner.start();

        await tokenContract.approve(sender,tokenAmount)
        const message: PaymentEntrance.DataStruct = {
                payee: "0x28Feee805791932240741A6324cbAcea89Ce1846",
                cid: "QmRLr57t5ZjJ2FGWkTcSsQMWwkjCLttDAmj7XYyvB3cVnw",
                dataId: "e46cf170-8eaf-11ee-aef2-03ab57ca4caa",
                timeout: 30000,
                saoAmount: saoAmount,
                tokenAmount: tokenAmount
        }
        console.log("estimateGas")
        const tx = await senderContract.sendMessage(
            destinationChainSelector,
            receiver,
            message,
            tokenAddress,
            {gasLimit: 5000000, gasPrice: ethers.utils.parseUnits('9.0', 'gwei')}
        );

        await tx.wait();
        console.log(tx)
        spinner.start();
        console.log(`✅ Message sent, transaction hash: ${tx.hash}`);
    })


task(`get-tm-details`, `Gets details of any CCIP message received by the ProgrammableTokenTransfers.sol smart contract`)
    .addParam(`contractAddress`, `The address of the ProgrammableTokenTransfers.sol smart contract`)
    .addParam(`blockchain`, `The name of the blockchain where the contract is (for example ethereumSepolia)`)
    .setAction(async (taskArguments: TaskArguments) => {
        const { contractAddress, blockchain } = taskArguments;

        const rpcProviderUrl = getProviderRpcUrl(blockchain);
        const provider = new providers.JsonRpcProvider(rpcProviderUrl);

        const receiverContract: Portal = Portal__factory.connect(contractAddress, provider);

        // console.log(await receiverContract.());
    })