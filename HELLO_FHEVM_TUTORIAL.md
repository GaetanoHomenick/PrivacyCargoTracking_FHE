# Hello FHEVM: Building Your First Confidential Application

<div align="center">

![Hello FHEVM](https://img.shields.io/badge/Hello_FHEVM-Beginner%20Tutorial-brightgreen?style=for-the-badge&logo=ethereum)

**A Complete Step-by-Step Guide to Building Confidential Smart Contracts**

[![Difficulty](https://img.shields.io/badge/Difficulty-Beginner-green?style=for-the-badge)](https://github.com)
[![Duration](https://img.shields.io/badge/Duration-2%20Hours-blue?style=for-the-badge)](https://github.com)
[![FHEVM](https://img.shields.io/badge/Technology-FHEVM-gold?style=for-the-badge)](https://docs.zama.ai/fhevm)

</div>

## 🎯 What You'll Build

By the end of this tutorial, you'll have created a **Privacy Cargo Tracking System** - a fully functional confidential application that demonstrates the power of Fully Homomorphic Encryption (FHE) on the blockchain. This application allows users to:

- Create cargo shipments with **encrypted details**
- Track location updates while keeping **coordinates private**
- Manage **confidential access permissions**
- Maintain **complete privacy** throughout the shipping process

### 🔗 **Live Demo**
See the final result: [Privacy Cargo Tracking Demo](https://privacy-cargo-tracking-fhe.vercel.app/)

## 🎓 Learning Objectives

After completing this tutorial, you will:

✅ **Understand FHEVM Basics**: Learn what Fully Homomorphic Encryption brings to smart contracts
✅ **Write Confidential Contracts**: Create smart contracts that operate on encrypted data
✅ **Handle Encrypted Inputs**: Process user inputs while keeping them private
✅ **Manage Access Control**: Implement privacy-preserving permission systems
✅ **Build a Frontend**: Connect your confidential smart contract to a web interface
✅ **Deploy to Testnet**: Launch your application on a live blockchain network

## 📋 Prerequisites

### **Required Knowledge**
- **Solidity Basics**: You can write and deploy simple smart contracts
- **JavaScript Fundamentals**: Basic understanding of modern JavaScript/TypeScript
- **Web3 Familiarity**: Experience with MetaMask and blockchain interactions
- **Development Tools**: Comfortable with command line and package managers

### **What You DON'T Need**
- ❌ **No FHE Background Required**: Zero cryptography or advanced math knowledge needed
- ❌ **No FHEVM Experience**: This tutorial assumes you're completely new to FHEVM
- ❌ **No Complex Setup**: We'll use simple, well-documented tools

### **Required Tools**
- **Node.js 18+** - [Download here](https://nodejs.org/)
- **MetaMask** - [Install extension](https://metamask.io/)
- **Code Editor** - VS Code, Sublime, or your preference
- **Git** - For cloning repositories

## 🚀 Tutorial Overview

This tutorial is structured in **6 progressive chapters**:

1. **[Understanding FHEVM](#chapter-1-understanding-fhevm)** - Core concepts and setup
2. **[Smart Contract Development](#chapter-2-smart-contract-development)** - Writing confidential contracts
3. **[Frontend Integration](#chapter-3-frontend-integration)** - Building the user interface
4. **[Privacy Features](#chapter-4-privacy-features)** - Implementing confidential operations
5. **[Testing & Deployment](#chapter-5-testing--deployment)** - Testing and going live
6. **[Advanced Concepts](#chapter-6-advanced-concepts)** - Taking it further

---

## Chapter 1: Understanding FHEVM

### 🔍 What is FHEVM?

**Fully Homomorphic Encryption Virtual Machine (FHEVM)** enables smart contracts to perform computations on encrypted data without ever decrypting it. Think of it as a "privacy layer" for your smart contracts.

### 🔐 Key Concepts

#### **Traditional Smart Contracts**
```solidity
// ❌ Everyone can see this data
uint256 public cargoValue = 1000; // Visible to all
address public receiver = 0x123...; // Public information
```

#### **FHEVM Smart Contracts**
```solidity
// ✅ Data remains encrypted
euint32 private encryptedCargoValue; // Hidden from everyone
euint256 private encryptedReceiver; // Confidential information
```

### 📚 FHEVM Data Types

FHEVM introduces encrypted data types that work just like regular types:

| Regular Type | FHEVM Type | Description |
|--------------|------------|-------------|
| `uint8` | `euint8` | Encrypted 8-bit integer |
| `uint32` | `euint32` | Encrypted 32-bit integer |
| `address` | `eaddress` | Encrypted address |
| `bool` | `ebool` | Encrypted boolean |

### 🛠 Setting Up Your Environment

#### **1. Clone the Tutorial Repository**
```bash
git clone https://github.com/GaetanoHomenick/PrivacyCargoTracking_FHE.git
cd PrivacyCargoTracking_FHE
```

#### **2. Install Dependencies**
```bash
npm install
```

#### **3. Environment Configuration**
Create a `.env` file:
```bash
# .env
PRIVATE_KEY="your_private_key_here"
INFURA_API_KEY="your_infura_key_here"
```

#### **4. Verify Setup**
```bash
npm run compile
```

If everything is set up correctly, you should see:
```
✅ Smart contracts compiled successfully
```

---

## Chapter 2: Smart Contract Development

### 📝 Creating Your First Confidential Contract

Let's build the core smart contract that will handle encrypted cargo tracking.

#### **2.1 Basic Contract Structure**

Create `contracts/PrivateCargoTracking.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@fhevmjs/contracts/FHEVM.sol";

contract PrivateCargoTracking {
    using FHEVM for euint32;
    using FHEVM for eaddress;

    // Encrypted cargo data structure
    struct Cargo {
        euint32 weight;          // Hidden weight
        euint32 value;           // Hidden value
        eaddress receiver;       // Hidden receiver
        euint32 status;          // Hidden status
        address shipper;         // Public shipper (for basic access control)
        uint256 timestamp;       // Public creation time
    }

    // Storage
    mapping(uint32 => Cargo) private cargos;
    uint32 public nextCargoId = 1;

    // Events (only emit non-sensitive data)
    event CargoCreated(uint32 indexed cargoId, address indexed shipper);
    event CargoUpdated(uint32 indexed cargoId, address indexed updater);
}
```

#### **2.2 Creating Encrypted Cargo**

Add the cargo creation function:

```solidity
/**
 * @dev Creates a new cargo with encrypted details
 * @param _encryptedWeight Encrypted weight input
 * @param _encryptedValue Encrypted value input
 * @param _encryptedReceiver Encrypted receiver address
 */
function createCargo(
    einput _encryptedWeight,
    einput _encryptedValue,
    einput _encryptedReceiver
) external returns (uint32) {
    // Convert encrypted inputs to FHEVM types
    euint32 weight = FHEVM.asEuint32(_encryptedWeight);
    euint32 value = FHEVM.asEuint32(_encryptedValue);
    eaddress receiver = FHEVM.asEaddress(_encryptedReceiver);

    // Create cargo with encrypted data
    cargos[nextCargoId] = Cargo({
        weight: weight,
        value: value,
        receiver: receiver,
        status: FHEVM.asEuint32(0), // 0 = Created
        shipper: msg.sender,
        timestamp: block.timestamp
    });

    // Grant access permissions
    FHEVM.allow(weight, msg.sender);
    FHEVM.allow(value, msg.sender);
    FHEVM.allow(receiver, msg.sender);

    emit CargoCreated(nextCargoId, msg.sender);

    return nextCargoId++;
}
```

#### **2.3 Encrypted Location Updates**

Add location tracking functionality:

```solidity
// Location data structure
struct Location {
    euint32 latitude;    // Encrypted GPS coordinate
    euint32 longitude;   // Encrypted GPS coordinate
    euint32 status;      // Encrypted status
    uint256 timestamp;   // Public timestamp
}

// Storage for locations
mapping(uint32 => Location[]) private cargoLocations;

/**
 * @dev Updates cargo location with encrypted coordinates
 */
function updateLocation(
    uint32 _cargoId,
    einput _encryptedLat,
    einput _encryptedLng,
    einput _encryptedStatus
) external {
    require(_cargoId < nextCargoId, "Invalid cargo ID");

    // Convert inputs to encrypted types
    euint32 lat = FHEVM.asEuint32(_encryptedLat);
    euint32 lng = FHEVM.asEuint32(_encryptedLng);
    euint32 status = FHEVM.asEuint32(_encryptedStatus);

    // Add new location entry
    cargoLocations[_cargoId].push(Location({
        latitude: lat,
        longitude: lng,
        status: status,
        timestamp: block.timestamp
    }));

    // Update cargo status
    cargos[_cargoId].status = status;

    // Grant access to the updater
    FHEVM.allow(lat, msg.sender);
    FHEVM.allow(lng, msg.sender);
    FHEVM.allow(status, msg.sender);

    emit CargoUpdated(_cargoId, msg.sender);
}
```

#### **2.4 Access Control System**

Implement privacy-preserving access control:

```solidity
// Access permissions
mapping(uint32 => mapping(address => bool)) public cargoAccess;

/**
 * @dev Grants access to encrypted cargo data
 */
function grantAccess(uint32 _cargoId, address _authorized) external {
    require(cargos[_cargoId].shipper == msg.sender, "Only shipper can grant access");

    // Grant access to encrypted fields
    FHEVM.allow(cargos[_cargoId].weight, _authorized);
    FHEVM.allow(cargos[_cargoId].value, _authorized);
    FHEVM.allow(cargos[_cargoId].receiver, _authorized);
    FHEVM.allow(cargos[_cargoId].status, _authorized);

    // Grant access to location data
    for(uint i = 0; i < cargoLocations[_cargoId].length; i++) {
        FHEVM.allow(cargoLocations[_cargoId][i].latitude, _authorized);
        FHEVM.allow(cargoLocations[_cargoId][i].longitude, _authorized);
        FHEVM.allow(cargoLocations[_cargoId][i].status, _authorized);
    }

    cargoAccess[_cargoId][_authorized] = true;
}

/**
 * @dev Checks if address has access to cargo data
 */
function hasAccess(uint32 _cargoId, address _user) external view returns (bool) {
    return cargos[_cargoId].shipper == _user || cargoAccess[_cargoId][_user];
}
```

### 🧪 Testing Your Contract

Create `test/PrivateCargoTracking.test.js`:

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PrivateCargoTracking", function () {
    let contract;
    let owner;
    let receiver;

    beforeEach(async function () {
        [owner, receiver] = await ethers.getSigners();

        const PrivateCargoTracking = await ethers.getContractFactory("PrivateCargoTracking");
        contract = await PrivateCargoTracking.deploy();
        await contract.deployed();
    });

    it("Should create cargo with encrypted data", async function () {
        // This is a simplified test - in real FHEVM testing,
        // you would use encrypted inputs
        const tx = await contract.createCargo(
            1000, // weight (this would be encrypted)
            5000, // value (this would be encrypted)
            receiver.address // receiver (this would be encrypted)
        );

        const receipt = await tx.wait();
        const event = receipt.events?.find(e => e.event === 'CargoCreated');

        expect(event).to.not.be.undefined;
        expect(event.args.cargoId).to.equal(1);
        expect(event.args.shipper).to.equal(owner.address);
    });
});
```

Run your tests:
```bash
npm run test
```

---

## Chapter 3: Frontend Integration

### 🌐 Building the User Interface

Now let's create a frontend that interacts with our confidential smart contract.

#### **3.1 Project Structure**

```
frontend/
├── src/
│   ├── components/
│   │   ├── CargoForm.js
│   │   ├── CargoList.js
│   │   └── LocationTracker.js
│   ├── utils/
│   │   ├── contract.js
│   │   └── fhevm.js
│   ├── App.js
│   └── index.js
├── public/
└── package.json
```

#### **3.2 FHEVM Frontend Setup**

Install required dependencies:
```bash
cd frontend
npm install ethers fhevmjs react react-dom
```

Create `src/utils/fhevm.js`:
```javascript
import { createInstance } from 'fhevmjs';

let fhevmInstance = null;

export const initFHEVM = async () => {
    if (!fhevmInstance) {
        fhevmInstance = await createInstance({
            chainId: 11155111, // Sepolia
            gatewayUrl: "https://gateway.sepolia.fhevm.org"
        });
    }
    return fhevmInstance;
};

export const encryptData = async (value, type = 'uint32') => {
    const fhevm = await initFHEVM();
    return fhevm.encrypt(type, value);
};

export const getFHEVM = () => fhevmInstance;
```

#### **3.3 Contract Integration**

Create `src/utils/contract.js`:
```javascript
import { ethers } from 'ethers';
import { initFHEVM, encryptData } from './fhevm';

const CONTRACT_ADDRESS = "YOUR_DEPLOYED_CONTRACT_ADDRESS";
const CONTRACT_ABI = [
    // Add your contract ABI here
    "function createCargo(bytes calldata, bytes calldata, bytes calldata) external returns (uint32)",
    "function updateLocation(uint32, bytes calldata, bytes calldata, bytes calldata) external",
    "function grantAccess(uint32, address) external",
    "event CargoCreated(uint32 indexed cargoId, address indexed shipper)"
];

export class ContractService {
    constructor() {
        this.provider = null;
        this.signer = null;
        this.contract = null;
    }

    async connect() {
        if (window.ethereum) {
            this.provider = new ethers.providers.Web3Provider(window.ethereum);
            this.signer = this.provider.getSigner();
            this.contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, this.signer);

            await initFHEVM();
            return true;
        }
        return false;
    }

    async createCargo(weight, value, receiverAddress) {
        try {
            // Encrypt the data
            const encryptedWeight = await encryptData(weight);
            const encryptedValue = await encryptData(value);
            const encryptedReceiver = await encryptData(receiverAddress, 'address');

            // Send transaction
            const tx = await this.contract.createCargo(
                encryptedWeight,
                encryptedValue,
                encryptedReceiver
            );

            const receipt = await tx.wait();
            return receipt;
        } catch (error) {
            console.error('Error creating cargo:', error);
            throw error;
        }
    }

    async updateLocation(cargoId, latitude, longitude, status) {
        try {
            const encryptedLat = await encryptData(Math.floor(latitude * 1000000));
            const encryptedLng = await encryptData(Math.floor(longitude * 1000000));
            const encryptedStatus = await encryptData(status);

            const tx = await this.contract.updateLocation(
                cargoId,
                encryptedLat,
                encryptedLng,
                encryptedStatus
            );

            return await tx.wait();
        } catch (error) {
            console.error('Error updating location:', error);
            throw error;
        }
    }
}
```

#### **3.4 React Components**

Create `src/components/CargoForm.js`:
```javascript
import React, { useState } from 'react';
import { ContractService } from '../utils/contract';

const CargoForm = ({ onCargoCreated }) => {
    const [formData, setFormData] = useState({
        weight: '',
        value: '',
        receiver: ''
    });
    const [loading, setLoading] = useState(false);
    const [contract] = useState(new ContractService());

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            await contract.connect();
            const receipt = await contract.createCargo(
                parseInt(formData.weight),
                parseFloat(formData.value),
                formData.receiver
            );

            console.log('Cargo created:', receipt);
            onCargoCreated && onCargoCreated(receipt);

            // Clear form
            setFormData({ weight: '', value: '', receiver: '' });
        } catch (error) {
            alert('Error creating cargo: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="cargo-form">
            <h2>🔒 Create Confidential Cargo</h2>
            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label>Weight (kg):</label>
                    <input
                        type="number"
                        value={formData.weight}
                        onChange={(e) => setFormData({...formData, weight: e.target.value})}
                        required
                        min="1"
                        max="10000"
                    />
                </div>

                <div className="form-group">
                    <label>Value (ETH):</label>
                    <input
                        type="number"
                        step="0.001"
                        value={formData.value}
                        onChange={(e) => setFormData({...formData, value: e.target.value})}
                        required
                        min="0"
                    />
                </div>

                <div className="form-group">
                    <label>Receiver Address:</label>
                    <input
                        type="text"
                        value={formData.receiver}
                        onChange={(e) => setFormData({...formData, receiver: e.target.value})}
                        placeholder="0x..."
                        required
                    />
                </div>

                <button type="submit" disabled={loading}>
                    {loading ? '🔄 Creating Encrypted Cargo...' : '🚚 Create Cargo'}
                </button>
            </form>

            <div className="privacy-notice">
                <p>🔐 <strong>Privacy Notice:</strong> All cargo details will be encrypted on-chain. Only authorized parties can view this information.</p>
            </div>
        </div>
    );
};

export default CargoForm;
```

#### **3.5 Main Application**

Create `src/App.js`:
```javascript
import React, { useState, useEffect } from 'react';
import CargoForm from './components/CargoForm';
import './App.css';

function App() {
    const [account, setAccount] = useState('');
    const [connected, setConnected] = useState(false);

    const connectWallet = async () => {
        if (window.ethereum) {
            try {
                const accounts = await window.ethereum.request({
                    method: 'eth_requestAccounts'
                });

                setAccount(accounts[0]);
                setConnected(true);

                // Switch to Sepolia
                await window.ethereum.request({
                    method: 'wallet_switchEthereumChain',
                    params: [{ chainId: '0xaa36a7' }]
                });

            } catch (error) {
                console.error('Connection failed:', error);
            }
        } else {
            alert('Please install MetaMask!');
        }
    };

    const handleCargoCreated = (receipt) => {
        alert('✅ Cargo created successfully with encrypted data!');
    };

    return (
        <div className="App">
            <header className="App-header">
                <h1>🔐 Privacy Cargo Tracking</h1>
                <p>Confidential logistics powered by FHEVM</p>

                {!connected ? (
                    <button onClick={connectWallet} className="connect-btn">
                        Connect Wallet
                    </button>
                ) : (
                    <div className="wallet-info">
                        <span>Connected: {account.slice(0, 6)}...{account.slice(-4)}</span>
                    </div>
                )}
            </header>

            {connected && (
                <main className="App-main">
                    <CargoForm onCargoCreated={handleCargoCreated} />
                </main>
            )}
        </div>
    );
}

export default App;
```

---

## Chapter 4: Privacy Features

### 🔐 Understanding FHEVM Privacy

Let's dive deeper into the privacy features that make FHEVM special.

#### **4.1 Encryption Types and Operations**

FHEVM supports various operations on encrypted data:

```solidity
// Arithmetic operations
euint32 a = FHEVM.asEuint32(10);
euint32 b = FHEVM.asEuint32(20);
euint32 sum = FHEVM.add(a, b);        // Encrypted addition
euint32 diff = FHEVM.sub(a, b);       // Encrypted subtraction
euint32 product = FHEVM.mul(a, b);    // Encrypted multiplication

// Comparison operations
ebool isGreater = FHEVM.gt(a, b);     // Encrypted greater than
ebool isEqual = FHEVM.eq(a, b);       // Encrypted equality

// Selection operations
euint32 max = FHEVM.cmux(isGreater, a, b); // Conditional selection
```

#### **4.2 Advanced Privacy Patterns**

**Confidential Auctions:**
```solidity
contract PrivateAuction {
    euint32 private highestBid;
    eaddress private highestBidder;

    function bid(einput _encryptedBid) external {
        euint32 bidAmount = FHEVM.asEuint32(_encryptedBid);

        // Compare bids without revealing amounts
        ebool isHigher = FHEVM.gt(bidAmount, highestBid);

        // Update highest bid if current bid is higher
        highestBid = FHEVM.cmux(isHigher, bidAmount, highestBid);

        // Update highest bidder
        eaddress newBidder = FHEVM.asEaddress(msg.sender);
        highestBidder = FHEVM.cmux(isHigher, newBidder, highestBidder);
    }
}
```

**Privacy-Preserving Voting:**
```solidity
contract PrivateVoting {
    mapping(uint32 => euint32) private voteCounts;
    mapping(address => ebool) private hasVoted;

    function vote(uint32 _candidate, einput _encryptedVote) external {
        // Ensure user hasn't voted
        require(!FHEVM.decrypt(hasVoted[msg.sender]), "Already voted");

        // Add encrypted vote to candidate's total
        euint32 vote = FHEVM.asEuint32(_encryptedVote);
        voteCounts[_candidate] = FHEVM.add(voteCounts[_candidate], vote);

        // Mark as voted
        hasVoted[msg.sender] = FHEVM.asEbool(true);
    }
}
```

#### **4.3 Access Control Best Practices**

```solidity
contract AccessControlExample {
    // Multi-level access control
    mapping(address => uint8) public accessLevels;

    modifier requireAccess(uint8 _minLevel) {
        require(accessLevels[msg.sender] >= _minLevel, "Insufficient access");
        _;
    }

    function sensitiveOperation(einput _data)
        external
        requireAccess(2) // Require level 2 access
    {
        euint32 secretData = FHEVM.asEuint32(_data);

        // Only grant access to high-level users
        if (accessLevels[msg.sender] >= 3) {
            FHEVM.allow(secretData, msg.sender);
        }
    }
}
```

---

## Chapter 5: Testing & Deployment

### 🧪 Comprehensive Testing

#### **5.1 Local Testing Setup**

Create a complete test suite:

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PrivateCargoTracking - Complete Test Suite", function () {
    let contract;
    let owner, shipper, receiver, logistics;

    beforeEach(async function () {
        [owner, shipper, receiver, logistics] = await ethers.getSigners();

        const PrivateCargoTracking = await ethers.getContractFactory("PrivateCargoTracking");
        contract = await PrivateCargoTracking.deploy();
        await contract.deployed();
    });

    describe("Cargo Creation", function() {
        it("Should create cargo with encrypted data", async function () {
            const tx = await contract.connect(shipper).createCargo(
                1000, // weight
                5000, // value
                receiver.address
            );

            const receipt = await tx.wait();
            expect(receipt.events[0].event).to.equal("CargoCreated");
        });

        it("Should increment cargo ID correctly", async function () {
            await contract.connect(shipper).createCargo(1000, 5000, receiver.address);
            await contract.connect(shipper).createCargo(2000, 3000, receiver.address);

            const nextId = await contract.nextCargoId();
            expect(nextId).to.equal(3);
        });
    });

    describe("Access Control", function() {
        let cargoId;

        beforeEach(async function() {
            const tx = await contract.connect(shipper).createCargo(1000, 5000, receiver.address);
            const receipt = await tx.wait();
            cargoId = receipt.events[0].args.cargoId;
        });

        it("Should grant access to authorized users", async function () {
            await contract.connect(shipper).grantAccess(cargoId, logistics.address);

            const hasAccess = await contract.hasAccess(cargoId, logistics.address);
            expect(hasAccess).to.be.true;
        });

        it("Should prevent unauthorized access grants", async function () {
            await expect(
                contract.connect(receiver).grantAccess(cargoId, logistics.address)
            ).to.be.revertedWith("Only shipper can grant access");
        });
    });
});
```

#### **5.2 Integration Testing**

Test the full stack integration:

```javascript
// test/integration/FullStack.test.js
const { expect } = require("chai");

describe("Full Stack Integration", function() {
    it("Should handle complete cargo lifecycle", async function() {
        // 1. Deploy contract
        // 2. Create frontend instance
        // 3. Test wallet connection
        // 4. Test cargo creation
        // 5. Test location updates
        // 6. Test access control
        // 7. Verify privacy preservation
    });
});
```

### 🚀 Deployment Guide

#### **5.3 Deploy to Sepolia Testnet**

Create `scripts/deploy.js`:
```javascript
const hre = require("hardhat");

async function main() {
    console.log("🚀 Deploying PrivateCargoTracking to Sepolia...");

    // Deploy the contract
    const PrivateCargoTracking = await hre.ethers.getContractFactory("PrivateCargoTracking");
    const contract = await PrivateCargoTracking.deploy();

    await contract.deployed();

    console.log("✅ Contract deployed to:", contract.address);
    console.log("🔗 Etherscan:", `https://sepolia.etherscan.io/address/${contract.address}`);

    // Verify the contract
    if (hre.network.name !== "hardhat") {
        console.log("⏳ Waiting for verification...");
        await new Promise(resolve => setTimeout(resolve, 30000)); // Wait 30 seconds

        try {
            await hre.run("verify:verify", {
                address: contract.address,
                constructorArguments: []
            });
            console.log("✅ Contract verified!");
        } catch (error) {
            console.log("❌ Verification failed:", error.message);
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

Deploy your contract:
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

#### **5.4 Frontend Deployment**

Deploy to Vercel:

1. **Build your frontend:**
```bash
cd frontend
npm run build
```

2. **Deploy to Vercel:**
```bash
npm install -g vercel
vercel --prod
```

3. **Configure environment variables:**
```bash
vercel env add REACT_APP_CONTRACT_ADDRESS
vercel env add REACT_APP_NETWORK_ID
```

---

## Chapter 6: Advanced Concepts

### 🔬 Advanced FHEVM Features

#### **6.1 Batch Operations**

Optimize gas usage with batch operations:

```solidity
contract BatchOperations {
    function batchUpdateCargos(
        uint32[] calldata _cargoIds,
        einput[] calldata _encryptedStatuses
    ) external {
        for(uint i = 0; i < _cargoIds.length; i++) {
            // Update each cargo status
            updateCargoStatus(_cargoIds[i], _encryptedStatuses[i]);
        }
    }
}
```

#### **6.2 Event Filtering with Privacy**

Implement privacy-preserving event filtering:

```solidity
contract PrivateEvents {
    event CargoStatusChanged(
        uint32 indexed cargoId,
        bytes32 encryptedStatusHash  // Hash of encrypted status
    );

    function updateWithPrivateEvent(
        uint32 _cargoId,
        einput _encryptedStatus
    ) external {
        euint32 status = FHEVM.asEuint32(_encryptedStatus);

        // Update status
        cargos[_cargoId].status = status;

        // Emit event with encrypted hash
        bytes32 statusHash = keccak256(abi.encodePacked(
            FHEVM.toBytes(status)
        ));

        emit CargoStatusChanged(_cargoId, statusHash);
    }
}
```

#### **6.3 Cross-Contract Privacy**

Maintain privacy across multiple contracts:

```solidity
contract PrivacyOracle {
    mapping(bytes32 => euint32) private sharedSecrets;

    function shareSecret(
        bytes32 _key,
        einput _encryptedSecret
    ) external {
        euint32 secret = FHEVM.asEuint32(_encryptedSecret);
        sharedSecrets[_key] = secret;

        // Grant access to calling contract
        FHEVM.allowThis(secret);
    }

    function getSharedSecret(bytes32 _key)
        external
        view
        returns (euint32)
    {
        return sharedSecrets[_key];
    }
}
```

### 🎯 Performance Optimization

#### **6.4 Gas Optimization Techniques**

```solidity
contract OptimizedContract {
    // Use packed structs for better storage efficiency
    struct PackedCargo {
        euint32 weight;      // 32 bytes
        euint32 value;       // 32 bytes
        eaddress receiver;   // 32 bytes
        uint64 timestamp;    // 8 bytes - fits in same slot
        uint8 status;        // 1 byte - fits in same slot
    }

    // Minimize expensive operations
    function efficientUpdate(uint32 _id, einput _data) external {
        // Cache frequently accessed data
        PackedCargo storage cargo = cargos[_id];

        // Single SSTORE operation
        cargo.value = FHEVM.asEuint32(_data);
    }
}
```

#### **6.5 Security Best Practices**

```solidity
contract SecurePrivacyContract {
    // Prevent replay attacks with nonces
    mapping(address => uint256) private nonces;

    function secureOperation(
        einput _data,
        uint256 _nonce,
        bytes calldata _signature
    ) external {
        // Verify nonce
        require(_nonce > nonces[msg.sender], "Invalid nonce");
        nonces[msg.sender] = _nonce;

        // Verify signature
        bytes32 hash = keccak256(abi.encodePacked(_data, _nonce));
        require(verifySignature(hash, _signature), "Invalid signature");

        // Process encrypted data
        euint32 data = FHEVM.asEuint32(_data);
        // ... secure operations
    }
}
```

---

## 🎉 Congratulations!

You've successfully built your first confidential application using FHEVM! Let's recap what you've accomplished:

### ✅ **What You've Learned**

- **FHEVM Fundamentals**: Understanding encrypted smart contracts
- **Privacy-Preserving Operations**: Working with encrypted data types
- **Access Control**: Managing confidential permissions
- **Frontend Integration**: Connecting UI to confidential contracts
- **Testing & Deployment**: Full development lifecycle
- **Advanced Patterns**: Optimization and security best practices

### 🚀 **Your Final Application Features**

- ✅ **Encrypted Cargo Creation** - Confidential shipment details
- ✅ **Private Location Tracking** - Hidden GPS coordinates
- ✅ **Access Control Management** - Selective data sharing
- ✅ **Privacy-Preserving UI** - User-friendly confidential operations
- ✅ **Live Testnet Deployment** - Real blockchain deployment

## 🔄 Next Steps

### **Extend Your Application**
1. **Add more cargo types** with different privacy levels
2. **Implement confidential payments** using encrypted amounts
3. **Create a mobile app** for on-the-go tracking
4. **Add multi-signature** support for high-value cargo
5. **Integrate IoT sensors** for real-time cargo monitoring

### **Learn More Advanced Topics**
- **Zero-Knowledge Proofs** integration with FHEVM
- **Cross-chain privacy** preservation
- **Threshold encryption** for distributed access
- **Privacy-preserving analytics** on encrypted data

### **Join the Community**
- **FHEVM Documentation**: [docs.zama.ai/fhevm](https://docs.zama.ai/fhevm)
- **Discord Community**: Join the FHEVM developer discussions
- **GitHub**: Contribute to open-source privacy tools
- **Twitter**: Follow @ZamaFHE for updates

## 📚 Additional Resources

### **Documentation & Guides**
- [FHEVM Developer Docs](https://docs.zama.ai/fhevm)
- [Solidity Best Practices](https://docs.soliditylang.org/)
- [React.js Documentation](https://reactjs.org/docs)
- [Hardhat Framework](https://hardhat.org/docs)

### **Example Projects**
- **Private Voting System**: Democratic voting with encrypted ballots
- **Confidential Auctions**: Sealed-bid auction implementation
- **Secret Salary Surveys**: Anonymous salary data collection
- **Private Medical Records**: Healthcare data with selective access

### **Development Tools**
- **Remix IDE**: Browser-based Solidity development
- **Hardhat**: Ethereum development environment
- **OpenZeppelin**: Security-focused smart contract library
- **MetaMask**: Browser wallet for testing

---

<div align="center">

**🔐 You've mastered the fundamentals of confidential smart contract development!**

[![FHEVM](https://img.shields.io/badge/Powered_by-FHEVM-gold?style=flat-square)](https://docs.zama.ai/fhevm)
[![Privacy](https://img.shields.io/badge/Privacy-First-green?style=flat-square)](https://zama.ai)
[![Web3](https://img.shields.io/badge/Built_for-Web3-blue?style=flat-square)](https://ethereum.org)

**Continue building the future of privacy-preserving applications!**

</div>