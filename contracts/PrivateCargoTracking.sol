// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract PrivateCargoTracking is SepoliaConfig {

    address public owner;
    uint32 public nextCargoId;

    struct CargoInfo {
        euint32 weight;           // 加密重量
        euint8 category;          // 加密货物类别 (0-255)
        euint32 value;            // 加密货物价值
        euint8 priority;          // 加密优先级 (0-10)
        bool exists;              // 货物是否存在
        address shipper;          // 发货方
        address receiver;         // 收货方
        uint256 timestamp;        // 创建时间
    }

    struct Location {
        euint32 latitude;         // 加密纬度
        euint32 longitude;        // 加密经度
        euint8 status;            // 加密状态 (0: 待发货, 1: 运输中, 2: 已到达, 3: 已交付)
        uint256 timestamp;        // 位置更新时间
        address updater;          // 位置更新者
    }

    struct Authorization {
        bool canView;             // 可以查看基本信息
        bool canTrack;            // 可以跟踪位置
        bool canUpdate;           // 可以更新状态
        uint256 expiresAt;        // 授权过期时间
    }

    mapping(uint32 => CargoInfo) public cargos;
    mapping(uint32 => Location[]) public locations;
    mapping(uint32 => mapping(address => Authorization)) public authorizations;
    mapping(address => uint32[]) public shipperCargos;
    mapping(address => uint32[]) public receiverCargos;

    event CargoCreated(uint32 indexed cargoId, address indexed shipper, address indexed receiver, uint256 timestamp);
    event LocationUpdated(uint32 indexed cargoId, address indexed updater, uint256 timestamp);
    event StatusChanged(uint32 indexed cargoId, uint8 newStatus, uint256 timestamp);
    event AuthorizationGranted(uint32 indexed cargoId, address indexed authorized, address indexed grantor);
    event AuthorizationRevoked(uint32 indexed cargoId, address indexed revoked, address indexed revoker);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier cargoExists(uint32 _cargoId) {
        require(cargos[_cargoId].exists, "Cargo does not exist");
        _;
    }

    modifier onlyAuthorized(uint32 _cargoId, string memory _action) {
        require(_isAuthorized(_cargoId, msg.sender, _action), "Not authorized for this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        nextCargoId = 1;
    }

    // 创建新货物
    function createCargo(
        uint32 _weight,
        uint8 _category,
        uint32 _value,
        uint8 _priority,
        address _receiver
    ) public returns (uint32) {
        require(_receiver != address(0), "Invalid receiver address");
        require(_receiver != msg.sender, "Cannot ship to yourself");

        uint32 cargoId = nextCargoId++;

        // 加密敏感信息
        euint32 encWeight = FHE.asEuint32(_weight);
        euint8 encCategory = FHE.asEuint8(_category);
        euint32 encValue = FHE.asEuint32(_value);
        euint8 encPriority = FHE.asEuint8(_priority);

        cargos[cargoId] = CargoInfo({
            weight: encWeight,
            category: encCategory,
            value: encValue,
            priority: encPriority,
            exists: true,
            shipper: msg.sender,
            receiver: _receiver,
            timestamp: block.timestamp
        });

        // 设置ACL权限
        FHE.allowThis(encWeight);
        FHE.allowThis(encCategory);
        FHE.allowThis(encValue);
        FHE.allowThis(encPriority);

        FHE.allow(encWeight, msg.sender);
        FHE.allow(encCategory, msg.sender);
        FHE.allow(encValue, msg.sender);
        FHE.allow(encPriority, msg.sender);

        FHE.allow(encWeight, _receiver);
        FHE.allow(encCategory, _receiver);
        FHE.allow(encValue, _receiver);
        FHE.allow(encPriority, _receiver);

        // 添加到发货方和收货方列表
        shipperCargos[msg.sender].push(cargoId);
        receiverCargos[_receiver].push(cargoId);

        // 初始化位置 (待发货状态)
        _updateLocation(cargoId, 0, 0, 0);

        emit CargoCreated(cargoId, msg.sender, _receiver, block.timestamp);
        return cargoId;
    }

    // 更新货物位置
    function updateLocation(
        uint32 _cargoId,
        uint32 _latitude,
        uint32 _longitude,
        uint8 _status
    ) external cargoExists(_cargoId) onlyAuthorized(_cargoId, "update") {
        _updateLocation(_cargoId, _latitude, _longitude, _status);
    }

    // 内部更新位置函数
    function _updateLocation(
        uint32 _cargoId,
        uint32 _latitude,
        uint32 _longitude,
        uint8 _status
    ) internal {
        euint32 encLatitude = FHE.asEuint32(_latitude);
        euint32 encLongitude = FHE.asEuint32(_longitude);
        euint8 encStatus = FHE.asEuint8(_status);

        Location memory newLocation = Location({
            latitude: encLatitude,
            longitude: encLongitude,
            status: encStatus,
            timestamp: block.timestamp,
            updater: msg.sender
        });

        locations[_cargoId].push(newLocation);

        // 设置ACL权限
        FHE.allowThis(encLatitude);
        FHE.allowThis(encLongitude);
        FHE.allowThis(encStatus);

        // 允许发货方和收货方查看
        CargoInfo storage cargo = cargos[_cargoId];
        FHE.allow(encLatitude, cargo.shipper);
        FHE.allow(encLongitude, cargo.shipper);
        FHE.allow(encStatus, cargo.shipper);

        FHE.allow(encLatitude, cargo.receiver);
        FHE.allow(encLongitude, cargo.receiver);
        FHE.allow(encStatus, cargo.receiver);

        emit LocationUpdated(_cargoId, msg.sender, block.timestamp);
        emit StatusChanged(_cargoId, _status, block.timestamp);
    }

    // 授权第三方访问权限
    function grantAuthorization(
        uint32 _cargoId,
        address _authorized,
        bool _canView,
        bool _canTrack,
        bool _canUpdate,
        uint256 _expiresAt
    ) external cargoExists(_cargoId) {
        require(_isCargoParty(_cargoId, msg.sender), "Only shipper or receiver can grant authorization");
        require(_authorized != address(0), "Invalid address");
        require(_expiresAt > block.timestamp, "Expiration must be in the future");

        authorizations[_cargoId][_authorized] = Authorization({
            canView: _canView,
            canTrack: _canTrack,
            canUpdate: _canUpdate,
            expiresAt: _expiresAt
        });

        // 如果授权查看或跟踪，给予FHE访问权限
        if (_canView || _canTrack) {
            CargoInfo storage cargo = cargos[_cargoId];

            if (_canView) {
                FHE.allow(cargo.weight, _authorized);
                FHE.allow(cargo.category, _authorized);
                FHE.allow(cargo.value, _authorized);
                FHE.allow(cargo.priority, _authorized);
            }

            if (_canTrack && locations[_cargoId].length > 0) {
                for (uint i = 0; i < locations[_cargoId].length; i++) {
                    FHE.allow(locations[_cargoId][i].latitude, _authorized);
                    FHE.allow(locations[_cargoId][i].longitude, _authorized);
                    FHE.allow(locations[_cargoId][i].status, _authorized);
                }
            }
        }

        emit AuthorizationGranted(_cargoId, _authorized, msg.sender);
    }

    // 撤销授权
    function revokeAuthorization(
        uint32 _cargoId,
        address _authorized
    ) external cargoExists(_cargoId) {
        require(_isCargoParty(_cargoId, msg.sender), "Only shipper or receiver can revoke authorization");

        delete authorizations[_cargoId][_authorized];

        emit AuthorizationRevoked(_cargoId, _authorized, msg.sender);
    }

    // 获取货物基本信息（仅授权用户）
    function getCargoInfo(uint32 _cargoId) external view cargoExists(_cargoId) onlyAuthorized(_cargoId, "view") returns (
        address shipper,
        address receiver,
        uint256 timestamp,
        uint256 locationCount
    ) {
        CargoInfo storage cargo = cargos[_cargoId];
        return (
            cargo.shipper,
            cargo.receiver,
            cargo.timestamp,
            locations[_cargoId].length
        );
    }

    // 获取最新位置信息（仅授权用户）
    function getLatestLocation(uint32 _cargoId) external view cargoExists(_cargoId) onlyAuthorized(_cargoId, "track") returns (
        uint256 timestamp,
        address updater
    ) {
        require(locations[_cargoId].length > 0, "No location data");
        Location storage latest = locations[_cargoId][locations[_cargoId].length - 1];
        return (latest.timestamp, latest.updater);
    }

    // 获取位置历史数量
    function getLocationCount(uint32 _cargoId) external view cargoExists(_cargoId) returns (uint256) {
        return locations[_cargoId].length;
    }

    // 获取用户的发货列表
    function getShipperCargos(address _shipper) external view returns (uint32[] memory) {
        return shipperCargos[_shipper];
    }

    // 获取用户的收货列表
    function getReceiverCargos(address _receiver) external view returns (uint32[] memory) {
        return receiverCargos[_receiver];
    }

    // 检查用户是否有特定操作的权限
    function _isAuthorized(uint32 _cargoId, address _user, string memory _action) internal view returns (bool) {
        // 货物相关方始终有权限
        if (_isCargoParty(_cargoId, _user)) {
            return true;
        }

        Authorization storage auth = authorizations[_cargoId][_user];

        // 检查授权是否过期
        if (auth.expiresAt <= block.timestamp) {
            return false;
        }

        // 检查具体权限
        if (keccak256(bytes(_action)) == keccak256(bytes("view"))) {
            return auth.canView;
        } else if (keccak256(bytes(_action)) == keccak256(bytes("track"))) {
            return auth.canTrack;
        } else if (keccak256(bytes(_action)) == keccak256(bytes("update"))) {
            return auth.canUpdate;
        }

        return false;
    }

    // 检查用户是否为货物相关方（发货方或收货方）
    function _isCargoParty(uint32 _cargoId, address _user) internal view returns (bool) {
        CargoInfo storage cargo = cargos[_cargoId];
        return _user == cargo.shipper || _user == cargo.receiver;
    }

    // 检查授权状态
    function checkAuthorization(uint32 _cargoId, address _user) external view cargoExists(_cargoId) returns (
        bool canView,
        bool canTrack,
        bool canUpdate,
        uint256 expiresAt,
        bool isExpired
    ) {
        if (_isCargoParty(_cargoId, _user)) {
            return (true, true, true, type(uint256).max, false);
        }

        Authorization storage auth = authorizations[_cargoId][_user];
        bool expired = auth.expiresAt <= block.timestamp;

        return (
            auth.canView,
            auth.canTrack,
            auth.canUpdate,
            auth.expiresAt,
            expired
        );
    }

    // 批量创建货物（适用于物流公司）
    function createBatchCargos(
        uint32[] memory _weights,
        uint8[] memory _categories,
        uint32[] memory _values,
        uint8[] memory _priorities,
        address[] memory _receivers
    ) external returns (uint32[] memory) {
        require(_weights.length == _categories.length, "Array length mismatch");
        require(_weights.length == _values.length, "Array length mismatch");
        require(_weights.length == _priorities.length, "Array length mismatch");
        require(_weights.length == _receivers.length, "Array length mismatch");
        require(_weights.length > 0 && _weights.length <= 50, "Invalid batch size");

        uint32[] memory cargoIds = new uint32[](_weights.length);

        for (uint i = 0; i < _weights.length; i++) {
            cargoIds[i] = createCargo(
                _weights[i],
                _categories[i],
                _values[i],
                _priorities[i],
                _receivers[i]
            );
        }

        return cargoIds;
    }

    // 应急情况处理 - 所有者可以更新任何货物状态
    function emergencyStatusUpdate(
        uint32 _cargoId,
        uint32 _latitude,
        uint32 _longitude,
        uint8 _status
    ) external onlyOwner cargoExists(_cargoId) {
        _updateLocation(_cargoId, _latitude, _longitude, _status);
    }
}