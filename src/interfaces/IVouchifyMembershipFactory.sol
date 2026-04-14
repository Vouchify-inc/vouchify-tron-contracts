// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";

/// @title IVouchifyMembershipFactory
/// @notice Interface for the membership factory that deploys minimal proxy clones
interface IVouchifyMembershipFactory {
    // ============ Events ============

    /// @notice Emitted when a new membership clone is created
    event MembershipCreated(
        bytes32 indexed membershipId,
        address indexed membershipAddress,
        uint256 indexed tokenId,
        address buyer,
        uint256 merchantId,
        uint256 totalCredits
    );

    /// @notice Emitted when a credit is redeemed
    event CreditRedeemed(
        bytes32 indexed membershipId,
        uint256 remainingCredits,
        address indexed redeemedBy
    );

    /// @notice Emitted when implementation is updated
    event ImplementationUpdated(address indexed oldImpl, address indexed newImpl);

    /// @notice Emitted when voucher contract is set
    event VoucherContractSet(address indexed voucherContract);

    // ============ Core Functions ============

    /// @notice Create a new membership clone and mint voucher NFT
    /// @param params Parameters for creating the membership
    /// @return membershipAddress Address of the deployed membership clone
    /// @return tokenId ID of the minted voucher NFT
    function createMembership(
        VouchifyTypes.CreateMembershipParams calldata params
    ) external returns (address membershipAddress, uint256 tokenId);

    /// @notice Redeem one credit from a membership
    /// @param membershipId Membership ID
    /// @return remaining Number of credits remaining
    function redeemCredit(bytes32 membershipId) external returns (uint256 remaining);

    /// @notice Mark a membership as expired
    /// @param membershipId Membership ID
    function expireMembership(bytes32 membershipId) external;

    // ============ Admin Functions ============

    /// @notice Set the membership implementation contract
    /// @param newImplementation Address of new implementation
    function setImplementation(address newImplementation) external;

    /// @notice Set the voucher NFT contract
    /// @param voucherContract Address of VouchifyVoucher contract
    function setVoucherContract(address voucherContract) external;

    // ============ View Functions ============

    /// @notice Predict membership address using CREATE2
    /// @param membershipId Unique membership identifier
    /// @return Predicted membership clone address
    function getMembershipAddress(bytes32 membershipId) external view returns (address);

    /// @notice Get membership address by token ID
    /// @param tokenId NFT token ID
    /// @return Membership clone address
    function getMembershipByTokenId(uint256 tokenId) external view returns (address);

    /// @notice Get membership address by membership ID
    /// @param membershipId Unique membership identifier
    /// @return Membership clone address
    function getMembershipByMembershipId(bytes32 membershipId) external view returns (address);

    /// @notice Get the current implementation address
    function implementation() external view returns (address);

    /// @notice Get the voucher NFT contract address
    function voucherContract() external view returns (address);

    /// @notice Get total memberships created
    function totalMemberships() external view returns (uint256);
}
