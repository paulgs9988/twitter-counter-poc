const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);

    // Define Chainlink Functions Router address for Sepolia
    const ROUTER_ADDRESS = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0"; // Sepolia Functions Router

    // Deploy TwitterCounter first
    console.log("Deploying TwitterCounter...");
    const TwitterCounter = await hre.ethers.getContractFactory("TwitterCounter");
    const counter = await TwitterCounter.deploy(deployer.address);
    await counter.waitForDeployment();
    const counterAddress = await counter.getAddress();
    console.log("TwitterCounter deployed to:", counterAddress);

    // Deploy OracleSafe with Functions
    console.log("Deploying OracleSafe...");
    const OracleSafe = await hre.ethers.getContractFactory("OracleSafe");
    const oracleSafe = await OracleSafe.deploy(
        counterAddress,        // _counterContract
        BigInt(3821),         // _subscriptionId
        ROUTER_ADDRESS,       // _router
        {                     // deployment options
            gasLimit: 3000000
        }
    );
    await oracleSafe.waitForDeployment();
    const safeAddress = await oracleSafe.getAddress();
    console.log("OracleSafe deployed to:", safeAddress);

    // Update TwitterCounter's safe address
    console.log("Updating TwitterCounter's safe address...");
    const counterContract = TwitterCounter.attach(counterAddress);
    await counterContract.updateSafeAddress(safeAddress);
    // For tutorial:
    console.log("Contracts deployed successfully");
    console.log("\nNext steps:");
    console.log("1. Go to https://functions.chain.link/sepolia");
    console.log("2. Click on subscription ID 3821");
    console.log(`3. Add your OracleSafe contract (${safeAddress}) as a consumer`);
    console.log("4. Send some Sepolia ETH to the OracleSafe contract");
    console.log("5. Set a tweet ID to monitor using setTweetToMonitor()");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });