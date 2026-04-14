// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { VouchifyVoucher } from "../src/core/VouchifyVoucher.sol";
import { VouchifyEscrow } from "../src/core/VouchifyEscrow.sol";
import { VouchifyEscrowFactory } from "../src/core/VouchifyEscrowFactory.sol";
import { VouchifyTypes } from "../src/libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../src/libraries/VouchifyErrors.sol";

/// @title VouchifyVoucherTest
/// @notice Unit tests for VouchifyVoucher ERC-721 NFT
contract VouchifyVoucherTest is Test {
    VouchifyEscrow public escrowImpl;
    VouchifyEscrowFactory public factory;
    VouchifyVoucher public voucher;
    
    address public admin = address(0x1);
    address public operator = address(0x2);
    address public pauser = address(0x3);
    address public buyer = address(0x4);
    address public recipient = address(0x5);
    
    bytes32 public constant VOUCHER_ID = keccak256("VOUCHER_001");
    uint256 public constant AMOUNT = 100 * 1e6;
    uint256 public constant MERCHANT_ID = 1;
    
    function setUp() public {
        vm.startPrank(admin);
        
        escrowImpl = new VouchifyEscrow();
        voucher = new VouchifyVoucher(
            "Vouchify Voucher",
            "VOUCH",
            admin,
            "https://api.vouchify.com/voucher/"
        );
        factory = new VouchifyEscrowFactory(address(escrowImpl), admin, operator, pauser);
        
        factory.setVoucherContract(address(voucher));
        voucher.setFactory(address(factory));
        
        vm.stopPrank();
    }
    
    modifier asOperator() {
        vm.startPrank(operator);
        _;
        vm.stopPrank();
    }
    
    function testMintVoucher() public {
        vm.startPrank(operator);
        
        (address escrowAddress, uint256 tokenId) = _createTestEscrow();
        
        // Verify NFT was minted
        assertEq(voucher.ownerOf(tokenId), buyer);
        assertEq(voucher.balanceOf(buyer), 1);
        assertEq(voucher.totalMinted(), 1);
        assertEq(voucher.totalSupply(), 1);
        
        // Verify metadata
        VouchifyTypes.VoucherMetadata memory metadata = voucher.getVoucher(tokenId);
        assertEq(metadata.escrowAddress, escrowAddress);
        assertEq(metadata.merchantId, MERCHANT_ID);
        assertEq(metadata.originalAmount, AMOUNT);
        assertEq(metadata.originalBuyer, buyer);
        assertFalse(metadata.isGift);
        
        vm.stopPrank();
    }
    
    function testTransferVoucher() public {
        vm.startPrank(operator);
        (, uint256 tokenId) = _createTestEscrow();
        vm.stopPrank();
        
        // Transfer from buyer to recipient
        vm.prank(buyer);
        voucher.transferFrom(buyer, recipient, tokenId);
        
        // Verify ownership changed
        assertEq(voucher.ownerOf(tokenId), recipient);
        assertEq(voucher.balanceOf(buyer), 0);
        assertEq(voucher.balanceOf(recipient), 1);
    }
    
    function testGetEscrowAddress() public {
        vm.startPrank(operator);
        
        (address escrowAddress, uint256 tokenId) = _createTestEscrow();
        
        assertEq(voucher.getEscrow(tokenId), escrowAddress);
        
        vm.stopPrank();
    }
    
    function testVoucherExists() public {
        vm.startPrank(operator);
        
        assertFalse(voucher.voucherExists(1));
        
        (, uint256 tokenId) = _createTestEscrow();
        
        assertTrue(voucher.voucherExists(tokenId));
        
        vm.stopPrank();
    }
    
    function testBurnVoucher() public {
        vm.startPrank(operator);
        (, uint256 tokenId) = _createTestEscrow();
        vm.stopPrank();
        
        // Burn by owner
        vm.prank(buyer);
        voucher.burn(tokenId);
        
        assertFalse(voucher.voucherExists(tokenId));
        assertEq(voucher.balanceOf(buyer), 0);
        assertEq(voucher.totalSupply(), 0);
    }
    
    function testCannotBurnOthersVoucher() public {
        vm.startPrank(operator);
        (, uint256 tokenId) = _createTestEscrow();
        vm.stopPrank();
        
        // Try to burn as non-owner
        vm.prank(recipient);
        vm.expectRevert(VouchifyErrors.NotVoucherOwner.selector);
        voucher.burn(tokenId);
    }
    
    function testEnumeration() public {
        vm.startPrank(operator);
        
        // Create multiple vouchers for same buyer
        (, uint256 tokenId1) = _createTestEscrow();
        
        // Create second voucher
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: keccak256("VOUCHER_002"),
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: 5 * 1e6,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.USDC,
            externalTxId: "",
            isGift: false
        });
        (, uint256 tokenId2) = factory.createEscrow(params);
        
        vm.stopPrank();
        
        // Verify enumeration
        assertEq(voucher.balanceOf(buyer), 2);
        assertEq(voucher.tokenOfOwnerByIndex(buyer, 0), tokenId1);
        assertEq(voucher.tokenOfOwnerByIndex(buyer, 1), tokenId2);
    }
    
    function testSetBaseURI() public {
        vm.prank(admin);
        voucher.setBaseURI("https://new-api.vouchify.com/voucher/");
        
        // Note: tokenURI requires token to exist
    }
    
    function testPauseAndUnpause() public {
        vm.startPrank(admin);
        
        voucher.pause();
        
        vm.stopPrank();
        
        // Try to create while paused
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: VOUCHER_ID,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: 5 * 1e6,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_123",
            isGift: false
        });
        
        vm.prank(operator);
        vm.expectRevert();
        factory.createEscrow(params);
        
        // Unpause
        vm.prank(admin);
        voucher.unpause();
        
        // Should work now
        vm.prank(operator);
        factory.createEscrow(params);
        
        vm.stopPrank();
    }
    
    // ============ Helper Functions ============
    
    function _createTestEscrow() internal returns (address, uint256) {
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: VOUCHER_ID,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: 5 * 1e6,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_123",
            isGift: false
        });
        
        return factory.createEscrow(params);
    }
}
