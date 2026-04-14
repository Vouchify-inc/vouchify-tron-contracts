// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IVouchifyEscrowFactory } from "../interfaces/IVouchifyEscrowFactory.sol";
import { IVouchifyEscrow } from "../interfaces/IVouchifyEscrow.sol";
import { IVouchifyVoucher } from "../interfaces/IVouchifyVoucher.sol";
import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../libraries/VouchifyErrors.sol";

/// @title VouchifyEscrowFactory
/// @notice Factory contract that deploys minimal proxy clones for each voucher
/// @dev Uses EIP-1167 (OpenZeppelin Clones) for gas-efficient deployment
contract VouchifyEscrowFactory is IVouchifyEscrowFactory, AccessControl, Pausable, ReentrancyGuard {
    using Clones for address;

    // ============ Constants ============
    
    /// @notice Role for operators who can create escrows
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    /// @notice Role for pausing the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Version for upgrade tracking
    string public constant VERSION = "1.0.0";

    // ============ State Variables ============
    
    /// @notice Address of the escrow implementation contract
    address private _implementation;
    
    /// @notice Address of the VouchifyVoucher NFT contract
    address private _voucherContract;
    
    /// @notice Mapping: voucherId => escrow clone address
    mapping(bytes32 => address) private _escrowsByVoucherId;
    
    /// @notice Mapping: tokenId => escrow clone address
    mapping(uint256 => address) private _escrowsByTokenId;
    
    /// @notice Total number of escrows created
    uint256 private _totalEscrows;

    // ============ Constructor ============
    
    /// @notice Initialize the factory with implementation, admin, operator, and pauser
    /// @param implementation_ Address of the VouchifyEscrow implementation
    /// @param admin Address of the default admin
    /// @param operator Address that can create and manage escrows
    /// @param pauser Address that can pause/unpause the contract
    constructor(address implementation_, address admin, address operator, address pauser) {
        if (implementation_ == address(0)) revert VouchifyErrors.ZeroAddress();
        if (admin == address(0)) revert VouchifyErrors.ZeroAddress();
        if (operator == address(0)) revert VouchifyErrors.ZeroAddress();
        if (pauser == address(0)) revert VouchifyErrors.ZeroAddress();
        
        _implementation = implementation_;
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, operator);
        _grantRole(PAUSER_ROLE, pauser);
    }

    // ============ Core Functions ============
    
    /// @inheritdoc IVouchifyEscrowFactory
    function createEscrow(
        VouchifyTypes.CreateEscrowParams calldata params
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant returns (
        address escrowAddress,
        uint256 tokenId
    ) {
        // Validate inputs
        if (params.buyer == address(0)) revert VouchifyErrors.ZeroAddress();
        if (params.amount == 0) revert VouchifyErrors.InvalidAmount();
        if (params.expiresAt <= block.timestamp) revert VouchifyErrors.InvalidTimestamp();
        if (_escrowsByVoucherId[params.voucherId] != address(0)) {
            revert VouchifyErrors.EscrowAlreadyExists();
        }
        if (_voucherContract == address(0)) revert VouchifyErrors.VoucherContractNotSet();
        
        // Deploy clone using CREATE2 for deterministic address
        escrowAddress = _implementation.cloneDeterministic(params.voucherId);
        
        // Mint the voucher NFT first to get tokenId
        tokenId = IVouchifyVoucher(_voucherContract).mint(
            params.buyer,
            escrowAddress,
            params.merchantId,
            params.amount,
            params.expiresAt,
            params.isGift
        );
        
        // Initialize the escrow clone
        IVouchifyEscrow(escrowAddress).initialize(
            params.voucherId,
            tokenId,
            params.buyer,
            params.merchantId,
            params.amount,
            params.platformFee,
            params.expiresAt,
            params.paymentMethod,
            params.externalTxId
        );
        
        // Activate immediately (payment already confirmed by backend)
        IVouchifyEscrow(escrowAddress).activate();
        
        // Store mappings
        _escrowsByVoucherId[params.voucherId] = escrowAddress;
        _escrowsByTokenId[tokenId] = escrowAddress;
        _totalEscrows++;
        
        emit EscrowCreated(
            params.voucherId,
            escrowAddress,
            tokenId,
            params.buyer,
            params.merchantId,
            params.amount
        );
    }

    /// @notice Redeem a voucher (called by backend after merchant verification)
    /// @param voucherId Voucher ID
    /// @param amount Amount to redeem
    /// @return remaining Amount remaining after redemption
    function redeemVoucher(
        bytes32 voucherId,
        uint256 amount
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant returns (uint256 remaining) {
        address escrowAddress = _escrowsByVoucherId[voucherId];
        if (escrowAddress == address(0)) revert VouchifyErrors.EscrowNotFound();
        
        remaining = IVouchifyEscrow(escrowAddress).redeem(amount, msg.sender);
        
        // Record redemption on NFT
        uint256 tokenId_ = IVouchifyEscrow(escrowAddress).tokenId();
        IVouchifyVoucher(_voucherContract).recordRedemption(tokenId_, amount, remaining);
        
        return remaining;
    }

    /// @notice Refund a voucher
    /// @param voucherId Voucher ID
    function refundVoucher(bytes32 voucherId) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        address escrowAddress = _escrowsByVoucherId[voucherId];
        if (escrowAddress == address(0)) revert VouchifyErrors.EscrowNotFound();
        
        IVouchifyEscrow(escrowAddress).refund();
    }

    /// @notice Mark a voucher as expired
    /// @param voucherId Voucher ID
    function expireVoucher(bytes32 voucherId) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        address escrowAddress = _escrowsByVoucherId[voucherId];
        if (escrowAddress == address(0)) revert VouchifyErrors.EscrowNotFound();
        
        IVouchifyEscrow(escrowAddress).expire();
    }

    /// @notice Extend a voucher's expiry date and deduct extension fee
    /// @param voucherId Voucher ID
    /// @param newExpiresAt New expiry timestamp
    /// @param feeDeducted Fee deducted from escrow balance (smallest unit)
    function extendVoucher(
        bytes32 voucherId,
        uint256 newExpiresAt,
        uint256 feeDeducted
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        address escrowAddress = _escrowsByVoucherId[voucherId];
        if (escrowAddress == address(0)) revert VouchifyErrors.EscrowNotFound();

        IVouchifyEscrow(escrowAddress).extendExpiry(newExpiresAt, feeDeducted);
    }

    /// @notice Sync owner when NFT is transferred
    /// @param tokenId Token ID
    /// @param newOwner New owner address
    function syncOwner(uint256 tokenId, address newOwner) external {
        // Only voucher contract can call this
        if (msg.sender != _voucherContract) revert VouchifyErrors.Unauthorized();
        
        address escrowAddress = _escrowsByTokenId[tokenId];
        if (escrowAddress != address(0)) {
            IVouchifyEscrow(escrowAddress).syncOwner(newOwner);
        }
    }

    // ============ Admin Functions ============
    
    /// @inheritdoc IVouchifyEscrowFactory
    function setImplementation(address newImplementation) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newImplementation == address(0)) revert VouchifyErrors.ZeroAddress();
        
        address oldImpl = _implementation;
        _implementation = newImplementation;
        
        emit ImplementationUpdated(oldImpl, newImplementation);
    }

    /// @inheritdoc IVouchifyEscrowFactory
    function setVoucherContract(address voucherContract_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (voucherContract_ == address(0)) revert VouchifyErrors.ZeroAddress();
        
        _voucherContract = voucherContract_;
        
        emit VoucherContractSet(voucherContract_);
    }

    /// @notice Pause the factory
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the factory
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ============ View Functions ============
    
    /// @inheritdoc IVouchifyEscrowFactory
    function getEscrowAddress(bytes32 voucherId) external view override returns (address) {
        return _implementation.predictDeterministicAddress(voucherId, address(this));
    }

    /// @inheritdoc IVouchifyEscrowFactory
    function getEscrowByTokenId(uint256 tokenId) external view override returns (address) {
        return _escrowsByTokenId[tokenId];
    }

    /// @inheritdoc IVouchifyEscrowFactory
    function getEscrowByVoucherId(bytes32 voucherId) external view override returns (address) {
        return _escrowsByVoucherId[voucherId];
    }

    /// @inheritdoc IVouchifyEscrowFactory
    function implementation() external view override returns (address) {
        return _implementation;
    }

    /// @inheritdoc IVouchifyEscrowFactory
    function voucherContract() external view override returns (address) {
        return _voucherContract;
    }

    /// @inheritdoc IVouchifyEscrowFactory
    function totalEscrows() external view override returns (uint256) {
        return _totalEscrows;
    }

    /// @notice Check if an escrow exists for a voucher ID
    /// @param voucherId Voucher ID
    /// @return True if escrow exists
    function escrowExists(bytes32 voucherId) external view returns (bool) {
        return _escrowsByVoucherId[voucherId] != address(0);
    }
}
