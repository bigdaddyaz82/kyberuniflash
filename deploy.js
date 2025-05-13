async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    
    const FlashArbitrage = await ethers.getContractFactory("FlashArbitrage");
    const flashArb = await FlashArbitrage.deploy("<address_provider>");
    console.log("FlashArbitrage deployed to:", flashArb.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
