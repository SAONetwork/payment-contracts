import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";
import { getPrivateKey, getProviderRpcUrl, getRouterConfig } from "./utils";
import { Wallet, providers } from "ethers";
import {
        WMATIC,
        WMATIC__factory
} from "../typechain-types";
import { Spinner } from "../utils/spinner";

task(`deploy-erc20`, `Deploys the ERC20 smart contract`)
    .setAction(async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {

        const privateKey = getPrivateKey();
        const rpcProviderUrl = getProviderRpcUrl(hre.network.name);

        const provider = new providers.JsonRpcProvider(rpcProviderUrl);
        const wallet = new Wallet(privateKey);
        const deployer = wallet.connect(provider);

        const wmaticFactory: WMATIC__factory = await hre.ethers.getContractFactory('WMATIC');
        const wmatic: WMATIC= await wmaticFactory.deploy();
        await wmatic.deployed();

        const spinner: Spinner = new Spinner();
        spinner.start();

        console.log(`ℹ️  Attempting to deploy WMATIC on the ${hre.network.name} blockchain using ${deployer.address} address`)

        spinner.stop();
        console.log(`✅ WMATIC deployed at address ${wmatic.address} on ${hre.network.name} blockchain`)
    });

