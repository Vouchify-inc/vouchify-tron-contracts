// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IVouchifyPaymentWallet
/// @notice Interface for temporary payment wallets that receive crypto (USDC/USDT)
interface IVouchifyPaymentWallet {
    // ============ Events ============

    /// @notice Emitted when payment is received
    event PaymentReceived(address indexed token, uint256 amount, address indexed from);

    /// @notice Emitted when wallet is swept to cold storage
    event Swept(address indexed token, address indexed coldWallet, uint256 amount);

    // ============ Core Functions ============

    /// @notice Initialize the payment wallet (called by factory after cloning)
    /// @param factory_ Address of the factory that created this wallet
    /// @param paymentId_ Unique payment identifier
    /// @param token_ Token address (USDC or USDT)
    /// @param expectedAmount_ Expected amount to receive
    /// @param buyer_ Address of the buyer initiating payment
    function initialize(
        address factory_,
        bytes32 paymentId_,
        address token_,
        uint256 expectedAmount_,
        address buyer_
    ) external;

    /// @notice Get current balance of the expected token
    /// @return Balance of the token in this wallet
    function getBalance() external view returns (uint256);

    /// @notice Sweep funds to cold wallet (only factory can call)
    /// @param coldWallet Address to sweep funds to
    function sweep(address coldWallet) external;

    // ============ View Functions ============

    /// @notice Check if wallet has received payment
    /// @return True if balance >= expectedAmount
    function isPaymentReceived() external view returns (bool);

    /// @notice Check if wallet has been swept
    /// @return True if funds have been swept
    function isSwept() external view returns (bool);

    /// @notice Get payment details
    function getDetails()
        external
        view
        returns (
            bytes32 id,
            address tokenAddr,
            uint256 expectedAmt,
            uint256 currentBalance,
            bool paymentReceived,
            bool swept,
            address buyerAddr
        );

    /// @notice Get token address
    function getToken() external view returns (address);
}
