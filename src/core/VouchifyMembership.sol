// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IVouchifyMembership } from "../interfaces/IVouchifyMembership.sol";
import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../libraries/VouchifyErrors.sol";

/// @title VouchifyMembership
/// @notice Clone template for per-membership pass. Each clone holds ONE membership's data.
/// @dev Deployed as minimal proxy (EIP-1167). Logic delegated to implementation.
contract VouchifyMembership is IVouchifyMembership {
    // ============ Constants ============

    /// @notice Version for upgrade tracking
    string public constant VERSION = "1.0.0";

    // ============ Immutable References ============

    /// @notice Factory that deployed this clone
    address public factory;

    // ============ Membership Data ============

    bytes32 private _membershipId;
    uint256 private _tokenId;
    address private _buyer;
    address private _currentOwner;
    uint256 private _merchantId;
    uint256 private _totalCredits;
    uint256 private _remainingCredits;
    uint256 private _platformFee;
    VouchifyTypes.PaymentMethod private _paymentMethod;
    string private _externalTxId;
    VouchifyTypes.MembershipStatus private _status;

    // ============ Timestamps ============

    uint256 public createdAt;
    uint256 public expiresAt;
    uint256 public activatedAt;

    // ============ Redemption History ============

    VouchifyTypes.CreditRedemption[] private _redemptions;

    // ============ Initialization Flag ============

    bool private _initialized;

    // ============ Modifiers ============

    modifier onlyFactory() {
        if (msg.sender != factory) revert VouchifyErrors.NotMembershipFactory();
        _;
    }

    modifier onlyOnce() {
        if (_initialized) revert VouchifyErrors.MembershipAlreadyInitialized();
        _;
    }

    modifier whenActive() {
        if (_status != VouchifyTypes.MembershipStatus.ACTIVE) {
            revert VouchifyErrors.MembershipNotActive();
        }
        _;
    }

    modifier notExpired() {
        if (block.timestamp >= expiresAt) revert VouchifyErrors.MembershipExpired();
        _;
    }

    // ============ Constructor ============

    /// @notice Constructor is empty - all state set via initialize()
    constructor() {
        // Implementation contract should not be initialized
        // Clones will call initialize()
    }

    // ============ Initialization ============

    /// @inheritdoc IVouchifyMembership
    function initialize(
        bytes32 membershipId_,
        uint256 tokenId_,
        address buyer_,
        uint256 merchantId_,
        uint256 totalCredits_,
        uint256 platformFee_,
        uint256 expiresAt_,
        VouchifyTypes.PaymentMethod paymentMethod_,
        string calldata externalTxId_
    ) external override onlyOnce {
        if (buyer_ == address(0)) revert VouchifyErrors.ZeroAddress();
        if (totalCredits_ == 0) revert VouchifyErrors.InvalidAmount();
        if (expiresAt_ <= block.timestamp) revert VouchifyErrors.InvalidTimestamp();

        factory = msg.sender;
        _membershipId = membershipId_;
        _tokenId = tokenId_;
        _buyer = buyer_;
        _currentOwner = buyer_;
        _merchantId = merchantId_;
        _totalCredits = totalCredits_;
        _remainingCredits = totalCredits_;
        _platformFee = platformFee_;
        _paymentMethod = paymentMethod_;
        _externalTxId = externalTxId_;
        _status = VouchifyTypes.MembershipStatus.PENDING;
        createdAt = block.timestamp;
        expiresAt = expiresAt_;

        _initialized = true;
    }

    // ============ State Changes ============

    /// @inheritdoc IVouchifyMembership
    function activate() external override onlyFactory {
        if (_status != VouchifyTypes.MembershipStatus.PENDING) {
            revert VouchifyErrors.MembershipNotActive();
        }

        _status = VouchifyTypes.MembershipStatus.ACTIVE;
        activatedAt = block.timestamp;

        emit Activated(block.timestamp);
    }

    /// @inheritdoc IVouchifyMembership
    function redeemCredit() external override onlyFactory whenActive notExpired returns (uint256 remaining) {
        if (_remainingCredits == 0) revert VouchifyErrors.NoCreditsRemaining();

        _remainingCredits -= 1;

        // Record redemption
        _redemptions.push(VouchifyTypes.CreditRedemption({
            timestamp: block.timestamp,
            redeemedBy: tx.origin // The merchant who initiated
        }));

        // Update status
        if (_remainingCredits == 0) {
            _status = VouchifyTypes.MembershipStatus.FULLY_USED;
        }

        emit CreditRedeemed(_remainingCredits, tx.origin);

        return _remainingCredits;
    }

    /// @inheritdoc IVouchifyMembership
    function expire() external override onlyFactory {
        if (block.timestamp < expiresAt) revert VouchifyErrors.MembershipExpired();
        if (_status == VouchifyTypes.MembershipStatus.FULLY_USED) {
            revert VouchifyErrors.NoCreditsRemaining();
        }
        if (_status == VouchifyTypes.MembershipStatus.EXPIRED) {
            revert VouchifyErrors.MembershipExpired();
        }

        _status = VouchifyTypes.MembershipStatus.EXPIRED;

        emit Expired(block.timestamp);
    }

    /// @inheritdoc IVouchifyMembership
    function syncOwner(address newOwner) external override onlyFactory {
        if (newOwner == address(0)) revert VouchifyErrors.ZeroAddress();

        address previousOwner = _currentOwner;
        _currentOwner = newOwner;

        emit OwnerSynced(previousOwner, newOwner);
    }

    // ============ View Functions ============

    /// @inheritdoc IVouchifyMembership
    function getDetails() external view override returns (
        bytes32,
        address,
        uint256,
        uint256,
        uint256,
        VouchifyTypes.MembershipStatus,
        uint256
    ) {
        return (
            _membershipId,
            _buyer,
            _merchantId,
            _totalCredits,
            _remainingCredits,
            _status,
            expiresAt
        );
    }

    /// @inheritdoc IVouchifyMembership
    function membershipId() external view override returns (bytes32) {
        return _membershipId;
    }

    /// @inheritdoc IVouchifyMembership
    function tokenId() external view override returns (uint256) {
        return _tokenId;
    }

    /// @inheritdoc IVouchifyMembership
    function buyer() external view override returns (address) {
        return _buyer;
    }

    /// @inheritdoc IVouchifyMembership
    function currentOwner() external view override returns (address) {
        return _currentOwner;
    }

    /// @inheritdoc IVouchifyMembership
    function merchantId() external view override returns (uint256) {
        return _merchantId;
    }

    /// @inheritdoc IVouchifyMembership
    function totalCredits() external view override returns (uint256) {
        return _totalCredits;
    }

    /// @inheritdoc IVouchifyMembership
    function remainingCredits() external view override returns (uint256) {
        return _remainingCredits;
    }

    /// @inheritdoc IVouchifyMembership
    function status() external view override returns (VouchifyTypes.MembershipStatus) {
        return _status;
    }

    /// @inheritdoc IVouchifyMembership
    function isRedeemable() external view override returns (bool) {
        return (
            _status == VouchifyTypes.MembershipStatus.ACTIVE &&
            block.timestamp < expiresAt &&
            _remainingCredits > 0
        );
    }

    /// @inheritdoc IVouchifyMembership
    function isExpired() external view override returns (bool) {
        return block.timestamp >= expiresAt;
    }

    /// @inheritdoc IVouchifyMembership
    function getRedemptionCount() external view override returns (uint256) {
        return _redemptions.length;
    }

    /// @inheritdoc IVouchifyMembership
    function getRedemption(uint256 index) external view override returns (VouchifyTypes.CreditRedemption memory) {
        return _redemptions[index];
    }

    /// @notice Get payment method
    function paymentMethod() external view returns (VouchifyTypes.PaymentMethod) {
        return _paymentMethod;
    }

    /// @notice Get external transaction ID
    function externalTxId() external view returns (string memory) {
        return _externalTxId;
    }

    /// @notice Get platform fee
    function platformFee() external view returns (uint256) {
        return _platformFee;
    }
}
