// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { IVouchifyVoucher } from "../interfaces/IVouchifyVoucher.sol";
import { VouchifyTypes } from "../libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../libraries/VouchifyErrors.sol";

/// @title VouchifyVoucher
/// @notice ERC-721 NFT representing voucher ownership
/// @dev Each token is linked to an escrow clone contract
contract VouchifyVoucher is IVouchifyVoucher, ERC721, ERC721Enumerable, ERC721Burnable, AccessControl, Pausable {
    // ============ Constants ============
    
    /// @notice Role for the factory contract
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    
    /// @notice Role for pausing
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Version for upgrade tracking
    string public constant VERSION = "1.0.0";

    // ============ State Variables ============
    
    /// @notice Factory contract address
    address private _factory;
    
    /// @notice Token ID counter
    uint256 private _tokenIdCounter;
    
    /// @notice Total minted (including burned)
    uint256 private _totalMinted;
    
    /// @notice Mapping: tokenId => escrow address
    mapping(uint256 => address) private _tokenEscrow;
    
    /// @notice Mapping: tokenId => metadata
    mapping(uint256 => VouchifyTypes.VoucherMetadata) private _metadata;
    
    /// @notice Base URI for token metadata
    string private _baseTokenURI;

    // ============ Constructor ============
    
    /// @notice Initialize the voucher NFT contract
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param admin Admin address
    /// @param baseURI_ Base URI for metadata
    constructor(
        string memory name_,
        string memory symbol_,
        address admin,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        if (admin == address(0)) revert VouchifyErrors.ZeroAddress();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _baseTokenURI = baseURI_;
    }

    // ============ Core Functions ============
    
    /// @inheritdoc IVouchifyVoucher
    function mint(
        address to,
        address escrowAddress,
        uint256 merchantId,
        uint256 amount,
        uint256 expiresAt,
        bool isGift
    ) external override onlyRole(FACTORY_ROLE) whenNotPaused returns (uint256 tokenId) {
        if (to == address(0)) revert VouchifyErrors.ZeroAddress();
        if (escrowAddress == address(0)) revert VouchifyErrors.ZeroAddress();
        if (amount == 0) revert VouchifyErrors.InvalidAmount();
        
        _tokenIdCounter++;
        tokenId = _tokenIdCounter;
        _totalMinted++;
        
        _safeMint(to, tokenId);
        
        _tokenEscrow[tokenId] = escrowAddress;
        _metadata[tokenId] = VouchifyTypes.VoucherMetadata({
            escrowAddress: escrowAddress,
            merchantId: merchantId,
            originalAmount: amount,
            purchasedAt: block.timestamp,
            expiresAt: expiresAt,
            isGift: isGift,
            originalBuyer: to
        });
        
        emit VoucherMinted(tokenId, escrowAddress, to, merchantId, amount);
    }

    /// @inheritdoc IVouchifyVoucher
    function burn(uint256 tokenId) public override(IVouchifyVoucher, ERC721Burnable) {
        // Can be burned by owner, approved, or factory
        if (!_isAuthorized(ownerOf(tokenId), msg.sender, tokenId) && !hasRole(FACTORY_ROLE, msg.sender)) {
            revert VouchifyErrors.NotVoucherOwner();
        }
        
        _burn(tokenId);
        
        // Clean up mappings
        delete _tokenEscrow[tokenId];
        delete _metadata[tokenId];
        
        emit VoucherBurned(tokenId);
    }

    /// @inheritdoc IVouchifyVoucher
    function recordRedemption(
        uint256 tokenId,
        uint256 amount,
        uint256 remaining
    ) external override onlyRole(FACTORY_ROLE) {
        if (!_exists(tokenId)) revert VouchifyErrors.VoucherNotFound();
        
        bool fullyRedeemed = remaining == 0;
        
        emit VoucherRedeemed(tokenId, amount, remaining, fullyRedeemed);
    }

    // ============ Admin Functions ============
    
    /// @notice Set the factory contract
    /// @param factory_ Factory address
    function setFactory(address factory_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (factory_ == address(0)) revert VouchifyErrors.ZeroAddress();
        
        // Revoke old factory role if exists
        if (_factory != address(0)) {
            _revokeRole(FACTORY_ROLE, _factory);
        }
        
        _factory = factory_;
        _grantRole(FACTORY_ROLE, factory_);
    }

    /// @notice Set the base URI
    /// @param baseURI_ New base URI
    function setBaseURI(string calldata baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI_;
    }

    /// @notice Pause the contract
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ============ View Functions ============
    
    /// @inheritdoc IVouchifyVoucher
    function getVoucher(uint256 tokenId) external view override returns (VouchifyTypes.VoucherMetadata memory) {
        if (!_exists(tokenId)) revert VouchifyErrors.VoucherNotFound();
        return _metadata[tokenId];
    }

    /// @inheritdoc IVouchifyVoucher
    function getEscrow(uint256 tokenId) external view override returns (address) {
        if (!_exists(tokenId)) revert VouchifyErrors.VoucherNotFound();
        return _tokenEscrow[tokenId];
    }

    /// @inheritdoc IVouchifyVoucher
    function voucherExists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /// @inheritdoc IVouchifyVoucher
    function factory() external view override returns (address) {
        return _factory;
    }

    /// @inheritdoc IVouchifyVoucher
    function totalMinted() external view override returns (uint256) {
        return _totalMinted;
    }

    // ============ Internal Functions ============
    
    /// @notice Check if token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /// @notice Override base URI
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Hook called after token transfer - sync owner with escrow
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused returns (address) {
        address from = super._update(to, tokenId, auth);
        
        // If this is a transfer (not mint or burn), sync owner with factory
        if (from != address(0) && to != address(0) && _factory != address(0)) {
            // Call factory to sync owner in escrow
            // Using low-level call to avoid revert if factory doesn't implement
            (bool success,) = _factory.call(
                abi.encodeWithSignature("syncOwner(uint256,address)", tokenId, to)
            );
            // Don't revert if sync fails - transfer should still work
        }
        
        return from;
    }

    // ============ Required Overrides ============
    
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
