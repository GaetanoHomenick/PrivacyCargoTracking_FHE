// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint64, ebool, euint8 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/**
 * @title Privacy Cargo Tracking with FHE
 * @dev Simplified FHE implementation focusing on encryption without problematic decryption
 */
contract PrivacyCargoTracking {
    using FHE for euint8;
    using FHE for euint64;
    using FHE for ebool;

    struct Cargo {
        string cargoId;
        string destination;
        string status;
        string location;
        euint8 encryptedPriority;    // FHE encrypted priority (0-3)
        ebool encryptedIsFragile;    // FHE encrypted fragile flag
        euint64 encryptedValue;      // FHE encrypted cargo value
        address owner;
        address authorizedViewer;
        uint256 timestamp;
        bool isPublic;               // Plain boolean for privacy setting to avoid decrypt issues
        bool exists;
    }

    mapping(string => Cargo) public cargos;
    mapping(address => string[]) public ownerCargos;

    event CargoCreated(string indexed cargoId, address indexed owner);
    event CargoStatusUpdated(string indexed cargoId, string status, string location);
    event CargoPrivacyUpdated(string indexed cargoId, bool isPublic);

    modifier cargoExists(string calldata cargoId) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        _;
    }

    modifier onlyAuthorized(string calldata cargoId) {
        Cargo storage cargo = cargos[cargoId];
        require(
            cargo.owner == msg.sender ||
            cargo.authorizedViewer == msg.sender ||
            cargo.isPublic,
            "Not authorized to view this cargo"
        );
        _;
    }

    modifier onlyCargoOwner(string calldata cargoId) {
        require(cargos[cargoId].owner == msg.sender, "Only cargo owner allowed");
        _;
    }

    /**
     * @dev Create a new cargo with FHE-encrypted sensitive data
     */
    function createCargo(
        string calldata cargoId,
        string calldata destination,
        uint8 priority,
        bool isFragile,
        uint64 cargoValue
    ) external {
        require(!cargos[cargoId].exists, "Cargo already exists");
        require(bytes(cargoId).length > 0, "Cargo ID cannot be empty");
        require(bytes(destination).length > 0, "Destination cannot be empty");
        require(priority <= 3, "Priority must be 0-3");

        // FHE encryption - contract handles encryption internally
        euint8 encryptedPriority = FHE.asEuint8(priority);
        ebool encryptedIsFragile = FHE.asEbool(isFragile);
        euint64 encryptedValue = FHE.asEuint64(cargoValue);

        // Grant permissions to encrypted values
        FHE.allowThis(encryptedPriority);
        FHE.allow(encryptedPriority, msg.sender);

        FHE.allowThis(encryptedIsFragile);
        FHE.allow(encryptedIsFragile, msg.sender);

        FHE.allowThis(encryptedValue);
        FHE.allow(encryptedValue, msg.sender);

        cargos[cargoId] = Cargo({
            cargoId: cargoId,
            destination: destination,
            status: "Created",
            location: "Origin",
            encryptedPriority: encryptedPriority,
            encryptedIsFragile: encryptedIsFragile,
            encryptedValue: encryptedValue,
            owner: msg.sender,
            authorizedViewer: address(0),
            timestamp: block.timestamp,
            isPublic: false,
            exists: true
        });

        ownerCargos[msg.sender].push(cargoId);

        emit CargoCreated(cargoId, msg.sender);
    }

    /**
     * @dev Update cargo status and location
     */
    function updateStatus(
        string calldata cargoId,
        string calldata status,
        string calldata location
    ) external {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(cargos[cargoId].owner == msg.sender, "Only cargo owner allowed");

        cargos[cargoId].status = status;
        cargos[cargoId].location = location;
        cargos[cargoId].timestamp = block.timestamp;

        emit CargoStatusUpdated(cargoId, status, location);
    }

    /**
     * @dev Update cargo privacy settings
     */
    function updatePrivacySettings(
        string calldata cargoId,
        bool isPublic,
        address authorizedViewer
    ) external {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(cargos[cargoId].owner == msg.sender, "Only cargo owner allowed");
        cargos[cargoId].isPublic = isPublic;
        cargos[cargoId].authorizedViewer = authorizedViewer;

        // Grant permissions to authorized viewer if set
        if (authorizedViewer != address(0)) {
            FHE.allow(cargos[cargoId].encryptedPriority, authorizedViewer);
            FHE.allow(cargos[cargoId].encryptedIsFragile, authorizedViewer);
            FHE.allow(cargos[cargoId].encryptedValue, authorizedViewer);
        }

        emit CargoPrivacyUpdated(cargoId, isPublic);
    }

    /**
     * @dev Get cargo ID
     */
    function getCargoId(string calldata cargoId) external view returns (string memory) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender ||
            cargos[cargoId].isPublic,
            "Not authorized"
        );
        return cargos[cargoId].cargoId;
    }

    /**
     * @dev Get cargo destination
     */
    function getCargoDestination(string calldata cargoId) external view returns (string memory) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender ||
            cargos[cargoId].isPublic,
            "Not authorized"
        );
        return cargos[cargoId].destination;
    }

    /**
     * @dev Get cargo status
     */
    function getCargoStatus(string calldata cargoId) external view returns (string memory) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender ||
            cargos[cargoId].isPublic,
            "Not authorized"
        );
        return cargos[cargoId].status;
    }

    /**
     * @dev Get cargo location
     */
    function getCargoLocation(string calldata cargoId) external view returns (string memory) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender ||
            cargos[cargoId].isPublic,
            "Not authorized"
        );
        return cargos[cargoId].location;
    }

    /**
     * @dev Check if cargo is public
     */
    function isCargoPublic(string calldata cargoId) external view returns (bool) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        return cargos[cargoId].isPublic;
    }

    /**
     * @dev Get cargo owner
     */
    function getCargoOwner(string calldata cargoId) external view returns (address) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender ||
            cargos[cargoId].isPublic,
            "Not authorized"
        );
        return cargos[cargoId].owner;
    }

    /**
     * @dev Get cargo timestamp
     */
    function getCargoTimestamp(string calldata cargoId) external view returns (uint256) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender ||
            cargos[cargoId].isPublic,
            "Not authorized"
        );
        return cargos[cargoId].timestamp;
    }

    /**
     * @dev Get all cargo IDs for a specific owner
     */
    function getOwnerCargos(address owner) external view returns (string[] memory) {
        return ownerCargos[owner];
    }

    /**
     * @dev Get public cargo destination
     */
    function getPublicCargoDestination(string calldata cargoId) external view returns (string memory) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(cargos[cargoId].isPublic, "Cargo is private");
        return cargos[cargoId].destination;
    }

    /**
     * @dev Get public cargo status
     */
    function getPublicCargoStatus(string calldata cargoId) external view returns (string memory) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(cargos[cargoId].isPublic, "Cargo is private");
        return cargos[cargoId].status;
    }

    /**
     * @dev Get public cargo location
     */
    function getPublicCargoLocation(string calldata cargoId) external view returns (string memory) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(cargos[cargoId].isPublic, "Cargo is private");
        return cargos[cargoId].location;
    }

    /**
     * @dev Get public cargo owner
     */
    function getPublicCargoOwner(string calldata cargoId) external view returns (address) {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(cargos[cargoId].isPublic, "Cargo is private");
        return cargos[cargoId].owner;
    }

    /**
     * @dev Authorize a new viewer for encrypted data
     */
    function authorizeViewer(string calldata cargoId, address viewer)
        external
    {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(cargos[cargoId].owner == msg.sender, "Only cargo owner allowed");
        // Grant permissions to the new viewer for all encrypted fields
        FHE.allow(cargos[cargoId].encryptedPriority, viewer);
        FHE.allow(cargos[cargoId].encryptedIsFragile, viewer);
        FHE.allow(cargos[cargoId].encryptedValue, viewer);

        cargos[cargoId].authorizedViewer = viewer;
    }

    /**
     * @dev Get encrypted priority (for authorized users only)
     */
    function getEncryptedPriority(string calldata cargoId)
        external
        view
        returns (euint8)
    {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender,
            "Not authorized"
        );
        return cargos[cargoId].encryptedPriority;
    }

    /**
     * @dev Get encrypted fragile flag (for authorized users only)
     */
    function getEncryptedIsFragile(string calldata cargoId)
        external
        view
        returns (ebool)
    {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender,
            "Not authorized"
        );
        return cargos[cargoId].encryptedIsFragile;
    }

    /**
     * @dev Get encrypted value (for authorized users only)
     */
    function getEncryptedValue(string calldata cargoId)
        external
        view
        returns (euint64)
    {
        require(cargos[cargoId].exists, "Cargo does not exist");
        require(
            cargos[cargoId].owner == msg.sender ||
            cargos[cargoId].authorizedViewer == msg.sender,
            "Not authorized"
        );
        return cargos[cargoId].encryptedValue;
    }
}