import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Payee", function () {

  async function deployPortal() {

    const [owner, payee] = await ethers.getSigners();

    const Portal = await ethers.getContractFactory("Portal");
    const Payee = await ethers.getContractFactory("Payee");
    const portal = await Portal.deploy();

    return { portal, payee, Payee };
  }

  describe("CreatePayee", function () {
    describe("Payee", function () {
      it("Should create payee success", async function () {
        const { portal, payee, Payee } = await loadFixture(deployPortal);

        //const ad = await expect(portal.connect(payee).createPayee())
        const ad = await portal.connect(payee).createPayee()

        const payeeA = await portal.getPayee(payee.address)

        const payeeC = Payee.attach(payeeA)

        console.log(await payeeC.paymentId())
         //.to.emit(portal, "PayeeCreated")
         //.withArgs(payee.address, "0xdeF226f18bF28c1Ecb9a7EAfF9e33A574d04b746"); 

      });

    });

  });
});
