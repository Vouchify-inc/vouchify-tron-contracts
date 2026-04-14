// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";

/// @title IVouchifyEscrowFactory
/// @notice Interface for the escrow factory that deploys minimal proxy clones
interface IVouchifyEscrowFactory {
    // ============ Events ============
    
    /// @notice Emitted when a new escrow clone is created
    event EscrowCreated(
        bytes32 indexed voucherId,
        address indexed escrowAddress,
        uint256 indexed tokenId,
        address buyer,
        uint256 merchantId,
        uint256 amount
    );

    /// @notice Emitted when implementation is updated
    event ImplementationUpdated(address indexed oldImpl, address indexed newImpl);

    /// @notice Emitted when voucher contract is set
    event VoucherContractSet(address indexed voucherContract);

    // ============ Core Functions ============
    
    /// @notice Create a new escrow clone and mint voucher NFT
    /// @param params Parameters for creating the escrow
    /// @return escrowAddress Address of the deployed escrow clone
    /// @return tokenId ID of the minted voucher NFT
    function createEscrow(
        VouchifyTypes.CreateEscrowParams calldata params
    ) external returns (address escrowAddress, uint256 tokenId);

    /// @notice Predict escrow address using CREATE2
    /// @param voucherId Unique voucher identifier
    /// @return Predicted escrow clone address
    function getEscrowAddress(bytes32 voucherId) external view returns (address);

    /// @notice Get escrow address by token ID
    /// @param tokenId NFT token ID
    /// @return Escrow clone address
    function getEscrowByTokenId(uint256 tokenId) external view returns (address);

    /// @notice Get escrow address by voucher ID
    /// @param voucherId Unique voucher identifier
    /// @return Escrow clone address
    function getEscrowByVoucherId(bytes32 voucherId) external view returns (address);

    // ============ Admin Functions ============
    
    /// @notice Set the escrow implementation contract
    /// @param newImplementation Address of new implementation
    function setImplementation(address newImplementation) external;

    /// @notice Set the voucher NFT contract
    /// @param voucherContract Address of VouchifyVoucher contract
    function setVoucherContract(address voucherContract) external;

    // ============ View Functions ============
    
    /// @notice Get the current implementation address
    function implementation() external view returns (address);

    /// @notice Get the voucher NFT contract address
    function voucherContract() external view returns (address);

    /// @notice Get total escrows created
    function totalEscrows() external view returns (uint256);
}
