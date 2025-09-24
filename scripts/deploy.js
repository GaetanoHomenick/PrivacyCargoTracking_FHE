const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  console.log("Deploying Privacy Cargo Tracking contract with FHE...");
  console.log("Network:", hre.network.name);
  console.log("Using @fhevm/solidity library with SepoliaConfig");

  // Get the ContractFactory and Signers here.
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the final working FHE contract
  const contractName = "PrivacyCargoTracking"; // Will deploy PrivacyCargoTracking_Final.sol
  const PrivacyCargoTracking = await hre.ethers.getContractFactory(contractName);

  console.log(`Deploying ${contractName} with FHE support...`);

  // Deploy with gas estimation
  const estimatedGas = await hre.ethers.provider.estimateGas(
    PrivacyCargoTracking.getDeployTransaction()
  );
  console.log("Estimated gas:", estimatedGas.toString());

  const privacyCargoTracking = await PrivacyCargoTracking.deploy({
    gasLimit: estimatedGas.mul(120).div(100), // 20% buffer
  });

  await privacyCargoTracking.deployed();

  console.log("✅ PrivacyCargoTracking deployed to:", privacyCargoTracking.address);
  console.log("Transaction hash:", privacyCargoTracking.deployTransaction.hash);
  console.log("Gas used:", (await privacyCargoTracking.deployTransaction.wait()).gasUsed.toString());

  // Wait for a few block confirmations
  console.log("Waiting for block confirmations...");
  await privacyCargoTracking.deployTransaction.wait(5);

  console.log("✅ Deployment completed!");
  console.log("📋 Contract Details:");
  console.log("  - Address:", privacyCargoTracking.address);
  console.log("  - Network:", hre.network.name);
  console.log("  - FHE Support: ✅ Enabled");
  console.log("  - FHEVM Library: @fhevm/solidity ^0.7.0");
  console.log("");
  console.log("🔧 Next Steps:");
  console.log("1. Update CONTRACT_ADDRESS in index.html with:", privacyCargoTracking.address);
  console.log("2. Test FHE functionality:");
  console.log("   - Connect MetaMask to Sepolia");
  console.log("   - Create encrypted cargo shipments");
  console.log("   - Test privacy controls");

  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    contractAddress: privacyCargoTracking.address,
    transactionHash: privacyCargoTracking.deployTransaction.hash,
    deployedAt: new Date().toISOString(),
    contractName: contractName,
    fheLibrary: "@fhevm/solidity ^0.7.0",
    features: [
      "FHE Encryption (priority, fragile, value)",
      "Permission Management (FHE.allow)",
      "SepoliaConfig Integration",
      "MetaMask Transaction Flow"
    ]
  };

  console.log("");
  console.log("📄 Deployment Info:", JSON.stringify(deploymentInfo, null, 2));

  // Verify contract on Etherscan (if on testnet/mainnet)
  if (hre.network.name !== "localhost" && hre.network.name !== "hardhat") {
    console.log("⏳ Waiting before verification...");
    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait 30 seconds

    try {
      await hre.run("verify:verify", {
        address: privacyCargoTracking.address,
        constructorArguments: [],
      });
      console.log("✅ Contract verified on Etherscan");
    } catch (error) {
      console.log("❌ Verification failed:", error.message);
      console.log("You can verify manually later with:");
      console.log(`npx hardhat verify --network ${hre.network.name} ${privacyCargoTracking.address}`);
    }
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });