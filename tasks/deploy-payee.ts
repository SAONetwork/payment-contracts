import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";
import { getPrivateKey, getProviderRpcUrl, getRouterConfig } from "./utils";
import { Wallet, providers } from "ethers";
import {
        Payee,
        Payee__factory, Portal, Portal__factory,
} from "../typechain-types";
import { Spinner } from "../utils/spinner";

task(`deploy-payee`, `Deploys the Payee smart contract`)
    .addOptionalParam(`router`, `The address of the Router contract`)
    .addParam(`portal`, `The address of the contract Portal.sol on the source blockchain`)
    .setAction(async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
        const routerAddress = taskArguments.router ? taskArguments.router : getRouterConfig(hre.network.name).address;

        const privateKey = getPrivateKey();
        const rpcProviderUrl = getProviderRpcUrl(hre.network.name);

        const provider = new providers.JsonRpcProvider(rpcProviderUrl);
        const wallet = new Wallet(privateKey);
        const deployer = wallet.connect(provider);

        const portalContract: Portal = Portal__factory.connect(taskArguments.portal, deployer);

        const spinner: Spinner = new Spinner();

        console.log(`ℹ️  Attempting to deploy Payee on the ${hre.network.name} blockchain using ${deployer.address} address, with the Router address ${routerAddress} provided as constructor argument, by Portal contract ${portalContract.address}`);
        spinner.start();

        const tx = await portalContract.createPayee()

        console.log(tx)

        spinner.stop();
        console.log(`✅ Payee deployed at address ${tx.data} on ${hre.network.name} blockchain`)
    });
task(`create-proposal`, `Deploys the Portal smart contract`)
    .addOptionalParam(`router`, `The address of the Router contract`)
    // .addParam(`portal`, `The address of the contract Portal.sol on the source blockchain`)
    .setAction(async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
            const routerAddress = taskArguments.router ? taskArguments.router : getRouterConfig(hre.network.name).address;

            const privateKey = getPrivateKey();
            const rpcProviderUrl = getProviderRpcUrl(hre.network.name);

            const provider = new providers.JsonRpcProvider(rpcProviderUrl);
            const wallet = new Wallet(privateKey);
            const deployer = wallet.connect(provider);

            const payee: Payee = Payee__factory.connect("0xd31a8581A9f03c1B076Ce241895c1a2e3ee15eFC", deployer);
            const spinner: Spinner = new Spinner();

            console.log(`ℹ️  Attempting to deploy Portal on the ${hre.network.name} blockchain using ${deployer.address} address, with the Router address ${routerAddress} provided as constructor argument`);
            spinner.start();

            // const payeeFactory: Payee__factory = await hre.ethers.getContractFactory('Payee');
            const tx = await payee.createPayment("QmRLr57t5ZjJ2FGWkTcSsQMWwkjCLttDAmj7XYyvB3cVnw","e46cf170-8eaf-11ee-aef2-03ab57ca4caa",1,30000,90000000);

            console.log(tx)
            spinner.stop();
            console.log(`✅ Portal deployed at address ${payee.address} on ${hre.network.name} blockchain`)
    });