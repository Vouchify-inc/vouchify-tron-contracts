// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title VouchifyTypes
/// @notice Shared types and enums used across Vouchify contracts
library VouchifyTypes {
    /// @notice Payment methods supported by the platform
    enum PaymentMethod {
        FIAT,   // Paid via Flutterwave (Card, Mobile Money, Bank Transfer)
        USDC,   // Paid with USDC stablecoin
        USDT    // Paid with USDT stablecoin
    }

    /// @notice Status of an escrow/voucher
    enum EscrowStatus {
        PENDING,            // Created, awaiting payment confirmation
        ACTIVE,             // Payment confirmed, voucher is valid
        PARTIALLY_REDEEMED, // Some value has been used
        REDEEMED,           // Fully redeemed (remaining = 0)
        REFUNDED,           // Refunded to buyer
        EXPIRED             // Past expiry date, not redeemed
    }

    /// @notice Record of a partial redemption
    struct Redemption {
        uint256 amount;         // Amount redeemed in this transaction
        uint256 timestamp;      // When redemption occurred
        address redeemedBy;     // Merchant address who processed
    }

    /// @notice Metadata stored for each voucher NFT
    struct VoucherMetadata {
        address escrowAddress;  // Link to escrow clone
        uint256 merchantId;     // Off-chain merchant ID
        uint256 originalAmount; // Purchase amount (in smallest unit)
        uint256 purchasedAt;    // Timestamp of purchase
        uint256 expiresAt;      // Expiry timestamp
        bool isGift;            // Was this gifted to someone?
        address originalBuyer;  // Original purchaser address
    }

    /// @notice Merchant record for on-chain registry
    struct MerchantRecord {
        uint256 merchantId;         // Off-chain database ID
        address walletAddress;      // Verified wallet for payouts
        bool isVerified;            // KYB approved
        bool isActive;              // Can receive vouchers
        uint256 totalEarned;        // Lifetime earnings (smallest unit)
        uint256 pendingBalance;     // Available for withdrawal
        uint256 withdrawnTotal;     // Total withdrawn
        uint256 registeredAt;       // Registration timestamp
    }

    /// @notice Parameters for creating a new escrow
    struct CreateEscrowParams {
        bytes32 voucherId;          // Unique voucher identifier
        address buyer;              // Buyer's wallet address
        uint256 merchantId;         // Off-chain merchant ID
        uint256 amount;             // Total amount (smallest unit)
        uint256 platformFee;        // Platform fee amount
        uint256 expiresAt;          // Expiry timestamp
        PaymentMethod paymentMethod;// How it was paid
        string externalTxId;        // External payment reference (e.g., Flutterwave tx ID)
        bool isGift;                // Is this a gift voucher?
    }

    // ============ Membership Types ============

    /// @notice Status of a membership pass
    enum MembershipStatus {
        PENDING,        // Created, awaiting payment confirmation
        ACTIVE,         // Payment confirmed, membership is valid
        FULLY_USED,     // All credits have been redeemed
        EXPIRED         // Past expiry date
    }

    /// @notice Record of a single credit redemption
    struct CreditRedemption {
        uint256 timestamp;      // When redemption occurred
        address redeemedBy;     // Address who processed the redemption
    }

    /// @notice Parameters for creating a new membership pass
    struct CreateMembershipParams {
        bytes32 membershipId;       // Unique membership identifier
        address buyer;              // Buyer's wallet address
        uint256 merchantId;         // Off-chain merchant ID
        uint256 totalCredits;       // Total number of credits
        uint256 platformFee;        // Platform fee amount
        uint256 expiresAt;          // Expiry timestamp
        PaymentMethod paymentMethod;// How it was paid
        string externalTxId;        // External payment reference (e.g., Flutterwave tx ID)
    }
}
