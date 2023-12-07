import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";
import { getPrivateKey, getProviderRpcUrl, getRouterConfig } from "./utils";
import {Wallet, providers, ethers} from "ethers";
import { IERC20, IERC20__factory, IRouterClient, IRouterClient__factory, PayeeX, PayeeX__factory, Portal, Portal__factory } from "../typechain-types";
import { Spinner } from "../utils/spinner";

task(`send-tm`, `send cross-chain create payemnt`)
    .addParam(`sender`, `The address of the sender ProgrammableTokenTransfers.sol on the source blockchain`)
    .addParam(`token`, `The address of a token to be sent on the source blockchain`)
    .addParam(`sao`, `The amount of sao to be paid`)
    .addParam(`amount`, `The amount of token to be sent`)
    .setAction(async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
        const { sender, receiver,  token, sao, amount} = taskArguments;

        const privateKey = getPrivateKey();
        const sourceRpcProviderUrl = getProviderRpcUrl(hre.network.name);

        const sourceProvider = new providers.JsonRpcProvider(sourceRpcProviderUrl);
        const wallet = new Wallet(privateKey);
        const signer = wallet.connect(sourceProvider);
        const tokenContract: IERC20 = IERC20__factory.connect(token,signer);
        const senderContract: PayeeX = PayeeX__factory.connect(sender, signer);

        const spinner: Spinner = new Spinner();

        console.log(`ℹ️  Attempting to call the sendMessage function of ProgrammableTokenTransfers smart contract on the ${hre.network.name} blockchain using ${signer.address} address`);
        spinner.start();

        await tokenContract.approve(sender,amount)
        console.log("estimateGas")
        const tx = await senderContract.createPayment( "QmRLr57t5ZjJ2FGWkTcSsQMWwkjCLttDAmj7XYyvB3cVnw", "e46cf170-8eaf-11ee-aef2-03ab57ca4caa", sao, 30000, amount, {gasLimit: 1000000});

        await tx.wait();
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
