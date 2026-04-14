// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IVouchifyEscrow } from "../interfaces/IVouchifyEscrow.sol";
import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../libraries/VouchifyErrors.sol";

/// @title VouchifyEscrow
/// @notice Clone template for per-voucher escrow. Each clone holds ONE voucher's data.
/// @dev Deployed as minimal proxy (EIP-1167). Logic delegated to implementation.
contract VouchifyEscrow is IVouchifyEscrow {
    // ============ Constants ============
    
    /// @notice Version for upgrade tracking
    string public constant VERSION = "1.0.0";

    // ============ Immutable References ============
    
    /// @notice Factory that deployed this clone
    address public factory;

    // ============ Voucher Data ============
    
    bytes32 private _voucherId;
    uint256 private _tokenId;
    address private _buyer;
    address private _currentOwner;
    uint256 private _merchantId;
    uint256 private _amount;
    uint256 private _remainingAmount;
    uint256 private _platformFee;
    VouchifyTypes.PaymentMethod private _paymentMethod;
    string private _externalTxId;
    VouchifyTypes.EscrowStatus private _status;
    
    // ============ Timestamps ============
    
    uint256 public createdAt;
    uint256 public expiresAt;
    uint256 public redeemedAt;
    uint256 public activatedAt;

    // ============ Redemption History ============
    
    VouchifyTypes.Redemption[] private _redemptions;

    // ============ Initialization Flag ============
    
    bool private _initialized;

    // ============ Modifiers ============
    
    modifier onlyFactory() {
        if (msg.sender != factory) revert VouchifyErrors.NotFactory();
        _;
    }

    modifier onlyOnce() {
        if (_initialized) revert VouchifyErrors.AlreadyInitialized();
        _;
    }

    modifier whenActive() {
        if (_status != VouchifyTypes.EscrowStatus.ACTIVE && 
            _status != VouchifyTypes.EscrowStatus.PARTIALLY_REDEEMED) {
            revert VouchifyErrors.EscrowNotActive();
        }
        _;
    }

    modifier notExpired() {
        if (block.timestamp >= expiresAt) revert VouchifyErrors.EscrowExpired();
        _;
    }

    // ============ Constructor ============
    
    /// @notice Constructor is empty - all state set via initialize()
    constructor() {
        // Implementation contract should not be initialized
        // Clones will call initialize()
    }

    // ============ Initialization ============
    
    /// @inheritdoc IVouchifyEscrow
    function initialize(
        bytes32 voucherId_,
        uint256 tokenId_,
        address buyer_,
        uint256 merchantId_,
        uint256 amount_,
        uint256 platformFee_,
        uint256 expiresAt_,
        VouchifyTypes.PaymentMethod paymentMethod_,
        string calldata externalTxId_
    ) external override onlyOnce {
        if (buyer_ == address(0)) revert VouchifyErrors.ZeroAddress();
        if (amount_ == 0) revert VouchifyErrors.InvalidAmount();
        if (expiresAt_ <= block.timestamp) revert VouchifyErrors.InvalidTimestamp();

        factory = msg.sender;
        _voucherId = voucherId_;
        _tokenId = tokenId_;
        _buyer = buyer_;
        _currentOwner = buyer_;
        _merchantId = merchantId_;
        _amount = amount_;
        _remainingAmount = amount_;
        _platformFee = platformFee_;
        _paymentMethod = paymentMethod_;
        _externalTxId = externalTxId_;
        _status = VouchifyTypes.EscrowStatus.PENDING;
        createdAt = block.timestamp;
        expiresAt = expiresAt_;
        
        _initialized = true;
    }

    // ============ State Changes ============
    
    /// @inheritdoc IVouchifyEscrow
    function activate() external override onlyFactory {
        if (_status != VouchifyTypes.EscrowStatus.PENDING) {
            revert VouchifyErrors.EscrowNotActive();
        }
        
        _status = VouchifyTypes.EscrowStatus.ACTIVE;
        activatedAt = block.timestamp;
        
        emit Activated(block.timestamp);
    }

    /// @inheritdoc IVouchifyEscrow
    function redeem(
        uint256 amount_,
        address redeemedBy_
    ) external override onlyFactory whenActive notExpired returns (uint256 remaining) {
        if (amount_ == 0) revert VouchifyErrors.InvalidAmount();
        if (amount_ > _remainingAmount) revert VouchifyErrors.RedemptionAmountExceedsRemaining();
        if (redeemedBy_ == address(0)) revert VouchifyErrors.ZeroAddress();
        
        _remainingAmount -= amount_;
        
        // Record redemption
        _redemptions.push(VouchifyTypes.Redemption({
            amount: amount_,
            timestamp: block.timestamp,
            redeemedBy: redeemedBy_
        }));
        
        // Update status
        if (_remainingAmount == 0) {
            _status = VouchifyTypes.EscrowStatus.REDEEMED;
            redeemedAt = block.timestamp;
        } else {
            _status = VouchifyTypes.EscrowStatus.PARTIALLY_REDEEMED;
        }
        
        emit Redeemed(amount_, _remainingAmount, redeemedBy_);
        
        return _remainingAmount;
    }

    /// @inheritdoc IVouchifyEscrow
    function refund() external override onlyFactory {
        if (_status == VouchifyTypes.EscrowStatus.REDEEMED) {
            revert VouchifyErrors.EscrowAlreadyRedeemed();
        }
        if (_status == VouchifyTypes.EscrowStatus.REFUNDED) {
            revert VouchifyErrors.EscrowAlreadyRefunded();
        }
        
        uint256 refundAmount = _remainingAmount;
        _remainingAmount = 0;
        _status = VouchifyTypes.EscrowStatus.REFUNDED;
        
        emit Refunded(refundAmount, _currentOwner);
    }

    /// @inheritdoc IVouchifyEscrow
    function expire() external override onlyFactory {
        if (block.timestamp < expiresAt) revert VouchifyErrors.EscrowNotExpired();
        if (_status == VouchifyTypes.EscrowStatus.REDEEMED) {
            revert VouchifyErrors.EscrowAlreadyRedeemed();
        }
        if (_status == VouchifyTypes.EscrowStatus.REFUNDED) {
            revert VouchifyErrors.EscrowAlreadyRefunded();
        }
        if (_status == VouchifyTypes.EscrowStatus.EXPIRED) {
            revert VouchifyErrors.EscrowExpired();
        }
        
        _status = VouchifyTypes.EscrowStatus.EXPIRED;
        
        emit Expired(block.timestamp);
    }

    /// @inheritdoc IVouchifyEscrow
    function extendExpiry(uint256 newExpiresAt, uint256 feeDeducted) external override onlyFactory {
        if (_status == VouchifyTypes.EscrowStatus.REDEEMED) {
            revert VouchifyErrors.EscrowAlreadyRedeemed();
        }
        if (_status == VouchifyTypes.EscrowStatus.REFUNDED) {
            revert VouchifyErrors.EscrowAlreadyRefunded();
        }
        if (newExpiresAt <= expiresAt) revert VouchifyErrors.InvalidTimestamp();
        if (feeDeducted > _remainingAmount) revert VouchifyErrors.InsufficientBalance();

        uint256 oldExpiresAt = expiresAt;
        expiresAt = newExpiresAt;
        _remainingAmount -= feeDeducted;

        // If escrow was expired, re-activate it
        if (_status == VouchifyTypes.EscrowStatus.EXPIRED) {
            _status = VouchifyTypes.EscrowStatus.ACTIVE;
        }

        emit ExpiryExtended(oldExpiresAt, newExpiresAt, feeDeducted);
    }

    /// @inheritdoc IVouchifyEscrow
    function syncOwner(address newOwner) external override onlyFactory {
        if (newOwner == address(0)) revert VouchifyErrors.ZeroAddress();
        
        address previousOwner = _currentOwner;
        _currentOwner = newOwner;
        
        emit OwnerSynced(previousOwner, newOwner);
    }

    // ============ View Functions ============
    
    /// @inheritdoc IVouchifyEscrow
    function getDetails() external view override returns (
        bytes32,
        address,
        uint256,
        uint256,
        uint256,
        VouchifyTypes.EscrowStatus,
        uint256
    ) {
        return (
            _voucherId,
            _buyer,
            _merchantId,
            _amount,
            _remainingAmount,
            _status,
            expiresAt
        );
    }

    /// @inheritdoc IVouchifyEscrow
    function voucherId() external view override returns (bytes32) {
        return _voucherId;
    }

    /// @inheritdoc IVouchifyEscrow
    function tokenId() external view override returns (uint256) {
        return _tokenId;
    }

    /// @inheritdoc IVouchifyEscrow
    function buyer() external view override returns (address) {
        return _buyer;
    }

    /// @inheritdoc IVouchifyEscrow
    function currentOwner() external view override returns (address) {
        return _currentOwner;
    }

    /// @inheritdoc IVouchifyEscrow
    function merchantId() external view override returns (uint256) {
        return _merchantId;
    }

    /// @inheritdoc IVouchifyEscrow
    function amount() external view override returns (uint256) {
        return _amount;
    }

    /// @inheritdoc IVouchifyEscrow
    function remainingAmount() external view override returns (uint256) {
        return _remainingAmount;
    }

    /// @inheritdoc IVouchifyEscrow
    function status() external view override returns (VouchifyTypes.EscrowStatus) {
        return _status;
    }

    /// @inheritdoc IVouchifyEscrow
    function isRedeemable() external view override returns (bool) {
        return (
            (_status == VouchifyTypes.EscrowStatus.ACTIVE || 
             _status == VouchifyTypes.EscrowStatus.PARTIALLY_REDEEMED) &&
            block.timestamp < expiresAt &&
            _remainingAmount > 0
        );
    }

    /// @inheritdoc IVouchifyEscrow
    function isExpired() external view override returns (bool) {
        return block.timestamp >= expiresAt;
    }

    /// @inheritdoc IVouchifyEscrow
    function getRedemptionCount() external view override returns (uint256) {
        return _redemptions.length;
    }

    /// @inheritdoc IVouchifyEscrow
    function getRedemption(uint256 index) external view override returns (VouchifyTypes.Redemption memory) {
        return _redemptions[index];
    }

    /// @notice Get payment method
    function paymentMethod() external view returns (VouchifyTypes.PaymentMethod) {
        return _paymentMethod;
    }

    /// @notice Get external transaction ID (Flutterwave reference)
    function externalTxId() external view returns (string memory) {
        return _externalTxId;
    }

    /// @notice Get platform fee
    function platformFee() external view returns (uint256) {
        return _platformFee;
    }
}
