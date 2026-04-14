// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { VouchifyEscrow } from "../../src/core/VouchifyEscrow.sol";
import { VouchifyEscrowFactory } from "../../src/core/VouchifyEscrowFactory.sol";
import { VouchifyVoucher } from "../../src/core/VouchifyVoucher.sol";
import { VouchifyMerchantRegistry } from "../../src/registry/VouchifyMerchantRegistry.sol";
import { VouchifyTypes } from "../../src/libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../../src/libraries/VouchifyErrors.sol";

/// @title FullFlowTest
/// @notice Integration tests for complete voucher purchase → redemption → withdrawal flow
contract FullFlowTest is Test {
    VouchifyEscrow public escrowImpl;
    VouchifyEscrowFactory public factory;
    VouchifyVoucher public voucher;
    VouchifyMerchantRegistry public registry;
    
    address public admin = address(0x1);
    address public operator = address(0x2);
    address public pauser = address(0x3);
    address public buyer = address(0x4);
    address public buyer2 = address(0x5);
    address public merchantWallet = address(0x6);
    
    uint256 public constant MERCHANT_ID = 1;
    uint256 public constant AMOUNT = 100 * 1e6; // $100 (6 decimals)
    uint256 public constant PLATFORM_FEE = 5 * 1e6; // $5 platform fee
    
    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy all contracts
        escrowImpl = new VouchifyEscrow();
        voucher = new VouchifyVoucher(
            "Vouchify Voucher",
            "VOUCH",
            admin,
            "https://api.vouchify.com/voucher/"
        );
        factory = new VouchifyEscrowFactory(address(escrowImpl), admin, operator, pauser);
        registry = new VouchifyMerchantRegistry(admin);
        
        // Link contracts
        factory.setVoucherContract(address(voucher));
        voucher.setFactory(address(factory));
        
        // Grant operator operator role
        factory.grantRole(factory.OPERATOR_ROLE(), operator);
        registry.grantRole(registry.OPERATOR_ROLE(), operator);
        registry.grantRole(registry.REGISTRAR_ROLE(), operator);
        
        // Register and verify merchant
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.verifyMerchant(MERCHANT_ID);
        
        vm.stopPrank();
    }
    
    /// @notice Test complete flow: Purchase → Full Redemption → Withdrawal
    function testFullPurchaseRedeemWithdrawFlow() public {
        bytes32 voucherId = keccak256("VOUCHER_001");
        
        // ========== Step 1: Purchase Voucher ==========
        // Backend receives Flutterwave webhook and creates escrow
        vm.startPrank(operator);
        
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: voucherId,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_12345",
            isGift: false
        });
        
        (address escrowAddress, uint256 tokenId) = factory.createEscrow(params);
        
        // Verify state
        assertEq(voucher.ownerOf(tokenId), buyer);
        assertEq(voucher.balanceOf(buyer), 1);
        
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.ACTIVE));
        assertTrue(escrow.isRedeemable());
        
        console.log("Step 1: Voucher purchased");
        console.log("  - Escrow Address:", escrowAddress);
        console.log("  - Token ID:", tokenId);
        console.log("  - Buyer:", buyer);
        
        // ========== Step 2: Customer Redeems at Merchant ==========
        // Customer shows QR code, merchant scans, operator calls redeem
        
        uint256 redeemAmount = AMOUNT - PLATFORM_FEE; // Net amount after platform fee
        factory.redeemVoucher(voucherId, AMOUNT);
        
        // Credit merchant balance
        registry.creditBalance(MERCHANT_ID, redeemAmount, voucherId);
        
        // Verify state
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.REDEEMED));
        assertEq(escrow.remainingAmount(), 0);
        assertFalse(escrow.isRedeemable());
        
        VouchifyTypes.MerchantRecord memory merchant = registry.getMerchant(MERCHANT_ID);
        assertEq(merchant.pendingBalance, redeemAmount);
        assertEq(merchant.totalEarned, redeemAmount);
        
        console.log("Step 2: Voucher redeemed");
        console.log("  - Redeemed Amount:", AMOUNT);
        console.log("  - Merchant Credit:", redeemAmount);
        
        // ========== Step 3: Merchant Withdraws ==========
        // Merchant requests withdrawal, operator processes via Flutterwave
        
        registry.debitBalance(MERCHANT_ID, redeemAmount, "withdrawal");
        
        merchant = registry.getMerchant(MERCHANT_ID);
        assertEq(merchant.pendingBalance, 0);
        assertEq(merchant.withdrawnTotal, redeemAmount);
        
        console.log("Step 3: Merchant withdrawal complete");
        console.log("  - Withdrawn:", redeemAmount);
        
        vm.stopPrank();
    }
    
    /// @notice Test partial redemption flow
    function testPartialRedemptionFlow() public {
        bytes32 voucherId = keccak256("VOUCHER_002");
        
        vm.startPrank(operator);
        
        // Create voucher
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: voucherId,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.USDC,
            externalTxId: "",
            isGift: false
        });
        
        (address escrowAddress, uint256 tokenId) = factory.createEscrow(params);
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        // First visit: Use $30
        uint256 firstRedeem = 30 * 1e6;
        uint256 remaining = factory.redeemVoucher(voucherId, firstRedeem);
        registry.creditBalance(MERCHANT_ID, firstRedeem - (PLATFORM_FEE * firstRedeem / AMOUNT), voucherId);
        
        assertEq(remaining, 70 * 1e6);
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.PARTIALLY_REDEEMED));
        assertTrue(escrow.isRedeemable());
        assertEq(escrow.getRedemptionCount(), 1);
        
        console.log("Partial redemption 1: $30, remaining: $70");
        
        // Second visit: Use $50
        uint256 secondRedeem = 50 * 1e6;
        remaining = factory.redeemVoucher(voucherId, secondRedeem);
        registry.creditBalance(MERCHANT_ID, secondRedeem - (PLATFORM_FEE * secondRedeem / AMOUNT), voucherId);
        
        assertEq(remaining, 20 * 1e6);
        assertEq(escrow.getRedemptionCount(), 2);
        
        console.log("Partial redemption 2: $50, remaining: $20");
        
        // Third visit: Use remaining $20
        uint256 thirdRedeem = 20 * 1e6;
        remaining = factory.redeemVoucher(voucherId, thirdRedeem);
        registry.creditBalance(MERCHANT_ID, thirdRedeem - (PLATFORM_FEE * thirdRedeem / AMOUNT), voucherId);
        
        assertEq(remaining, 0);
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.REDEEMED));
        assertFalse(escrow.isRedeemable());
        assertEq(escrow.getRedemptionCount(), 3);
        
        console.log("Final redemption: $20, voucher fully used");
        
        // Verify redemption history
        VouchifyTypes.Redemption memory r1 = escrow.getRedemption(0);
        VouchifyTypes.Redemption memory r2 = escrow.getRedemption(1);
        VouchifyTypes.Redemption memory r3 = escrow.getRedemption(2);
        
        assertEq(r1.amount, firstRedeem);
        assertEq(r2.amount, secondRedeem);
        assertEq(r3.amount, thirdRedeem);
        assertEq(r1.redeemedBy, operator);
        assertEq(r2.redeemedBy, operator);
        assertEq(r3.redeemedBy, operator);
        
        vm.stopPrank();
    }
    
    /// @notice Test gift voucher flow (transfer then redeem)
    function testGiftVoucherFlow() public {
        bytes32 voucherId = keccak256("GIFT_VOUCHER_001");
        
        vm.startPrank(operator);
        
        // Create gift voucher
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: voucherId,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_GIFT",
            isGift: true
        });
        
        (address escrowAddress, uint256 tokenId) = factory.createEscrow(params);
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        vm.stopPrank();
        
        // Buyer gifts to buyer2
        vm.prank(buyer);
        voucher.transferFrom(buyer, buyer2, tokenId);
        
        // Verify ownership
        assertEq(voucher.ownerOf(tokenId), buyer2);
        assertEq(escrow.currentOwner(), buyer2); // Synced via transfer hook
        assertEq(escrow.buyer(), buyer); // Original buyer unchanged
        
        console.log("Gift voucher transferred from buyer to buyer2");
        
        // buyer2 redeems
        vm.prank(operator);
        factory.redeemVoucher(voucherId, AMOUNT);
        
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.REDEEMED));
        
        console.log("Gift voucher redeemed by recipient");
    }
    
    /// @notice Test voucher expiry flow
    function testExpiryFlow() public {
        bytes32 voucherId = keccak256("EXPIRING_VOUCHER");
        
        vm.startPrank(operator);
        
        // Create voucher with 7 day expiry
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: voucherId,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: block.timestamp + 7 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_EXPIRE",
            isGift: false
        });
        
        (address escrowAddress,) = factory.createEscrow(params);
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        // Fast forward past expiry
        vm.warp(block.timestamp + 8 days);
        
        assertTrue(escrow.isExpired());
        assertFalse(escrow.isRedeemable());
        
        // Expire the voucher
        factory.expireVoucher(voucherId);
        
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.EXPIRED));
        
        console.log("Voucher expired after 7 days");
        
        vm.stopPrank();
    }
    
    /// @notice Test refund flow
    function testRefundFlow() public {
        bytes32 voucherId = keccak256("REFUND_VOUCHER");
        
        vm.startPrank(operator);
        
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: voucherId,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_REFUND",
            isGift: false
        });
        
        (address escrowAddress,) = factory.createEscrow(params);
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        
        // Process refund
        factory.refundVoucher(voucherId);
        
        assertEq(uint256(escrow.status()), uint256(VouchifyTypes.EscrowStatus.REFUNDED));
        assertEq(escrow.remainingAmount(), 0);
        
        console.log("Voucher refunded");
        
        vm.stopPrank();
    }
    
    /// @notice Test multiple merchants scenario
    function testMultipleMerchants() public {
        uint256 merchant2Id = 2;
        address merchant2Wallet = address(0x7); // Different from merchantWallet (0x6)
        
        vm.startPrank(operator);
        
        // Register second merchant
        registry.registerMerchant(merchant2Id, merchant2Wallet);
        registry.verifyMerchant(merchant2Id);
        
        // Create vouchers for different merchants
        bytes32 voucher1Id = keccak256("MERCH1_VOUCHER");
        bytes32 voucher2Id = keccak256("MERCH2_VOUCHER");
        
        VouchifyTypes.CreateEscrowParams memory params1 = VouchifyTypes.CreateEscrowParams({
            voucherId: voucher1Id,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: 50 * 1e6,
            platformFee: 2.5 * 1e6,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_M1",
            isGift: false
        });
        
        VouchifyTypes.CreateEscrowParams memory params2 = VouchifyTypes.CreateEscrowParams({
            voucherId: voucher2Id,
            buyer: buyer,
            merchantId: merchant2Id,
            amount: 75 * 1e6,
            platformFee: 3.75 * 1e6,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.USDC,
            externalTxId: "",
            isGift: false
        });
        
        factory.createEscrow(params1);
        factory.createEscrow(params2);
        
        // Buyer has 2 vouchers
        assertEq(voucher.balanceOf(buyer), 2);
        assertEq(factory.totalEscrows(), 2);
        
        // Redeem both
        factory.redeemVoucher(voucher1Id, 50 * 1e6);
        registry.creditBalance(MERCHANT_ID, 47.5 * 1e6, voucher1Id);
        
        factory.redeemVoucher(voucher2Id, 75 * 1e6);
        registry.creditBalance(merchant2Id, 71.25 * 1e6, voucher2Id);
        
        // Verify balances
        assertEq(registry.getPendingBalance(MERCHANT_ID), 47.5 * 1e6);
        assertEq(registry.getPendingBalance(merchant2Id), 71.25 * 1e6);
        
        console.log("Multiple merchants processed successfully");
        
        vm.stopPrank();
    }
    
    /// @notice Test gas costs
    function testGasCosts() public {
        bytes32 voucherId = keccak256("GAS_TEST");
        
        vm.startPrank(operator);
        
        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: voucherId,
            buyer: buyer,
            merchantId: MERCHANT_ID,
            amount: AMOUNT,
            platformFee: PLATFORM_FEE,
            expiresAt: block.timestamp + 30 days,
            paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
            externalTxId: "FLW_TX_GAS",
            isGift: false
        });
        
        uint256 gasStart = gasleft();
        factory.createEscrow(params);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for createEscrow (clone + mint):", gasUsed);
        // Should be around 200-300k gas on first call, much lower on subsequent
        
        // Create another to see gas difference
        bytes32 voucherId2 = keccak256("GAS_TEST_2");
        params.voucherId = voucherId2;
        
        gasStart = gasleft();
        factory.createEscrow(params);
        gasUsed = gasStart - gasleft();
        
        console.log("Gas used for second createEscrow:", gasUsed);
        
        vm.stopPrank();
    }
}
