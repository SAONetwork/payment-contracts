import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";
import { getPrivateKey, getProviderRpcUrl, getRouterConfig } from "./utils";
import { Wallet, providers } from "ethers";
import { PayeeX , PayeeX__factory } from "../typechain-types";
import { Spinner } from "../utils/spinner";

task(`deploy-payeex`, `Deploys the payeeX smart contract`)
    .addOptionalParam(`router`, `The address of the Router contract`)
    .addOptionalParam(`portal`, `The address of the Portal contract`)
    .addOptionalParam(`token`, `The address of the Token contract`)
    .addOptionalParam(`payee`, `The address of the Payee contract`)
    .setAction(async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
        const routerAddress = taskArguments.router ? taskArguments.router : getRouterConfig(hre.network.name).address;
        const portalAddress = taskArguments.portal ? taskArguments.portal : getRouterConfig(hre.network.name).address;
        const tokenAddress = taskArguments.token ? taskArguments.token : getRouterConfig(hre.network.name).address;
        const payeeAddress = taskArguments.payee? taskArguments.payee: getRouterConfig(hre.network.name).address;

        const privateKey = getPrivateKey();
        const rpcProviderUrl = getProviderRpcUrl(hre.network.name);

        const provider = new providers.JsonRpcProvider(rpcProviderUrl);
        const wallet = new Wallet(privateKey);
        const deployer = wallet.connect(provider);

        const spinner: Spinner = new Spinner();

        console.log(`ℹ️  Attempting to deploy payeeX on the ${hre.network.name} blockchain using ${deployer.address} address, with the Router address ${routerAddress} provided as constructor argument`);
        spinner.start();

        const payeeXFactory: PayeeX__factory = await hre.ethers.getContractFactory('PayeeX');
        const payeeX: PayeeX = await payeeXFactory.deploy(routerAddress, tokenAddress, portalAddress, payeeAddress, getRouterConfig(hre.network.name).feeTokens[0]);
        await payeeX.deployed();

        spinner.stop();
        console.log(`✅ PaymentEntrance deployed at address ${payeeX.address} on ${hre.network.name} blockchain`)
    });
