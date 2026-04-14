// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { VouchifyEscrow } from "../src/core/VouchifyEscrow.sol";
import { VouchifyEscrowFactory } from "../src/core/VouchifyEscrowFactory.sol";
import { VouchifyVoucher } from "../src/core/VouchifyVoucher.sol";
import { VouchifyPaymentWallet } from "../src/payment/VouchifyPaymentWallet.sol";
import { VouchifyPaymentWalletFactory } from "../src/payment/VouchifyPaymentWalletFactory.sol";
import { VouchifyMembership } from "../src/core/VouchifyMembership.sol";
import { VouchifyMembershipFactory } from "../src/core/VouchifyMembershipFactory.sol";
import { VouchifyTypes } from "../src/libraries/VouchifyTypes.sol";

/// @title ValidateTronTestnet
/// @notice Deploys a validation stack and proves deterministic clone predictions on Tron testnet.
/// @dev This script assumes Tron USDT is the only ERC-20 payment token in scope. It does not attempt
///      to validate native TRX payment flows, because TRX is only used to pay deployment costs.
contract ValidateTronTestnet is Script {
    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    struct ValidationConfig {
        address admin;
        address coldWallet;
        address validationBuyer;
        address tronUsdt;
        uint256 merchantId;
        uint256 paymentAmount;
        uint256 membershipCredits;
    }

    struct ValidationDeployment {
        VouchifyEscrowFactory escrowFactory;
        VouchifyMembershipFactory membershipFactory;
        VouchifyPaymentWalletFactory walletFactory;
        VouchifyVoucher voucher;
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        ValidationConfig memory config = _loadConfig();

        bytes32 voucherId = keccak256("TRON_TESTNET_ESCROW_VALIDATION");
        bytes32 membershipId = keccak256("TRON_TESTNET_MEMBERSHIP_VALIDATION");
        bytes32 paymentId = keccak256("TRON_TESTNET_PAYMENT_WALLET_VALIDATION");
        uint256 expiresAt = block.timestamp + 30 days;

        console.log("Running Tron testnet validation...");
        console.log("Deployer / Operator:", deployer);
        console.log("Admin:", config.admin);
        console.log("Cold Wallet:", config.coldWallet);
        console.log("Validation Buyer:", config.validationBuyer);
        console.log("Tron USDT:", config.tronUsdt);

        vm.startBroadcast(deployerPrivateKey);

        ValidationDeployment memory deployment = _deployValidationStack(config, deployer);

        _validateEscrowClone(
            deployment.escrowFactory,
            voucherId,
            config.validationBuyer,
            config.merchantId,
            config.paymentAmount,
            expiresAt,
            deployer
        );
        _validateMembershipClone(
            deployment.membershipFactory,
            membershipId,
            config.validationBuyer,
            config.merchantId,
            config.membershipCredits,
            config.paymentAmount,
            expiresAt,
            deployer
        );
        _validatePaymentWalletClone(
            deployment.walletFactory,
            paymentId,
            config.tronUsdt,
            config.paymentAmount,
            config.validationBuyer
        );

        if (config.admin != deployer) {
            _grantValidationAdmins(deployment, config.admin);
        }

        vm.stopBroadcast();

        console.log("Validation completed successfully.");
        console.log("Escrow factory:", address(deployment.escrowFactory));
        console.log("Membership factory:", address(deployment.membershipFactory));
        console.log("Payment wallet factory:", address(deployment.walletFactory));
        console.log("Voucher NFT:", address(deployment.voucher));
    }

    function _loadConfig() internal view returns (ValidationConfig memory config) {
        config.admin = vm.envAddress("ADMIN_WALLET");
        config.coldWallet = vm.envAddress("COLD_WALLET");
        config.validationBuyer = vm.envAddress("VALIDATION_BUYER");
        config.tronUsdt = vm.envAddress("TRON_USDT_TOKEN");
        config.merchantId = vm.envUint("VALIDATION_MERCHANT_ID");
        config.paymentAmount = vm.envUint("VALIDATION_PAYMENT_AMOUNT");
        config.membershipCredits = vm.envUint("VALIDATION_MEMBERSHIP_CREDITS");

        require(config.admin != address(0), "admin required");
        require(config.coldWallet != address(0), "cold wallet required");
        require(config.validationBuyer != address(0), "validation buyer required");
        require(config.tronUsdt != address(0), "tron usdt required");
        require(config.paymentAmount > 0, "payment amount required");
        require(config.membershipCredits > 0, "membership credits required");
    }

    function _deployValidationStack(
        ValidationConfig memory config,
        address deployer
    ) internal returns (ValidationDeployment memory deployment) {
        address escrowImpl = address(new VouchifyEscrow());
        deployment.voucher = new VouchifyVoucher(
            "Vouchify Voucher",
            "VOUCH",
            deployer,
            "https://api.usevouchify.com/voucher/"
        );
        deployment.escrowFactory = new VouchifyEscrowFactory(
            escrowImpl,
            deployer,
            deployer,
            deployer
        );
        deployment.walletFactory = new VouchifyPaymentWalletFactory(
            address(new VouchifyPaymentWallet()),
            config.coldWallet,
            deployer,
            deployer,
            deployer
        );
        deployment.membershipFactory = new VouchifyMembershipFactory(
            address(new VouchifyMembership()),
            deployer,
            deployer,
            deployer
        );

        deployment.escrowFactory.setVoucherContract(address(deployment.voucher));
        deployment.voucher.setFactory(address(deployment.escrowFactory));
        deployment.membershipFactory.setVoucherContract(address(deployment.voucher));
        deployment.voucher.grantRole(FACTORY_ROLE, address(deployment.membershipFactory));
    }

    function _grantValidationAdmins(ValidationDeployment memory deployment, address admin) internal {
        bytes32 defaultAdmin = 0x00;
        bytes32 pauserRole = keccak256("PAUSER_ROLE");

        deployment.voucher.grantRole(defaultAdmin, admin);
        deployment.voucher.grantRole(pauserRole, admin);
        deployment.escrowFactory.grantRole(defaultAdmin, admin);
        deployment.walletFactory.grantRole(defaultAdmin, admin);
        deployment.membershipFactory.grantRole(defaultAdmin, admin);
    }

    function _validateEscrowClone(
        VouchifyEscrowFactory escrowFactory,
        bytes32 voucherId,
        address buyer,
        uint256 merchantId,
        uint256 amount,
        uint256 expiresAt,
        address operator
    ) internal {
        address predictedEscrow = escrowFactory.getEscrowAddress(voucherId);

        VouchifyTypes.CreateEscrowParams memory params = VouchifyTypes.CreateEscrowParams({
            voucherId: voucherId,
            buyer: buyer,
            merchantId: merchantId,
            amount: amount,
            platformFee: 0,
            expiresAt: expiresAt,
            paymentMethod: VouchifyTypes.PaymentMethod.USDT,
            externalTxId: "TRON_TESTNET_ESCROW_PAYMENT",
            isGift: false
        });

        (address actualEscrow, uint256 tokenId) = escrowFactory.createEscrow(params);
        require(predictedEscrow == actualEscrow, "escrow clone mismatch");

        VouchifyEscrow escrow = VouchifyEscrow(actualEscrow);
        require(escrow.tokenId() == tokenId, "escrow token mismatch");
        require(escrow.currentOwner() == buyer, "escrow owner mismatch");

        uint256 remaining = escrowFactory.redeemVoucher(voucherId, amount / 2);
        require(remaining == amount - (amount / 2), "escrow redemption mismatch");

        VouchifyTypes.Redemption memory redemption = escrow.getRedemption(0);
        require(redemption.redeemedBy == operator, "escrow redeemer mismatch");

        console.log("Escrow validation passed:", actualEscrow);
    }

    function _validateMembershipClone(
        VouchifyMembershipFactory membershipFactory,
        bytes32 membershipId,
        address buyer,
        uint256 merchantId,
        uint256 totalCredits,
        uint256 paymentAmount,
        uint256 expiresAt,
        address operator
    ) internal {
        address predictedMembership = membershipFactory.getMembershipAddress(membershipId);

        VouchifyTypes.CreateMembershipParams memory params = VouchifyTypes.CreateMembershipParams({
            membershipId: membershipId,
            buyer: buyer,
            merchantId: merchantId,
            totalCredits: totalCredits,
            platformFee: paymentAmount / 20,
            expiresAt: expiresAt,
            paymentMethod: VouchifyTypes.PaymentMethod.USDT,
            externalTxId: "TRON_TESTNET_MEMBERSHIP_PAYMENT"
        });

        (address actualMembership, uint256 tokenId) = membershipFactory.createMembership(params);
        require(predictedMembership == actualMembership, "membership clone mismatch");

        VouchifyMembership membership = VouchifyMembership(actualMembership);
        require(membership.tokenId() == tokenId, "membership token mismatch");
        require(membership.currentOwner() == buyer, "membership owner mismatch");

        uint256 remainingCredits = membershipFactory.redeemCredit(membershipId);
        require(remainingCredits == totalCredits - 1, "membership redemption mismatch");

        VouchifyTypes.CreditRedemption memory redemption = membership.getRedemption(0);
        require(redemption.redeemedBy == operator, "membership redeemer mismatch");

        console.log("Membership validation passed:", actualMembership);
    }

    function _validatePaymentWalletClone(
        VouchifyPaymentWalletFactory walletFactory,
        bytes32 paymentId,
        address tronUsdt,
        uint256 expectedAmount,
        address buyer
    ) internal {
        address predictedWallet = walletFactory.getWalletAddress(paymentId);
        address actualWallet = walletFactory.createPaymentWallet(paymentId, tronUsdt, expectedAmount, buyer);
        require(predictedWallet == actualWallet, "payment wallet clone mismatch");

        VouchifyPaymentWallet paymentWallet = VouchifyPaymentWallet(actualWallet);
        require(paymentWallet.getToken() == tronUsdt, "payment token mismatch");
        require(paymentWallet.expectedAmount() == expectedAmount, "payment amount mismatch");
        require(paymentWallet.buyer() == buyer, "payment buyer mismatch");

        console.log("Payment wallet validation passed:", actualWallet);
    }
}