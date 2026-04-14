// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { VouchifyEscrow } from "../src/core/VouchifyEscrow.sol";
import { VouchifyEscrowFactory } from "../src/core/VouchifyEscrowFactory.sol";
import { VouchifyVoucher } from "../src/core/VouchifyVoucher.sol";
import { VouchifyTypes } from "../src/libraries/VouchifyTypes.sol";
import { VouchifyErrors } from "../src/libraries/VouchifyErrors.sol";

/// @title VouchifyEscrowFactoryTest
/// @notice Unit tests for VouchifyEscrowFactory with updated role system
contract VouchifyEscrowFactoryTest is Test {
    VouchifyEscrow public escrowImpl;
    VouchifyEscrowFactory public factory;
    VouchifyVoucher public voucher;

    address public admin = address(0x1);
    address public operator = address(0x2);
    address public pauser = address(0x3);
    address public buyer = address(0x4);
    address public unauthorized = address(0x6);

    bytes32 public constant VOUCHER_ID = keccak256("VOUCHER_001");
    uint256 public constant MERCHANT_ID = 1;
    uint256 public constant AMOUNT = 100 * 1e6; // 100 USDC
    uint256 public constant PLATFORM_FEE = 5 * 1e6; // 5 USDC

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

    // ============ Constructor Tests ============

    function test_ConstructorInitialization() public {
        assertEq(factory.implementation(), address(escrowImpl));
        assertTrue(factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(factory.hasRole(factory.OPERATOR_ROLE(), operator));
        assertTrue(factory.hasRole(factory.PAUSER_ROLE(), pauser));
    }

    function test_ConstructorRoles_AllDifferent() public {
        // Verify operator and pauser have different roles
        assertTrue(factory.hasRole(factory.OPERATOR_ROLE(), operator));
        assertFalse(factory.hasRole(factory.OPERATOR_ROLE(), pauser));
        assertFalse(factory.hasRole(factory.PAUSER_ROLE(), operator));
        assertTrue(factory.hasRole(factory.PAUSER_ROLE(), pauser));
    }

    function test_Constructor_ZeroImplementation() public {
        vm.prank(admin);
        vm.expectRevert(VouchifyErrors.ZeroAddress.selector);
        new VouchifyEscrowFactory(address(0), admin, operator, pauser);
    }

    // ============ Create Escrow Tests ============

    function test_CreateEscrow_ReturnsAllDetails() public {
        vm.prank(operator);
        (
            address escrowAddress,
            uint256 tokenId
        ) = factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );

        assertNotEq(escrowAddress, address(0));
        assertNotEq(tokenId, 0);
        
        // Verify data via escrow contract
        VouchifyEscrow escrow = VouchifyEscrow(escrowAddress);
        assertEq(escrow.voucherId(), VOUCHER_ID);
        assertEq(escrow.buyer(), buyer);
        assertEq(escrow.merchantId(), MERCHANT_ID);
        assertEq(escrow.amount(), AMOUNT);
    }

    function test_CreateEscrow_OperatorOnly() public {
        vm.prank(pauser);
        vm.expectRevert();
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );
    }

    function test_CreateEscrow_ZeroBuyer() public {
        vm.prank(operator);
        vm.expectRevert(VouchifyErrors.ZeroAddress.selector);
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: address(0),
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );
    }

    function test_CreateEscrow_ZeroAmount() public {
        vm.prank(operator);
        vm.expectRevert(VouchifyErrors.InvalidAmount.selector);
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: 0,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );
    }

    function test_CreateEscrow_InvalidExpiry() public {
        vm.prank(operator);
        vm.expectRevert(VouchifyErrors.InvalidTimestamp.selector);
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp - 1,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );
    }

    function test_CreateEscrow_DuplicateVoucher() public {
        vm.startPrank(operator);

        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );

        vm.expectRevert(VouchifyErrors.EscrowAlreadyExists.selector);
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );

        vm.stopPrank();
    }

    // ============ Pause Tests ============

    function test_Pause_PauserCan() public {
        vm.prank(pauser);
        factory.pause();

        vm.prank(operator);
        vm.expectRevert();
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );
    }

    function test_Unpause_PauserCan() public {
        vm.startPrank(pauser);
        factory.pause();
        factory.unpause();
        vm.stopPrank();

        vm.prank(operator);
        (address escrowAddr,) = factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );

        assertNotEq(escrowAddr, address(0));
    }

    // ============ Role Separation Tests ============

    function test_OperatorCannotSetImplementation() public {
        VouchifyEscrow newImpl = new VouchifyEscrow();

        vm.prank(operator);
        vm.expectRevert();
        factory.setImplementation(address(newImpl));
    }

    function test_PauserCannotCreateEscrow() public {
        vm.prank(pauser);
        vm.expectRevert();
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );
    }

    // ============ Admin Tests ============

    function test_SetImplementation_AdminOnly() public {
        VouchifyEscrow newImpl = new VouchifyEscrow();

        vm.prank(admin);
        factory.setImplementation(address(newImpl));

        assertEq(factory.implementation(), address(newImpl));
    }

    // ============ View Functions Tests ============

    function test_TotalEscrows() public {
        assertEq(factory.totalEscrows(), 0);

        vm.prank(operator);
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );

        assertEq(factory.totalEscrows(), 1);
    }

    function test_EscrowExists() public {
        assertFalse(factory.escrowExists(VOUCHER_ID));

        vm.prank(operator);
        factory.createEscrow(
            VouchifyTypes.CreateEscrowParams({
                voucherId: VOUCHER_ID,
                buyer: buyer,
                merchantId: MERCHANT_ID,
                amount: AMOUNT,
                platformFee: PLATFORM_FEE,
                expiresAt: block.timestamp + 30 days,
                paymentMethod: VouchifyTypes.PaymentMethod.FIAT,
                externalTxId: "FLW_TXN_123",
                isGift: false
            })
        );

        assertTrue(factory.escrowExists(VOUCHER_ID));
    }
}
