// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";

/// @title IVouchifyEscrow
/// @notice Interface for individual escrow clones (one per voucher)
interface IVouchifyEscrow {
    // ============ Events ============
    
    /// @notice Emitted when escrow is activated (payment confirmed)
    event Activated(uint256 timestamp);
    
    /// @notice Emitted when voucher is redeemed (full or partial)
    event Redeemed(uint256 amount, uint256 remaining, address indexed redeemedBy);
    
    /// @notice Emitted when voucher is refunded
    event Refunded(uint256 amount, address indexed refundedTo);
    
    /// @notice Emitted when voucher expires
    event Expired(uint256 timestamp);
    
    /// @notice Emitted when owner is synced from NFT transfer
    event OwnerSynced(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when the escrow expiry is extended
    event ExpiryExtended(uint256 oldExpiresAt, uint256 newExpiresAt, uint256 feeDeducted);

    // ============ Initialization ============
    
    /// @notice Initialize the escrow clone (called once by factory)
    /// @param voucherId Unique voucher identifier
    /// @param tokenId NFT token ID
    /// @param buyer Original buyer address
    /// @param merchantId Off-chain merchant ID
    /// @param amount Total amount in smallest unit
    /// @param platformFee Platform fee amount
    /// @param expiresAt Expiry timestamp
    /// @param paymentMethod How the voucher was paid
    /// @param externalTxId External payment reference
    function initialize(
        bytes32 voucherId,
        uint256 tokenId,
        address buyer,
        uint256 merchantId,
        uint256 amount,
        uint256 platformFee,
        uint256 expiresAt,
        VouchifyTypes.PaymentMethod paymentMethod,
        string calldata externalTxId
    ) external;

    // ============ State Changes ============
    
    /// @notice Activate the escrow (payment confirmed)
    function activate() external;
    
    /// @notice Redeem voucher (full or partial)
    /// @param amount Amount to redeem
    /// @return remaining Amount remaining after redemption
    function redeem(uint256 amount) external returns (uint256 remaining);
    
    /// @notice Refund the voucher to buyer
    function refund() external;
    
    /// @notice Mark voucher as expired
    function expire() external;
    
    /// @notice Sync current owner when NFT is transferred
    /// @param newOwner New owner address
    function syncOwner(address newOwner) external;

    /// @notice Extend the escrow expiry date and deduct extension fee
    /// @param newExpiresAt New expiry timestamp (must be > current expiresAt)
    /// @param feeDeducted Fee to deduct from remaining balance (in smallest unit)
    function extendExpiry(uint256 newExpiresAt, uint256 feeDeducted) external;

    // ============ View Functions ============
    
    /// @notice Get escrow details
    function getDetails() external view returns (
        bytes32 voucherId,
        address buyer,
        uint256 merchantId,
        uint256 amount,
        uint256 remainingAmount,
        VouchifyTypes.EscrowStatus status,
        uint256 expiresAt
    );
    
    /// @notice Get the voucher ID
    function voucherId() external view returns (bytes32);
    
    /// @notice Get the NFT token ID
    function tokenId() external view returns (uint256);
    
    /// @notice Get the original buyer
    function buyer() external view returns (address);
    
    /// @notice Get the current owner (may differ from buyer if gifted/transferred)
    function currentOwner() external view returns (address);
    
    /// @notice Get the merchant ID
    function merchantId() external view returns (uint256);
    
    /// @notice Get the original amount
    function amount() external view returns (uint256);
    
    /// @notice Get remaining amount
    function remainingAmount() external view returns (uint256);
    
    /// @notice Get current status
    function status() external view returns (VouchifyTypes.EscrowStatus);
    
    /// @notice Check if voucher is redeemable
    function isRedeemable() external view returns (bool);
    
    /// @notice Check if voucher is expired
    function isExpired() external view returns (bool);
    
    /// @notice Get redemption count
    function getRedemptionCount() external view returns (uint256);
    
    /// @notice Get specific redemption record
    function getRedemption(uint256 index) external view returns (VouchifyTypes.Redemption memory);
}
