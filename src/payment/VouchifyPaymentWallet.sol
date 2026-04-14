// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IVouchifyPaymentWallet } from "../interfaces/IVouchifyPaymentWallet.sol";
import { VouchifyErrors } from "../libraries/VouchifyErrors.sol";

/// @title VouchifyPaymentWallet
/// @notice Minimal wallet for receiving crypto payments (USDC/USDT)
/// @dev Deployed as EIP-1167 clone via VouchifyPaymentWalletFactory
contract VouchifyPaymentWallet is IVouchifyPaymentWallet {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    /// @notice Factory that created this wallet
    address private _factory;

    /// @notice Unique payment identifier
    bytes32 private _paymentId;

    /// @notice Token address (USDC or USDT)
    address private _token;

    /// @notice Expected amount to receive
    uint256 private _expectedAmount;

    /// @notice Address of the buyer making payment
    address private _buyer;

    /// @notice Whether this wallet has been swept
    bool private _swept;

    /// @notice Whether initialization has been called
    bool private _initialized;

    // ============ Constructor ============

    constructor() {
        // Implementation contract, disabled initialization
        _initialized = true;
    }

    // ============ Initialization ============

    /// @inheritdoc IVouchifyPaymentWallet
    function initialize(
        address factory_,
        bytes32 paymentId_,
        address token_,
        uint256 expectedAmount_,
        address buyer_
    ) external {
        if (_initialized) revert VouchifyErrors.AlreadyInitialized();
        if (factory_ == address(0)) revert VouchifyErrors.ZeroAddress();
        if (token_ == address(0)) revert VouchifyErrors.ZeroAddress();
        if (expectedAmount_ == 0) revert VouchifyErrors.InvalidAmount();
        if (buyer_ == address(0)) revert VouchifyErrors.ZeroAddress();

        _factory = factory_;
        _paymentId = paymentId_;
        _token = token_;
        _expectedAmount = expectedAmount_;
        _buyer = buyer_;
        _swept = false;
        _initialized = true;
    }

    // ============ Core Functions ============

    /// @inheritdoc IVouchifyPaymentWallet
    function getBalance() external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @inheritdoc IVouchifyPaymentWallet
    function sweep(address coldWallet) external {
        if (msg.sender != _factory) revert VouchifyErrors.Unauthorized();
        if (coldWallet == address(0)) revert VouchifyErrors.ZeroAddress();
        if (_swept) revert VouchifyErrors.WalletAlreadySwept();

        _swept = true;

        // Get current balance
        uint256 balance = IERC20(_token).balanceOf(address(this));

        // Transfer to cold wallet
        if (balance > 0) {
            IERC20(_token).safeTransfer(coldWallet, balance);
        }

        emit Swept(_token, coldWallet, balance);
    }

    // ============ View Functions ============

    /// @inheritdoc IVouchifyPaymentWallet
    function isPaymentReceived() external view returns (bool) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        return balance >= _expectedAmount;
    }

    /// @inheritdoc IVouchifyPaymentWallet
    function isSwept() external view returns (bool) {
        return _swept;
    }

    /// @inheritdoc IVouchifyPaymentWallet
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
        )
    {
        currentBalance = IERC20(_token).balanceOf(address(this));
        paymentReceived = currentBalance >= _expectedAmount;

        return (_paymentId, _token, _expectedAmount, currentBalance, paymentReceived, _swept, _buyer);
    }

    // ============ Helper Functions ============

    /// @notice Get factory address
    function factory() external view returns (address) {
        return _factory;
    }

    /// @notice Get payment ID
    function paymentId() external view returns (bytes32) {
        return _paymentId;
    }

    /// @notice Get token address
    function getToken() external view returns (address) {
        return _token;
    }

    /// @notice Get expected amount
    function expectedAmount() external view returns (uint256) {
        return _expectedAmount;
    }

    /// @notice Get buyer address
    function buyer() external view returns (address) {
        return _buyer;
    }

    /// @notice Check if initialized
    function initialized() external view returns (bool) {
        return _initialized;
    }
}
