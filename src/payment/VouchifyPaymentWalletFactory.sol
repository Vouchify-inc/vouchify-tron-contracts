// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IVouchifyPaymentWalletFactory } from "../interfaces/IVouchifyPaymentWalletFactory.sol";
import { IVouchifyPaymentWallet } from "../interfaces/IVouchifyPaymentWallet.sol";
import { VouchifyErrors } from "../libraries/VouchifyErrors.sol";

/// @title VouchifyPaymentWalletFactory
/// @notice Factory contract that deploys minimal proxy clones for crypto payment wallets
/// @dev Uses EIP-1167 (OpenZeppelin Clones) for gas-efficient deployment of payment wallets
contract VouchifyPaymentWalletFactory is IVouchifyPaymentWalletFactory, AccessControl, Pausable, ReentrancyGuard {
    using Clones for address;

    // ============ Constants ============

    /// @notice Role for operators who can create payment wallets
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Role for pausing the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Version for upgrade tracking
    string public constant VERSION = "1.0.0";

    // ============ State Variables ============

    /// @notice Address of the payment wallet implementation contract
    address private _implementation;

    /// @notice Address of the cold storage wallet (multi-sig)
    address private _coldWallet;

    /// @notice Mapping: paymentId => payment wallet clone address
    mapping(bytes32 => address) private _walletsByPaymentId;

    /// @notice Total number of payment wallets created
    uint256 private _totalWallets;

    // ============ Constructor ============

    /// @notice Initialize the factory with implementation and admin
    /// @param implementation_ Address of the VouchifyPaymentWallet implementation
    /// @param coldWallet_ Address of the cold storage wallet (multi-sig)
    /// @param admin Address of the default admin
    /// @param operator Address that can create payment wallets
    /// @param pauser Address that can pause/unpause the contract
    constructor(
        address implementation_,
        address coldWallet_,
        address admin,
        address operator,
        address pauser
    ) {
        if (implementation_ == address(0)) revert VouchifyErrors.ZeroAddress();
        if (coldWallet_ == address(0)) revert VouchifyErrors.ZeroAddress();
        if (admin == address(0)) revert VouchifyErrors.ZeroAddress();
        if (operator == address(0)) revert VouchifyErrors.ZeroAddress();
        if (pauser == address(0)) revert VouchifyErrors.ZeroAddress();

        _implementation = implementation_;
        _coldWallet = coldWallet_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, operator);
        _grantRole(PAUSER_ROLE, pauser);
    }

    // ============ Core Functions ============

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function createPaymentWallet(
        bytes32 paymentId,
        address token,
        uint256 expectedAmount,
        address buyer
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant returns (address walletAddress) {
        // Validate inputs
        if (token == address(0)) revert VouchifyErrors.ZeroAddress();
        if (expectedAmount == 0) revert VouchifyErrors.InvalidAmount();
        if (buyer == address(0)) revert VouchifyErrors.ZeroAddress();
        if (_walletsByPaymentId[paymentId] != address(0)) {
            revert VouchifyErrors.AlreadyInitialized();
        }

        // Deploy clone using CREATE2 for deterministic address
        walletAddress = _implementation.cloneDeterministic(paymentId);

        // Initialize the wallet clone
        IVouchifyPaymentWallet(walletAddress).initialize(address(this), paymentId, token, expectedAmount, buyer);

        // Store mapping
        _walletsByPaymentId[paymentId] = walletAddress;
        _totalWallets++;

        emit PaymentWalletCreated(paymentId, walletAddress, token, expectedAmount, buyer);

        return walletAddress;
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function sweepWallet(bytes32 paymentId) external override onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        address walletAddress = _walletsByPaymentId[paymentId];
        if (walletAddress == address(0)) revert VouchifyErrors.ZeroAddress();

        address token = IVouchifyPaymentWallet(walletAddress).getToken();
        uint256 amount = IVouchifyPaymentWallet(walletAddress).getBalance();

        IVouchifyPaymentWallet(walletAddress).sweep(_coldWallet);

        emit WalletSwept(paymentId, walletAddress, _coldWallet, amount);
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function sweepBatch(bytes32[] calldata paymentIds) external override onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        for (uint256 i = 0; i < paymentIds.length; i++) {
            bytes32 paymentId = paymentIds[i];
            address walletAddress = _walletsByPaymentId[paymentId];

            if (walletAddress != address(0)) {
                address token = IVouchifyPaymentWallet(walletAddress).getToken();
                uint256 amount = IVouchifyPaymentWallet(walletAddress).getBalance();

                IVouchifyPaymentWallet(walletAddress).sweep(_coldWallet);

                emit WalletSwept(paymentId, walletAddress, _coldWallet, amount);
            }
        }
    }

    // ============ Admin Functions ============

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function setImplementation(address newImplementation) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newImplementation == address(0)) revert VouchifyErrors.ZeroAddress();

        address oldImpl = _implementation;
        _implementation = newImplementation;

        emit ImplementationUpdated(oldImpl, newImplementation);
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function setColdWallet(address newColdWallet) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newColdWallet == address(0)) revert VouchifyErrors.ZeroAddress();

        address oldWallet = _coldWallet;
        _coldWallet = newColdWallet;

        emit ColdWalletUpdated(oldWallet, newColdWallet);
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function pause() external override onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function unpause() external override onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ============ View Functions ============

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function getWalletAddress(bytes32 paymentId) external view override returns (address) {
        return _implementation.predictDeterministicAddress(paymentId, address(this));
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function getWallet(bytes32 paymentId) external view override returns (address) {
        return _walletsByPaymentId[paymentId];
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function implementation() external view override returns (address) {
        return _implementation;
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function coldWallet() external view override returns (address) {
        return _coldWallet;
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function totalWallets() external view override returns (uint256) {
        return _totalWallets;
    }

    /// @inheritdoc IVouchifyPaymentWalletFactory
    function walletExists(bytes32 paymentId) external view override returns (bool) {
        return _walletsByPaymentId[paymentId] != address(0);
    }
}
