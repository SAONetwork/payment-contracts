import { task } from "hardhat/config";
import fs  from "fs";

import { getPrivateKey, getProviderRpcUrl, getRouterConfig } from "./utils";
import { Wallet, providers } from "ethers";

task("confirm", "tet")
    .setAction(async (taskArgs, hre) =>{
        const overrides = {
          gasLimit: taskArgs.requestgas,
        }
        const privateKey = getPrivateKey();
        const rpcProviderUrl = getProviderRpcUrl(hre.network.name);

        const provider = new providers.JsonRpcProvider(rpcProviderUrl);
        const wallet = new Wallet(privateKey);
        const deployer = wallet.connect(provider);
        const Payee = await ethers.getContractFactory("Payee");

        const payee = await Payee.attach("0x5bdf68745cc13f4df46df4560ff7cb6e6f9b777b")

        const source = fs.readFileSync("./order.js").toString()
        //const source = fs.readFileSync("./calc.js").toString()
        const donIdBytes32 = hre.ethers.utils.formatBytes32String("fun-polygon-mumbai-1")
        const donId = "0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000"

        /*
        let tx = await payee.confirmPayment(
            source,
            ["8c29aa70-8f5f-11ee-8d2b-240f9aae9640"],
            1048,
            250000,
            donIdBytes32
        )
        await tx.wait()
        */

        const reqId = await payee.s_lastRequestId()
        const resp = await payee.s_lastResponse()
        const error = await payee.s_lastError()

        console.log(reqId, resp, error)

    })
