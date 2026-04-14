// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IVouchifyMembershipFactory } from "../interfaces/IVouchifyMembershipFactory.sol";
import { IVouchifyMembership } from "../interfaces/IVouchifyMembership.sol";
import { IVouchifyVoucher } from "../interfaces/IVouchifyVoucher.sol";
import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../libraries/VouchifyErrors.sol";

/// @title VouchifyMembershipFactory
/// @notice Factory contract that deploys minimal proxy clones for each membership pass
/// @dev Uses EIP-1167 (OpenZeppelin Clones) for gas-efficient deployment
contract VouchifyMembershipFactory is IVouchifyMembershipFactory, AccessControl, Pausable, ReentrancyGuard {
    using Clones for address;

    // ============ Constants ============

    /// @notice Role for operators who can create memberships
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Role for pausing the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Version for upgrade tracking
    string public constant VERSION = "1.0.0";

    // ============ State Variables ============

    /// @notice Address of the membership implementation contract
    address private _implementation;

    /// @notice Address of the VouchifyVoucher NFT contract
    address private _voucherContract;

    /// @notice Mapping: membershipId => membership clone address
    mapping(bytes32 => address) private _membershipsByMembershipId;

    /// @notice Mapping: tokenId => membership clone address
    mapping(uint256 => address) private _membershipsByTokenId;

    /// @notice Total number of memberships created
    uint256 private _totalMemberships;

    // ============ Constructor ============

    /// @notice Initialize the factory with implementation, admin, operator, and pauser
    /// @param implementation_ Address of the VouchifyMembership implementation
    /// @param admin Address of the default admin
    /// @param operator Address that can create and manage memberships
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

    /// @inheritdoc IVouchifyMembershipFactory
    function createMembership(
        VouchifyTypes.CreateMembershipParams calldata params
    ) external override onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant returns (
        address membershipAddress,
        uint256 tokenId
    ) {
        // Validate inputs
        if (params.buyer == address(0)) revert VouchifyErrors.ZeroAddress();
        if (params.totalCredits == 0) revert VouchifyErrors.InvalidAmount();
        if (params.expiresAt <= block.timestamp) revert VouchifyErrors.InvalidTimestamp();
        if (_membershipsByMembershipId[params.membershipId] != address(0)) {
            revert VouchifyErrors.MembershipAlreadyExists();
        }
        if (_voucherContract == address(0)) revert VouchifyErrors.VoucherContractNotSet();

        // Deploy clone using CREATE2 for deterministic address
        membershipAddress = _implementation.cloneDeterministic(params.membershipId);

        // Mint the voucher NFT first to get tokenId
        tokenId = IVouchifyVoucher(_voucherContract).mint(
            params.buyer,
            membershipAddress,
            params.merchantId,
            params.totalCredits,
            params.expiresAt,
            false // Memberships are not gifts
        );

        // Initialize the membership clone
        IVouchifyMembership(membershipAddress).initialize(
            params.membershipId,
            tokenId,
            params.buyer,
            params.merchantId,
            params.totalCredits,
            params.platformFee,
            params.expiresAt,
            params.paymentMethod,
            params.externalTxId
        );

        // Activate immediately (payment already confirmed by backend)
        IVouchifyMembership(membershipAddress).activate();

        // Store mappings
        _membershipsByMembershipId[params.membershipId] = membershipAddress;
        _membershipsByTokenId[tokenId] = membershipAddress;
        _totalMemberships++;

        emit MembershipCreated(
            params.membershipId,
            membershipAddress,
            tokenId,
            params.buyer,
            params.merchantId,
            params.totalCredits
        );
    }

    /// @inheritdoc IVouchifyMembershipFactory
    function redeemCredit(
        bytes32 membershipId_
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant returns (uint256 remaining) {
        address membershipAddress = _membershipsByMembershipId[membershipId_];
        if (membershipAddress == address(0)) revert VouchifyErrors.MembershipNotFound();

        remaining = IVouchifyMembership(membershipAddress).redeemCredit();

        // Record redemption on NFT
        uint256 tokenId_ = IVouchifyMembership(membershipAddress).tokenId();
        IVouchifyVoucher(_voucherContract).recordRedemption(tokenId_, 1, remaining);

        emit CreditRedeemed(membershipId_, remaining, tx.origin);

        return remaining;
    }

    /// @notice Mark a membership as expired
    /// @param membershipId_ Membership ID
    function expireMembership(bytes32 membershipId_) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        address membershipAddress = _membershipsByMembershipId[membershipId_];
        if (membershipAddress == address(0)) revert VouchifyErrors.MembershipNotFound();

        IVouchifyMembership(membershipAddress).expire();
    }

    /// @notice Sync owner when NFT is transferred
    /// @param tokenId Token ID
    /// @param newOwner New owner address
    function syncOwner(uint256 tokenId, address newOwner) external {
        // Only voucher contract can call this
        if (msg.sender != _voucherContract) revert VouchifyErrors.Unauthorized();

        address membershipAddress = _membershipsByTokenId[tokenId];
        if (membershipAddress != address(0)) {
            IVouchifyMembership(membershipAddress).syncOwner(newOwner);
        }
    }

    // ============ Admin Functions ============

    /// @inheritdoc IVouchifyMembershipFactory
    function setImplementation(address newImplementation) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newImplementation == address(0)) revert VouchifyErrors.ZeroAddress();

        address oldImpl = _implementation;
        _implementation = newImplementation;

        emit ImplementationUpdated(oldImpl, newImplementation);
    }

    /// @inheritdoc IVouchifyMembershipFactory
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

    /// @inheritdoc IVouchifyMembershipFactory
    function getMembershipAddress(bytes32 membershipId_) external view override returns (address) {
        return _implementation.predictDeterministicAddress(membershipId_, address(this));
    }

    /// @inheritdoc IVouchifyMembershipFactory
    function getMembershipByTokenId(uint256 tokenId) external view override returns (address) {
        return _membershipsByTokenId[tokenId];
    }

    /// @inheritdoc IVouchifyMembershipFactory
    function getMembershipByMembershipId(bytes32 membershipId_) external view override returns (address) {
        return _membershipsByMembershipId[membershipId_];
    }

    /// @inheritdoc IVouchifyMembershipFactory
    function implementation() external view override returns (address) {
        return _implementation;
    }

    /// @inheritdoc IVouchifyMembershipFactory
    function voucherContract() external view override returns (address) {
        return _voucherContract;
    }

    /// @inheritdoc IVouchifyMembershipFactory
    function totalMemberships() external view override returns (uint256) {
        return _totalMemberships;
    }

    /// @notice Check if a membership exists for a membership ID
    /// @param membershipId_ Membership ID
    /// @return True if membership exists
    function membershipExists(bytes32 membershipId_) external view returns (bool) {
        return _membershipsByMembershipId[membershipId_] != address(0);
    }
}
