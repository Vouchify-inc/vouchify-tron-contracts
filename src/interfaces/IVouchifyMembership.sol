// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";

/// @title IVouchifyMembership
/// @notice Interface for individual membership clones (one per membership pass)
interface IVouchifyMembership {
    // ============ Events ============

    /// @notice Emitted when membership is activated (payment confirmed)
    event Activated(uint256 timestamp);

    /// @notice Emitted when a credit is redeemed
    event CreditRedeemed(uint256 remainingCredits, address indexed redeemedBy);

    /// @notice Emitted when membership expires
    event Expired(uint256 timestamp);

    /// @notice Emitted when owner is synced from NFT transfer
    event OwnerSynced(address indexed previousOwner, address indexed newOwner);

    // ============ Initialization ============

    /// @notice Initialize the membership clone (called once by factory)
    /// @param membershipId Unique membership identifier
    /// @param tokenId NFT token ID
    /// @param buyer Original buyer address
    /// @param merchantId Off-chain merchant ID
    /// @param totalCredits Total number of credits
    /// @param platformFee Platform fee amount
    /// @param expiresAt Expiry timestamp
    /// @param paymentMethod How the membership was paid
    /// @param externalTxId External payment reference
    function initialize(
        bytes32 membershipId,
        uint256 tokenId,
        address buyer,
        uint256 merchantId,
        uint256 totalCredits,
        uint256 platformFee,
        uint256 expiresAt,
        VouchifyTypes.PaymentMethod paymentMethod,
        string calldata externalTxId
    ) external;

    // ============ State Changes ============

    /// @notice Activate the membership (payment confirmed)
    function activate() external;

    /// @notice Redeem one credit from the membership
    /// @param redeemedBy Operator address responsible for the redemption
    /// @return remaining Number of credits remaining after redemption
    function redeemCredit(address redeemedBy) external returns (uint256 remaining);

    /// @notice Mark membership as expired
    function expire() external;

    /// @notice Sync current owner when NFT is transferred
    /// @param newOwner New owner address
    function syncOwner(address newOwner) external;

    // ============ View Functions ============

    /// @notice Get membership details
    function getDetails() external view returns (
        bytes32 membershipId,
        address buyer,
        uint256 merchantId,
        uint256 totalCredits,
        uint256 remainingCredits,
        VouchifyTypes.MembershipStatus status,
        uint256 expiresAt
    );

    /// @notice Get the membership ID
    function membershipId() external view returns (bytes32);

    /// @notice Get the NFT token ID
    function tokenId() external view returns (uint256);

    /// @notice Get the original buyer
    function buyer() external view returns (address);

    /// @notice Get the current owner (may differ from buyer if transferred)
    function currentOwner() external view returns (address);

    /// @notice Get the merchant ID
    function merchantId() external view returns (uint256);

    /// @notice Get the total credits
    function totalCredits() external view returns (uint256);

    /// @notice Get remaining credits
    function remainingCredits() external view returns (uint256);

    /// @notice Get current status
    function status() external view returns (VouchifyTypes.MembershipStatus);

    /// @notice Check if membership is redeemable
    function isRedeemable() external view returns (bool);

    /// @notice Check if membership is expired
    function isExpired() external view returns (bool);

    /// @notice Get redemption count
    function getRedemptionCount() external view returns (uint256);

    /// @notice Get specific credit redemption record
    function getRedemption(uint256 index) external view returns (VouchifyTypes.CreditRedemption memory);

    /// @notice Get payment method
    function paymentMethod() external view returns (VouchifyTypes.PaymentMethod);

    /// @notice Get external transaction ID
    function externalTxId() external view returns (string memory);

    /// @notice Get platform fee
    function platformFee() external view returns (uint256);
}
