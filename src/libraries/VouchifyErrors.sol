// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title VouchifyErrors
/// @notice Custom errors for Vouchify contracts (gas efficient)
library VouchifyErrors {
    // ============ General Errors ============
    error Unauthorized();
    error ZeroAddress();
    error InvalidAmount();
    error InvalidTimestamp();

    // ============ Escrow Errors ============
    error EscrowAlreadyExists();
    error EscrowNotFound();
    error EscrowNotActive();
    error EscrowAlreadyRedeemed();
    error EscrowExpired();
    error EscrowNotExpired();
    error EscrowAlreadyRefunded();
    error InsufficientBalance();
    error RedemptionAmountExceedsRemaining();
    error AlreadyInitialized();
    error NotFactory();

    // ============ Voucher NFT Errors ============
    error VoucherNotFound();
    error VoucherAlreadyBurned();
    error NotVoucherOwner();
    error VoucherNotTransferable();

    // ============ Merchant Errors ============
    error MerchantAlreadyRegistered();
    error MerchantNotFound();
    error MerchantNotVerified();
    error MerchantNotActive();
    error MerchantWalletMismatch();
    error WithdrawalExceedsBalance();

    // ============ Factory Errors ============
    error ImplementationNotSet();
    error CloneDeploymentFailed();
    error VoucherContractNotSet();

    // ============ Payment Wallet Errors ============
    error WalletAlreadySwept();
    error InsufficientPayment();
    error PaymentExpired();
    error InvalidToken();

    // ============ Membership Errors ============
    error MembershipNotFound();
    error MembershipNotActive();
    error MembershipExpired();
    error MembershipAlreadyExists();
    error NoCreditsRemaining();
    error MembershipAlreadyInitialized();
    error NotMembershipFactory();
}
