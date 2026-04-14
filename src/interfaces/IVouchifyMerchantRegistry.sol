// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";

/// @title IVouchifyMerchantRegistry
/// @notice Interface for on-chain merchant registry with balance tracking
interface IVouchifyMerchantRegistry {
    // ============ Events ============
    
    /// @notice Emitted when a merchant is registered
    event MerchantRegistered(
        uint256 indexed merchantId,
        address indexed wallet,
        uint256 timestamp
    );

    /// @notice Emitted when a merchant is verified (KYB approved)
    event MerchantVerified(uint256 indexed merchantId, uint256 timestamp);

    /// @notice Emitted when a merchant is deactivated
    event MerchantDeactivated(uint256 indexed merchantId, uint256 timestamp);

    /// @notice Emitted when a merchant is reactivated
    event MerchantActivated(uint256 indexed merchantId, uint256 timestamp);

    /// @notice Emitted when merchant wallet is updated
    event MerchantWalletUpdated(
        uint256 indexed merchantId,
        address indexed oldWallet,
        address indexed newWallet
    );

    /// @notice Emitted when balance is credited (redemption)
    event BalanceCredited(
        uint256 indexed merchantId,
        uint256 amount,
        bytes32 indexed voucherId,
        uint256 newBalance
    );

    /// @notice Emitted when balance is debited (withdrawal)
    event BalanceDebited(
        uint256 indexed merchantId,
        uint256 amount,
        string reason,
        uint256 newBalance
    );

    // ============ Admin Functions ============
    
    /// @notice Register a new merchant
    /// @param merchantId Off-chain database ID
    /// @param wallet Merchant's verified wallet address
    function registerMerchant(uint256 merchantId, address wallet) external;

    /// @notice Mark merchant as KYB verified
    /// @param merchantId Merchant ID
    function verifyMerchant(uint256 merchantId) external;

    /// @notice Deactivate a merchant
    /// @param merchantId Merchant ID
    function deactivateMerchant(uint256 merchantId) external;

    /// @notice Reactivate a merchant
    /// @param merchantId Merchant ID
    function activateMerchant(uint256 merchantId) external;

    /// @notice Update merchant wallet address
    /// @param merchantId Merchant ID
    /// @param newWallet New wallet address
    function updateMerchantWallet(uint256 merchantId, address newWallet) external;

    // ============ Balance Functions ============
    
    /// @notice Credit balance to merchant (on voucher redemption)
    /// @param merchantId Merchant ID
    /// @param amount Amount to credit
    /// @param voucherId Associated voucher ID
    function creditBalance(uint256 merchantId, uint256 amount, bytes32 voucherId) external;

    /// @notice Debit balance from merchant (on withdrawal)
    /// @param merchantId Merchant ID
    /// @param amount Amount to debit
    /// @param reason Reason for debit (e.g., "withdrawal", "adjustment")
    function debitBalance(uint256 merchantId, uint256 amount, string calldata reason) external;

    // ============ View Functions ============
    
    /// @notice Get merchant record
    /// @param merchantId Merchant ID
    /// @return Merchant record struct
    function getMerchant(uint256 merchantId) external view returns (VouchifyTypes.MerchantRecord memory);

    /// @notice Get merchant ID by wallet address
    /// @param wallet Wallet address
    /// @return merchantId
    function getMerchantByWallet(address wallet) external view returns (uint256);

    /// @notice Check if merchant is verified and active
    /// @param merchantId Merchant ID
    /// @return True if can receive vouchers
    function isMerchantActive(uint256 merchantId) external view returns (bool);

    /// @notice Get merchant's pending balance
    /// @param merchantId Merchant ID
    /// @return Pending balance
    function getPendingBalance(uint256 merchantId) external view returns (uint256);

    /// @notice Get total registered merchants
    function totalMerchants() external view returns (uint256);
}
