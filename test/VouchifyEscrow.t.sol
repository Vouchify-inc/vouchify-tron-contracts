// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { VouchifyEscrow } from "../src/core/VouchifyEscrow.sol";
import { VouchifyEscrowFactory } from "../src/core/VouchifyEscrowFactory.sol";
import { VouchifyVoucher } from "../src/core/VouchifyVoucher.sol";
import { VouchifyMerchantRegistry } from "../src/registry/VouchifyMerchantRegistry.sol";
import { VouchifyTypes } from "../src/libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../src/libraries/VouchifyErrors.sol";

/// @title VouchifyEscrowTest
/// @notice Unit tests for VouchifyEscrow clone template
contract VouchifyEscrowTest is Test {
    VouchifyEscrow public escrowImpl;
    VouchifyEscrowFactory public factory;
    VouchifyVoucher public voucher;
    
    address public admin = address(0x1);
    address public operator = address(0x2);
    address public pauser = address(0x3);
    address public buyer = address(0x4);
    address public merchant = address(0x5);
    
    bytes32 public constant VOUCHER_ID = keccak256("VOUCHER_001");
    uint256 public constant AMOUNT = 100 * 1e6; // 100 USDC (6 decimals)
    uint256 public constant PLATFORM_FEE = 5 * 1e6; // 5 USDC
    uint256 public constant MERCHANT_ID = 1;
    
    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy implementation
        escrowImpl = new VouchifyEscrow();
        
        // Deploy voucher NFT
        voucher = new VouchifyVoucher(
            "Vouchify Voucher",
            "VOUCH",
            admin,
            "https://api.vouchify.com/voucher/"
        );
        
        // Deploy factory with new constructor parameters
        factory = new VouchifyEscrowFactory(address(escrowImpl), admin, operator, pauser);
        
        // Link contracts
        factory.setVoucherContract(address(voucher));
        voucher.setFactory(address(factory));
        
        vm.stopPrank();
    }
    
    function testCreateEscrow() public {
        vm.startPrank(operator);
        
        uint256 expiresAt = block.timestamp + 30 days;
        
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: VOUCHER_ID,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: expiresAt,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_123",
            isGift: false
        });
        
        (address escrowAddress, uint256 tokenId) = factory.createEscrow(params);
        
        // Verify escrow was created
        assertEq(factory.getEscrowByVoucherId(VOUCHER_ID), escrowAddress);
        assertEq(factory.getEscrowByTokenId(tokenId), escrowAddress);
        assertEq(factory.totalEscrows(), 1);
        
        // Verify escrow state
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        assertEq(escrow.voucherId(), VOUCHER_ID);
        assertEq(escrow.buyer(), buyer);
        assertEq(escrow.currentOwner(), buyer);
        assertEq(escrow.merchantId(), MERCHANT_ID);
        assertEq(escrow.amount(), AMOUNT);
        assertEq(escrow.remainingAmount(), AMOUNT);
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.ACTIVE));
        assertTrue(escrow.isRedeemable());
        assertFalse(escrow.isExpired());
        
        vm.stopPrank();
    }
    
    function testRedeemPartial() public {
        vm.startPrank(operator);
        
        // Create escrow
        (address escrowAddress,) = _createTestEscrow();
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        // Redeem partial amount
        uint256 redeemAmount = 30 * 1e6; // 30 USDC
        uint256 remaining = factory.redeemVoucher(VOUCHER_ID, redeemAmount);
        
        assertEq(remaining, AMOUNT - redeemAmount);
        assertEq(escrow.remainingAmount(), AMOUNT - redeemAmount);
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.PARTIALLY_REDEEMED));
        assertEq(escrow.getRedemptionCount(), 1);
        
        vm.stopPrank();
    }
    
    function testRedeemFull() public {
        vm.startPrank(operator);
        
        // Create escrow
        (address escrowAddress,) = _createTestEscrow();
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        // Redeem full amount
        uint256 remaining = factory.redeemVoucher(VOUCHER_ID, AMOUNT);
        
        assertEq(remaining, 0);
        assertEq(escrow.remainingAmount(), 0);
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.REDEEMED));
        assertFalse(escrow.isRedeemable());
        
        vm.stopPrank();
    }
    
    function testRedeemMultiplePartial() public {
        vm.startPrank(operator);
        
        // Create escrow
        (address escrowAddress,) = _createTestEscrow();
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        // First redemption
        factory.redeemVoucher(VOUCHER_ID, 30 * 1e6);
        assertEq(escrow.getRedemptionCount(), 1);
        
        // Second redemption
        factory.redeemVoucher(VOUCHER_ID, 40 * 1e6);
        assertEq(escrow.getRedemptionCount(), 2);
        
        // Final redemption
        uint256 remaining = factory.redeemVoucher(VOUCHER_ID, 30 * 1e6);
        assertEq(remaining, 0);
        assertEq(escrow.getRedemptionCount(), 3);
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.REDEEMED));
        
        vm.stopPrank();
    }
    
    function testCannotRedeemMoreThanRemaining() public {
        vm.startPrank(operator);
        
        _createTestEscrow();
        
        // Try to redeem more than available
        vm.expectRevert(VouchifyErrors.RedemptionAmountExceedsRemaining.selector);
        factory.redeemVoucher(VOUCHER_ID, AMOUNT + 1);
        
        vm.stopPrank();
    }
    
    function testCannotRedeemAfterExpiry() public {
        vm.startPrank(operator);
        
        _createTestEscrow();
        
        // Fast forward past expiry
        vm.warp(block.timestamp + 31 days);
        
        // Try to redeem
        vm.expectRevert(VouchifyErrors.EscrowExpired.selector);
        factory.redeemVoucher(VOUCHER_ID, AMOUNT);
        
        vm.stopPrank();
    }
    
    function testRefund() public {
        vm.startPrank(operator);
        
        (address escrowAddress,) = _createTestEscrow();
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        factory.refundVoucher(VOUCHER_ID);
        
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.REFUNDED));
        assertEq(escrow.remainingAmount(), 0);
        
        vm.stopPrank();
    }
    
    function testCannotRefundAfterRedemption() public {
        vm.startPrank(operator);
        
        _createTestEscrow();
        
        // Redeem fully
        factory.redeemVoucher(VOUCHER_ID, AMOUNT);
        
        // Try to refund
        vm.expectRevert(VouchifyErrors.EscrowAlreadyRedeemed.selector);
        factory.refundVoucher(VOUCHER_ID);
        
        vm.stopPrank();
    }
    
    function testExpire() public {
        vm.startPrank(operator);
        
        (address escrowAddress,) = _createTestEscrow();
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        // Fast forward past expiry
        vm.warp(block.timestamp + 31 days);
        
        factory.expireVoucher(VOUCHER_ID);
        
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.EXPIRED));
        
        vm.stopPrank();
    }
    
    function testCannotExpireBeforeExpiryTime() public {
        vm.startPrank(operator);
        
        _createTestEscrow();
        
        // Try to expire before time
        vm.expectRevert(VouchifyErrors.EscrowNotExpired.selector);
        factory.expireVoucher(VOUCHER_ID);
        
        vm.stopPrank();
    }
    
    function testCannotCreateDuplicateEscrow() public {
        vm.startPrank(operator);
        
        _createTestEscrow();
        
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: VOUCHER_ID,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_456",
            isGift: false
        });
        
        vm.expectRevert(VouchifyErrors.EscrowAlreadyExists.selector);
        factory.createEscrow(params);
        
        vm.stopPrank();
    }
    
    function testPredictEscrowAddress() public {
        vm.startPrank(operator);
        
        // Predict address before creation
        address predicted = factory.getEscrowAddress(VOUCHER_ID);
        
        // Create escrow
        (address actual,) = _createTestEscrow();
        
        // Verify prediction was correct
        assertEq(predicted, actual);
        
        vm.stopPrank();
    }
    
    // ============ Helper Functions ============
    
    function _createTestEscrow() internal returns (address, uint256) {
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: VOUCHER_ID,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_123",
            isGift: false
        });
        
        return factory.createEscrow(params);
    }
}
