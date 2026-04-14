// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";

/// @title IVouchifyVoucher
/// @notice Interface for the ERC-721 voucher NFT contract
interface IVouchifyVoucher {
    // ============ Events ============
    
    /// @notice Emitted when a new voucher is minted
    event VoucherMinted(
        uint256 indexed tokenId,
        address indexed escrowAddress,
        address indexed owner,
        uint256 merchantId,
        uint256 amount
    );

    /// @notice Emitted when voucher is redeemed (partial or full)
    event VoucherRedeemed(
        uint256 indexed tokenId,
        uint256 amount,
        uint256 remaining,
        bool fullyRedeemed
    );

    /// @notice Emitted when voucher NFT is burned
    event VoucherBurned(uint256 indexed tokenId);

    // ============ Core Functions ============
    
    /// @notice Mint a new voucher NFT
    /// @param to Recipient address
    /// @param escrowAddress Address of the escrow clone
    /// @param merchantId Off-chain merchant ID
    /// @param amount Original purchase amount
    /// @param expiresAt Expiry timestamp
    /// @param isGift Whether this is a gift voucher
    /// @return tokenId The minted token ID
    function mint(
        address to,
        address escrowAddress,
        uint256 merchantId,
        uint256 amount,
        uint256 expiresAt,
        bool isGift
    ) external returns (uint256 tokenId);

    /// @notice Burn a voucher NFT (after full redemption or expiry)
    /// @param tokenId Token ID to burn
    function burn(uint256 tokenId) external;

    /// @notice Record a redemption on the voucher
    /// @param tokenId Token ID
    /// @param amount Amount redeemed
    /// @param remaining Amount remaining
    function recordRedemption(uint256 tokenId, uint256 amount, uint256 remaining) external;

    // ============ View Functions ============
    
    /// @notice Get voucher metadata
    /// @param tokenId Token ID
    /// @return Voucher metadata struct
    function getVoucher(uint256 tokenId) external view returns (VouchifyTypes.VoucherMetadata memory);

    /// @notice Get the escrow address for a voucher
    /// @param tokenId Token ID
    /// @return Escrow clone address
    function getEscrow(uint256 tokenId) external view returns (address);

    /// @notice Check if a voucher exists and is not burned
    /// @param tokenId Token ID
    /// @return True if voucher exists
    function voucherExists(uint256 tokenId) external view returns (bool);

    /// @notice Get the factory address
    function factory() external view returns (address);

    /// @notice Get total vouchers minted
    function totalMinted() external view returns (uint256);
}
