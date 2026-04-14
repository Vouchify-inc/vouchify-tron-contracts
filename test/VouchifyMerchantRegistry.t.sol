// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { VouchifyMerchantRegistry } from "../src/registry/VouchifyMerchantRegistry.sol";
import { VouchifyTypes } from "../src/libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../src/libraries/VouchifyErrors.sol";

/// @title VouchifyMerchantRegistryTest
/// @notice Unit tests for VouchifyMerchantRegistry
contract VouchifyMerchantRegistryTest is Test {
    VouchifyMerchantRegistry public registry;
    
    address public admin = address(0x1);
    address public operator = address(0x2);
    address public merchantWallet = address(0x3);
    address public merchantWallet2 = address(0x4);
    
    uint256 public constant MERCHANT_ID = 1;
    uint256 public constant MERCHANT_ID_2 = 2;
    
    function setUp() public {
        vm.prank(admin);
        registry = new VouchifyMerchantRegistry(admin);
    }
    
    function testRegisterMerchant() public {
        vm.prank(admin);
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        VouchifyTypes.MerchantRecord memory merchant = registry.getMerchant(MERCHANT_ID);
        
        assertEq(merchant.merchantId, MERCHANT_ID);
        assertEq(merchant.walletAddress, merchantWallet);
        assertFalse(merchant.isVerified);
        assertFalse(merchant.isActive);
        assertEq(merchant.totalEarned, 0);
        assertEq(merchant.pendingBalance, 0);
        assertTrue(merchant.registeredAt > 0);
        
        assertEq(registry.getMerchantByWallet(merchantWallet), MERCHANT_ID);
        assertEq(registry.totalMerchants(), 1);
    }
    
    function testVerifyMerchant() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.verifyMerchant(MERCHANT_ID);
        
        VouchifyTypes.MerchantRecord memory merchant = registry.getMerchant(MERCHANT_ID);
        assertTrue(merchant.isVerified);
        assertTrue(merchant.isActive);
        assertTrue(registry.isMerchantActive(MERCHANT_ID));
        
        vm.stopPrank();
    }
    
    function testDeactivateMerchant() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.verifyMerchant(MERCHANT_ID);
        registry.deactivateMerchant(MERCHANT_ID);
        
        VouchifyTypes.MerchantRecord memory merchant = registry.getMerchant(MERCHANT_ID);
        assertTrue(merchant.isVerified);
        assertFalse(merchant.isActive);
        assertFalse(registry.isMerchantActive(MERCHANT_ID));
        
        vm.stopPrank();
    }
    
    function testReactivateMerchant() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.verifyMerchant(MERCHANT_ID);
        registry.deactivateMerchant(MERCHANT_ID);
        registry.activateMerchant(MERCHANT_ID);
        
        assertTrue(registry.isMerchantActive(MERCHANT_ID));
        
        vm.stopPrank();
    }
    
    function testCannotActivateUnverifiedMerchant() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        vm.expectRevert(VouchifyErrors.MerchantNotVerified.selector);
        registry.activateMerchant(MERCHANT_ID);
        
        vm.stopPrank();
    }
    
    function testUpdateMerchantWallet() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.updateMerchantWallet(MERCHANT_ID, merchantWallet2);
        
        VouchifyTypes.MerchantRecord memory merchant = registry.getMerchant(MERCHANT_ID);
        assertEq(merchant.walletAddress, merchantWallet2);
        assertEq(registry.getMerchantByWallet(merchantWallet2), MERCHANT_ID);
        assertEq(registry.getMerchantByWallet(merchantWallet), 0);
        
        vm.stopPrank();
    }
    
    function testCreditBalance() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        bytes32 voucherId = keccak256("VOUCHER_001");
        uint256 creditAmount = 100 * 1e6;
        
        registry.creditBalance(MERCHANT_ID, creditAmount, voucherId);
        
        VouchifyTypes.MerchantRecord memory merchant = registry.getMerchant(MERCHANT_ID);
        assertEq(merchant.pendingBalance, creditAmount);
        assertEq(merchant.totalEarned, creditAmount);
        
        // Credit more
        registry.creditBalance(MERCHANT_ID, 50 * 1e6, keccak256("VOUCHER_002"));
        
        merchant = registry.getMerchant(MERCHANT_ID);
        assertEq(merchant.pendingBalance, 150 * 1e6);
        assertEq(merchant.totalEarned, 150 * 1e6);
        
        vm.stopPrank();
    }
    
    function testDebitBalance() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.creditBalance(MERCHANT_ID, 100 * 1e6, keccak256("VOUCHER_001"));
        
        registry.debitBalance(MERCHANT_ID, 40 * 1e6, "withdrawal");
        
        VouchifyTypes.MerchantRecord memory merchant = registry.getMerchant(MERCHANT_ID);
        assertEq(merchant.pendingBalance, 60 * 1e6);
        assertEq(merchant.withdrawnTotal, 40 * 1e6);
        assertEq(merchant.totalEarned, 100 * 1e6); // Total earned unchanged
        
        vm.stopPrank();
    }
    
    function testCannotDebitMoreThanBalance() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.creditBalance(MERCHANT_ID, 100 * 1e6, keccak256("VOUCHER_001"));
        
        vm.expectRevert(VouchifyErrors.WithdrawalExceedsBalance.selector);
        registry.debitBalance(MERCHANT_ID, 150 * 1e6, "withdrawal");
        
        vm.stopPrank();
    }
    
    function testCannotRegisterDuplicateMerchant() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        vm.expectRevert(VouchifyErrors.MerchantAlreadyRegistered.selector);
        registry.registerMerchant(MERCHANT_ID, merchantWallet2);
        
        vm.stopPrank();
    }
    
    function testCannotRegisterDuplicateWallet() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        vm.expectRevert(VouchifyErrors.MerchantAlreadyRegistered.selector);
        registry.registerMerchant(MERCHANT_ID_2, merchantWallet);
        
        vm.stopPrank();
    }
    
    function testCannotUpdateToUsedWallet() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.registerMerchant(MERCHANT_ID_2, merchantWallet2);
        
        vm.expectRevert(VouchifyErrors.MerchantAlreadyRegistered.selector);
        registry.updateMerchantWallet(MERCHANT_ID, merchantWallet2);
        
        vm.stopPrank();
    }
    
    function testGetPendingBalance() public {
        vm.startPrank(admin);
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        registry.creditBalance(MERCHANT_ID, 100 * 1e6, keccak256("VOUCHER_001"));
        
        assertEq(registry.getPendingBalance(MERCHANT_ID), 100 * 1e6);
        
        vm.stopPrank();
    }
    
    function testMerchantExists() public {
        vm.startPrank(admin);
        
        assertFalse(registry.merchantExists(MERCHANT_ID));
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        assertTrue(registry.merchantExists(MERCHANT_ID));
        
        vm.stopPrank();
    }
    
    function testPauseAndUnpause() public {
        vm.startPrank(admin);
        
        registry.pause();
        
        vm.expectRevert();
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        registry.unpause();
        
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        vm.stopPrank();
    }
    
    function testRoleBasedAccess() public {
        address unauthorized = address(0x99);
        
        vm.prank(unauthorized);
        vm.expectRevert();
        registry.registerMerchant(MERCHANT_ID, merchantWallet);
        
        vm.prank(unauthorized);
        vm.expectRevert();
        registry.creditBalance(MERCHANT_ID, 100, keccak256("test"));
    }
}
