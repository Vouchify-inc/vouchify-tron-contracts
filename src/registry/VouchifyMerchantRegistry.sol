// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IVouchifyMerchantRegistry } from "../interfaces/IVouchifyMerchantRegistry.sol";
import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../libraries/VouchifyErrors.sol";

/// @title VouchifyMerchantRegistry
/// @notice On-chain registry of verified merchants with balance tracking
/// @dev Used for transparent balance tracking and merchant verification status
contract VouchifyMerchantRegistry is IVouchifyMerchantRegistry, AccessControl, Pausable, ReentrancyGuard {
    // ============ Constants ============
    
    /// @notice Role for operators who can credit/debit balances
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    /// @notice Role for registrars who can register/verify merchants
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    
    /// @notice Role for pausing
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Version for upgrade tracking
    string public constant VERSION = "1.0.0";

    // ============ State Variables ============
    
    /// @notice Mapping: merchantId => MerchantRecord
    mapping(uint256 => VouchifyTypes.MerchantRecord) private _merchants;
    
    /// @notice Mapping: wallet address => merchantId
    mapping(address => uint256) private _walletToMerchant;
    
    /// @notice Total registered merchants
    uint256 private _totalMerchants;
    
    /// @notice Array of all merchant IDs (for enumeration)
    uint256[] private _merchantIds;

    // ============ Constructor ============
    
    /// @notice Initialize the registry
    /// @param admin Admin address
    constructor(address admin) {
        if (admin == address(0)) revert VouchifyErrors.ZeroAddress();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
        _grantRole(REGISTRAR_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    // ============ Admin Functions ============
    
    /// @inheritdoc IVouchifyMerchantRegistry
    function registerMerchant(
        uint256 merchantId,
        address wallet
    ) external override onlyRole(REGISTRAR_ROLE) whenNotPaused {
        if (wallet == address(0)) revert VouchifyErrors.ZeroAddress();
        if (_merchants[merchantId].registeredAt != 0) {
            revert VouchifyErrors.MerchantAlreadyRegistered();
        }
        if (_walletToMerchant[wallet] != 0) {
            revert VouchifyErrors.MerchantAlreadyRegistered();
        }
        
        _merchants[merchantId] = VouchifyTypes.MerchantRecord({
            merchantId: merchantId,
            walletAddress: wallet,
            isVerified: false,
            isActive: false,
            totalEarned: 0,
            pendingBalance: 0,
            withdrawnTotal: 0,
            registeredAt: block.timestamp
        });
        
        _walletToMerchant[wallet] = merchantId;
        _merchantIds.push(merchantId);
        _totalMerchants++;
        
        emit MerchantRegistered(merchantId, wallet, block.timestamp);
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function verifyMerchant(uint256 merchantId) external override onlyRole(REGISTRAR_ROLE) whenNotPaused {
        if (_merchants[merchantId].registeredAt == 0) {
            revert VouchifyErrors.MerchantNotFound();
        }
        
        _merchants[merchantId].isVerified = true;
        _merchants[merchantId].isActive = true;
        
        emit MerchantVerified(merchantId, block.timestamp);
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function deactivateMerchant(uint256 merchantId) external override onlyRole(REGISTRAR_ROLE) whenNotPaused {
        if (_merchants[merchantId].registeredAt == 0) {
            revert VouchifyErrors.MerchantNotFound();
        }
        
        _merchants[merchantId].isActive = false;
        
        emit MerchantDeactivated(merchantId, block.timestamp);
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function activateMerchant(uint256 merchantId) external override onlyRole(REGISTRAR_ROLE) whenNotPaused {
        if (_merchants[merchantId].registeredAt == 0) {
            revert VouchifyErrors.MerchantNotFound();
        }
        if (!_merchants[merchantId].isVerified) {
            revert VouchifyErrors.MerchantNotVerified();
        }
        
        _merchants[merchantId].isActive = true;
        
        emit MerchantActivated(merchantId, block.timestamp);
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function updateMerchantWallet(
        uint256 merchantId,
        address newWallet
    ) external override onlyRole(REGISTRAR_ROLE) whenNotPaused {
        if (newWallet == address(0)) revert VouchifyErrors.ZeroAddress();
        if (_merchants[merchantId].registeredAt == 0) {
            revert VouchifyErrors.MerchantNotFound();
        }
        if (_walletToMerchant[newWallet] != 0) {
            revert VouchifyErrors.MerchantAlreadyRegistered();
        }
        
        address oldWallet = _merchants[merchantId].walletAddress;
        
        // Update mappings
        delete _walletToMerchant[oldWallet];
        _walletToMerchant[newWallet] = merchantId;
        _merchants[merchantId].walletAddress = newWallet;
        
        emit MerchantWalletUpdated(merchantId, oldWallet, newWallet);
    }

    // ============ Balance Functions ============
    
    /// @inheritdoc IVouchifyMerchantRegistry
    function creditBalance(
        uint256 merchantId,
        uint256 amount,
        bytes32 voucherId
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        if (_merchants[merchantId].registeredAt == 0) {
            revert VouchifyErrors.MerchantNotFound();
        }
        if (amount == 0) revert VouchifyErrors.InvalidAmount();
        
        _merchants[merchantId].pendingBalance += amount;
        _merchants[merchantId].totalEarned += amount;
        
        emit BalanceCredited(merchantId, amount, voucherId, _merchants[merchantId].pendingBalance);
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function debitBalance(
        uint256 merchantId,
        uint256 amount,
        string calldata reason
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        if (_merchants[merchantId].registeredAt == 0) {
            revert VouchifyErrors.MerchantNotFound();
        }
        if (amount == 0) revert VouchifyErrors.InvalidAmount();
        if (amount > _merchants[merchantId].pendingBalance) {
            revert VouchifyErrors.WithdrawalExceedsBalance();
        }
        
        _merchants[merchantId].pendingBalance -= amount;
        _merchants[merchantId].withdrawnTotal += amount;
        
        emit BalanceDebited(merchantId, amount, reason, _merchants[merchantId].pendingBalance);
    }

    // ============ Pause Functions ============
    
    /// @notice Pause the registry
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the registry
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ============ View Functions ============
    
    /// @inheritdoc IVouchifyMerchantRegistry
    function getMerchant(
        uint256 merchantId
    ) external view override returns (VouchifyTypes.MerchantRecord memory) {
        if (_merchants[merchantId].registeredAt == 0) {
            revert VouchifyErrors.MerchantNotFound();
        }
        return _merchants[merchantId];
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function getMerchantByWallet(address wallet) external view override returns (uint256) {
        return _walletToMerchant[wallet];
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function isMerchantActive(uint256 merchantId) external view override returns (bool) {
        return _merchants[merchantId].isVerified && _merchants[merchantId].isActive;
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function getPendingBalance(uint256 merchantId) external view override returns (uint256) {
        return _merchants[merchantId].pendingBalance;
    }

    /// @inheritdoc IVouchifyMerchantRegistry
    function totalMerchants() external view override returns (uint256) {
        return _totalMerchants;
    }

    /// @notice Get merchant ID at index
    /// @param index Index in merchant array
    /// @return Merchant ID
    function getMerchantIdAtIndex(uint256 index) external view returns (uint256) {
        require(index < _merchantIds.length, "Index out of bounds");
        return _merchantIds[index];
    }

    /// @notice Check if merchant exists
    /// @param merchantId Merchant ID
    /// @return True if exists
    function merchantExists(uint256 merchantId) external view returns (bool) {
        return _merchants[merchantId].registeredAt != 0;
    }
}
