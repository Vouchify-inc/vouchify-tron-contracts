// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { VouchifyPaymentWallet } from "../src/payment/VouchifyPaymentWallet.sol";
import { VouchifyPaymentWalletFactory } from "../src/payment/VouchifyPaymentWalletFactory.sol";
import { VouchifyErrors } from "../src/libraries/VouchifyErrors.sol";

/// @title VouchifyPaymentWalletTest
/// @notice Unit tests for VouchifyPaymentWallet clone template
contract VouchifyPaymentWalletTest is Test {
    VouchifyPaymentWallet public walletImpl;
    VouchifyPaymentWalletFactory public factory;
    ERC20Mock public usdc;

    address public admin = address(0x1);
    address public operator = address(0x2);
    address public pauser = address(0x3);
    address public coldWallet = address(0x4);
    address public buyer = address(0x5);
    address public anotherAddress = address(0x6);

    bytes32 public constant PAYMENT_ID_1 = keccak256("PAYMENT_001");
    bytes32 public constant PAYMENT_ID_2 = keccak256("PAYMENT_002");
    uint256 public constant EXPECTED_AMOUNT = 100 * 1e6; // 100 USDC

    function setUp() public {
        vm.startPrank(admin);

        // Deploy mock USDC
        usdc = new ERC20Mock("USDC", "USDC", 6);

        // Deploy wallet implementation
        walletImpl = new VouchifyPaymentWallet();

        // Deploy factory
        factory = new VouchifyPaymentWalletFactory(
            address(walletImpl),
            coldWallet,
            admin,
            operator,
            pauser
        );

        // Mint USDC to buyer for testing
        usdc.mint(buyer, 1000 * 1e6);

        vm.stopPrank();
    }

    // ============ Creation Tests ============

    function test_CreatePaymentWallet() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        assertNotEq(wallet, address(0));
        assertTrue(factory.walletExists(PAYMENT_ID_1));
        assertEq(factory.getWallet(PAYMENT_ID_1), wallet);
    }

    function test_CreatePaymentWallet_DeterministicAddress() public {
        address predictedAddr = factory.getWalletAddress(PAYMENT_ID_1);

        vm.prank(operator);
        address actualAddr = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        assertEq(predictedAddr, actualAddr);
    }

    function test_CreatePaymentWallet_OnlyOperator() public {
        vm.prank(buyer);
        vm.expectRevert();
        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, buyer);
    }

    function test_CreatePaymentWallet_ZeroToken() public {
        vm.prank(operator);
        vm.expectRevert(VouchifyErrors.ZeroAddress.selector);
        factory.createPaymentWallet(PAYMENT_ID_1, address(0), EXPECTED_AMOUNT, buyer);
    }

    function test_CreatePaymentWallet_ZeroAmount() public {
        vm.prank(operator);
        vm.expectRevert(VouchifyErrors.InvalidAmount.selector);
        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), 0, buyer);
    }

    function test_CreatePaymentWallet_ZeroBuyer() public {
        vm.prank(operator);
        vm.expectRevert(VouchifyErrors.ZeroAddress.selector);
        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, address(0));
    }

    function test_CreatePaymentWallet_DuplicatePaymentId() public {
        vm.startPrank(operator);

        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, buyer);

        vm.expectRevert(VouchifyErrors.AlreadyInitialized.selector);
        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, buyer);

        vm.stopPrank();
    }

    // ============ Payment Reception Tests ============

    function test_ReceivePayment() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        // Transfer USDC to wallet
        vm.prank(buyer);
        usdc.transfer(wallet, EXPECTED_AMOUNT);

        assertEq(usdc.balanceOf(wallet), EXPECTED_AMOUNT);
    }

    function test_IsPaymentReceived() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        VouchifyPaymentWallet paymentWallet = VouchifyPaymentWallet(wallet);

        // Before payment
        assertFalse(paymentWallet.isPaymentReceived());

        // After payment
        vm.prank(buyer);
        usdc.transfer(wallet, EXPECTED_AMOUNT);

        assertTrue(paymentWallet.isPaymentReceived());
    }

    function test_IsPaymentReceived_PartialAmount() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        VouchifyPaymentWallet paymentWallet = VouchifyPaymentWallet(wallet);

        // Transfer less than expected
        vm.prank(buyer);
        usdc.transfer(wallet, EXPECTED_AMOUNT / 2);

        assertFalse(paymentWallet.isPaymentReceived());
    }

    function test_GetBalance() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        VouchifyPaymentWallet paymentWallet = VouchifyPaymentWallet(wallet);

        assertEq(paymentWallet.getBalance(), 0);

        vm.prank(buyer);
        usdc.transfer(wallet, EXPECTED_AMOUNT);

        assertEq(paymentWallet.getBalance(), EXPECTED_AMOUNT);
    }

    // ============ Sweep Tests ============

    function test_Sweep() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        // Transfer USDC to wallet
        vm.prank(buyer);
        usdc.transfer(wallet, EXPECTED_AMOUNT);

        // Sweep
        vm.prank(operator);
        factory.sweepWallet(PAYMENT_ID_1);

        assertEq(usdc.balanceOf(wallet), 0);
        assertEq(usdc.balanceOf(coldWallet), EXPECTED_AMOUNT);
    }

    function test_Sweep_OnlyOperator() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        vm.prank(buyer);
        vm.expectRevert();
        factory.sweepWallet(PAYMENT_ID_1);
    }

    function test_Sweep_EmptyWallet() public {
        vm.prank(operator);
        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, buyer);

        // Sweep empty wallet (should work without error)
        vm.prank(operator);
        factory.sweepWallet(PAYMENT_ID_1);

        // Cold wallet should receive 0
        assertEq(usdc.balanceOf(coldWallet), 0);
    }

    function test_Sweep_AlreadySwept() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        vm.prank(buyer);
        usdc.transfer(wallet, EXPECTED_AMOUNT);

        // Sweep once
        vm.prank(operator);
        factory.sweepWallet(PAYMENT_ID_1);

        // Try to sweep again
        vm.prank(operator);
        vm.expectRevert(VouchifyErrors.WalletAlreadySwept.selector);
        factory.sweepWallet(PAYMENT_ID_1);
    }

    // ============ Batch Sweep Tests ============

    function test_SweepBatch() public {
        // Create multiple wallets
        vm.startPrank(operator);

        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, buyer);
        factory.createPaymentWallet(PAYMENT_ID_2, address(usdc), EXPECTED_AMOUNT, buyer);

        vm.stopPrank();

        // Transfer USDC to both wallets
        vm.startPrank(buyer);
        address wallet1 = factory.getWallet(PAYMENT_ID_1);
        address wallet2 = factory.getWallet(PAYMENT_ID_2);

        usdc.transfer(wallet1, EXPECTED_AMOUNT);
        usdc.transfer(wallet2, EXPECTED_AMOUNT);

        vm.stopPrank();

        // Sweep batch
        bytes32[] memory paymentIds = new bytes32[](2);
        paymentIds[0] = PAYMENT_ID_1;
        paymentIds[1] = PAYMENT_ID_2;

        vm.prank(operator);
        factory.sweepBatch(paymentIds);

        assertEq(usdc.balanceOf(coldWallet), EXPECTED_AMOUNT * 2);
    }

    function test_SweepBatch_PartialExisting() public {
        // Create two wallets but only fund one
        vm.startPrank(operator);
        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, buyer);
        factory.createPaymentWallet(PAYMENT_ID_2, address(usdc), EXPECTED_AMOUNT, buyer);
        vm.stopPrank();

        // Get wallet address first (as operator or any account)
        address wallet1 = factory.getWallet(PAYMENT_ID_1);
        
        // Only fund first wallet (as buyer)
        vm.prank(buyer);
        usdc.transfer(wallet1, EXPECTED_AMOUNT);

        // Sweep batch - should skip empty second wallet
        bytes32[] memory paymentIds = new bytes32[](2);
        paymentIds[0] = PAYMENT_ID_1;
        paymentIds[1] = PAYMENT_ID_2;

        vm.prank(operator);
        factory.sweepBatch(paymentIds);

        // Only first wallet's funds should be swept
        assertEq(usdc.balanceOf(coldWallet), EXPECTED_AMOUNT);
    }

    // ============ View Functions Tests ============

    function test_GetDetails() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        VouchifyPaymentWallet paymentWallet = VouchifyPaymentWallet(wallet);

        (
            bytes32 id,
            address tokenAddr,
            uint256 expectedAmt,
            uint256 currentBalance,
            bool paymentReceived,
            bool swept,
            address buyerAddr
        ) = paymentWallet.getDetails();

        assertEq(id, PAYMENT_ID_1);
        assertEq(tokenAddr, address(usdc));
        assertEq(expectedAmt, EXPECTED_AMOUNT);
        assertEq(currentBalance, 0);
        assertFalse(paymentReceived);
        assertFalse(swept);
        assertEq(buyerAddr, buyer);
    }

    function test_GetDetails_AfterPayment() public {
        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        vm.prank(buyer);
        usdc.transfer(wallet, EXPECTED_AMOUNT);

        VouchifyPaymentWallet paymentWallet = VouchifyPaymentWallet(wallet);

        (, , , uint256 currentBalance, bool paymentReceived, , ) = paymentWallet.getDetails();

        assertEq(currentBalance, EXPECTED_AMOUNT);
        assertTrue(paymentReceived);
    }

    // ============ Admin Tests ============

    function test_SetImplementation() public {
        VouchifyPaymentWallet newImpl = new VouchifyPaymentWallet();

        vm.prank(admin);
        factory.setImplementation(address(newImpl));

        assertEq(factory.implementation(), address(newImpl));
    }

    function test_SetImplementation_OnlyAdmin() public {
        VouchifyPaymentWallet newImpl = new VouchifyPaymentWallet();

        vm.prank(operator);
        vm.expectRevert();
        factory.setImplementation(address(newImpl));
    }

    function test_SetColdWallet() public {
        address newColdWallet = address(0x99);

        vm.prank(admin);
        factory.setColdWallet(newColdWallet);

        assertEq(factory.coldWallet(), newColdWallet);
    }

    function test_SetColdWallet_OnlyAdmin() public {
        vm.prank(operator);
        vm.expectRevert();
        factory.setColdWallet(address(0x99));
    }

    // ============ Pause Tests ============

    function test_Pause() public {
        vm.prank(pauser);
        factory.pause();

        vm.prank(operator);
        vm.expectRevert();
        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, buyer);
    }

    function test_Unpause() public {
        vm.prank(pauser);
        factory.pause();

        vm.prank(pauser);
        factory.unpause();

        vm.prank(operator);
        address wallet = factory.createPaymentWallet(
            PAYMENT_ID_1,
            address(usdc),
            EXPECTED_AMOUNT,
            buyer
        );

        assertNotEq(wallet, address(0));
    }

    // ============ State Tracking Tests ============

    function test_TotalWallets() public {
        assertEq(factory.totalWallets(), 0);

        vm.prank(operator);
        factory.createPaymentWallet(PAYMENT_ID_1, address(usdc), EXPECTED_AMOUNT, buyer);

        assertEq(factory.totalWallets(), 1);

        vm.prank(operator);
        factory.createPaymentWallet(PAYMENT_ID_2, address(usdc), EXPECTED_AMOUNT, buyer);

        assertEq(factory.totalWallets(), 2);
    }
}
