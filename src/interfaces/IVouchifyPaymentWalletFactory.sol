// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";

/// @title IVouchifyPaymentWalletFactory
/// @notice Interface for factory that deploys payment wallet clones
interface IVouchifyPaymentWalletFactory {
    // ============ Events ============

    /// @notice Emitted when a new payment wallet is created
    event PaymentWalletCreated(
        bytes32 indexed paymentId,
        address indexed walletAddress,
        address indexed token,
        uint256 expectedAmount,
        address buyer
    );

    /// @notice Emitted when a wallet is swept
    event WalletSwept(bytes32 indexed paymentId, address indexed wallet, address indexed coldWallet, uint256 amount);

    /// @notice Emitted when implementation is updated
    event ImplementationUpdated(address indexed oldImplementation, address indexed newImplementation);

    /// @notice Emitted when cold wallet is updated
    event ColdWalletUpdated(address indexed oldWallet, address indexed newWallet);

    // ============ Core Functions ============

    /// @notice Create a new payment wallet for receiving crypto
    /// @param paymentId Unique payment identifier
    /// @param token Token address (USDC or USDT)
    /// @param expectedAmount Expected amount to receive (in token decimals)
    /// @param buyer Address of the buyer making the payment
    /// @return walletAddress Address of the newly created payment wallet
    function createPaymentWallet(
        bytes32 paymentId,
        address token,
        uint256 expectedAmount,
        address buyer
    ) external returns (address walletAddress);

    /// @notice Sweep a wallet to cold storage
    /// @param paymentId Payment ID
    function sweepWallet(bytes32 paymentId) external;

    /// @notice Batch sweep multiple wallets
    /// @param paymentIds Array of payment IDs to sweep
    function sweepBatch(bytes32[] calldata paymentIds) external;

    // ============ Admin Functions ============

    /// @notice Update the implementation contract
    /// @param newImplementation Address of new implementation
    function setImplementation(address newImplementation) external;

    /// @notice Update the cold wallet address
    /// @param newColdWallet Address of new cold wallet
    function setColdWallet(address newColdWallet) external;

    /// @notice Pause the factory
    function pause() external;

    /// @notice Unpause the factory
    function unpause() external;

    // ============ View Functions ============

    /// @notice Get wallet address for a payment ID
    /// @param paymentId Payment ID
    /// @return Wallet address (predicted via CREATE2)
    function getWalletAddress(bytes32 paymentId) external view returns (address);

    /// @notice Get wallet stored for a payment ID
    /// @param paymentId Payment ID
    /// @return Wallet address (if created)
    function getWallet(bytes32 paymentId) external view returns (address);

    /// @notice Get implementation address
    function implementation() external view returns (address);

    /// @notice Get cold wallet address
    function coldWallet() external view returns (address);

    /// @notice Get total wallets created
    function totalWallets() external view returns (uint256);

    /// @notice Check if wallet exists
    function walletExists(bytes32 paymentId) external view returns (bool);
}
