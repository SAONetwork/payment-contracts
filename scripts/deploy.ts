import { ethers } from "hardhat";

async function main() {


  const Portal = await ethers.getContractFactory("Portal");
  const Payee = await ethers.getContractFactory("Payee");

  const portal = await Portal.deploy();
  //const portal = await Portal.attach("0xFa1ABF81BA705358b417656C7564E8dF54528006")
  console.log(portal.address)

  await portal.createPayee()
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
