async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const LazyMinting = await ethers.getContractFactory("LazyMinting");
  const lazyMinting = await LazyMinting.deploy();
  console.log("LazyMinting contract address:-", lazyMinting.address);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });