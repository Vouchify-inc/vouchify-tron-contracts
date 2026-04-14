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

/// @title DeployVouchify
/// @notice Deployment script for Vouchify contracts
contract DeployVouchify is Script {
    // Deployment addresses (to be filled after deployment)
    address public escrowImpl;
    address public escrowFactory;
    address public voucherNFT;
    address public paymentWalletImpl;
    address public paymentWalletFactory;
    address public membershipImpl;
    address public membershipFactory;

    function run() external {
        // Get deployer from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address admin = vm.envAddress("ADMIN_WALLET");
        address coldWallet = vm.envAddress("COLD_WALLET");
        
        console.log("Deploying Vouchify contracts...");
        console.log("Deployer / Operator:", deployer);
        console.log("Admin:", admin);
        console.log("Cold Wallet:", coldWallet);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // ============ PHASE 1: Deploy contracts (deployer as temporary admin) ============
        
        // 1. Deploy Escrow Implementation
        VouchifyEscrow escrowImplContract = new VouchifyEscrow();
        escrowImpl = address(escrowImplContract);
        console.log("VouchifyEscrow Implementation:", escrowImpl);
        
        // 2. Deploy Voucher NFT (deployer as temp admin for linking)
        VouchifyVoucher voucherContract = new VouchifyVoucher(
            "Vouchify Voucher",
            "VOUCH",
            deployer,  // temp admin = deployer (for linking operations)
            "https://api.usevouchify.com/voucher/"
        );
        voucherNFT = address(voucherContract);
        console.log("VouchifyVoucher NFT:", voucherNFT);
        
        // 3. Deploy Escrow Factory (deployer as temp admin for linking)
        VouchifyEscrowFactory factoryContract = new VouchifyEscrowFactory(
            escrowImpl,
            deployer,  // temp admin = deployer (for setVoucherContract)
            deployer,  // operator = deployer
            deployer   // pauser = deployer
        );
        escrowFactory = address(factoryContract);
        console.log("VouchifyEscrowFactory:", escrowFactory);
        
        // 4. Deploy Payment Wallet Implementation
        VouchifyPaymentWallet paymentWalletImplContract = new VouchifyPaymentWallet();
        paymentWalletImpl = address(paymentWalletImplContract);
        console.log("VouchifyPaymentWallet Implementation:", paymentWalletImpl);
        
        // 5. Deploy Payment Wallet Factory (deployer as temp admin)
        VouchifyPaymentWalletFactory paymentFactoryContract = new VouchifyPaymentWalletFactory(
            paymentWalletImpl,
            coldWallet,  // cold wallet receives swept funds
            deployer,    // temp admin = deployer
            deployer,    // operator = deployer
            deployer     // pauser = deployer
        );
        paymentWalletFactory = address(paymentFactoryContract);
        console.log("VouchifyPaymentWalletFactory:", paymentWalletFactory);
        
        // 6. Deploy Membership Implementation
        VouchifyMembership membershipImplContract = new VouchifyMembership();
        membershipImpl = address(membershipImplContract);
        console.log("VouchifyMembership Implementation:", membershipImpl);
        
        // 7. Deploy Membership Factory (deployer as temp admin for linking)
        VouchifyMembershipFactory membershipFactoryContract = new VouchifyMembershipFactory(
            membershipImpl,
            deployer,  // temp admin = deployer (for setVoucherContract)
            deployer,  // operator = deployer
            deployer   // pauser = deployer
        );
        membershipFactory = address(membershipFactoryContract);
        console.log("VouchifyMembershipFactory:", membershipFactory);
        
        // ============ PHASE 2: Link contracts (requires DEFAULT_ADMIN_ROLE) ============
        
        factoryContract.setVoucherContract(voucherNFT);
        voucherContract.setFactory(escrowFactory); // also grants FACTORY_ROLE to escrowFactory
        membershipFactoryContract.setVoucherContract(voucherNFT);
        
        // Grant FACTORY_ROLE to membership factory so it can mint NFTs
        bytes32 FACTORY_ROLE = keccak256("FACTORY_ROLE");
        voucherContract.grantRole(FACTORY_ROLE, membershipFactory);
        
        console.log("Contracts linked successfully!");
        
        // ============ PHASE 3: Transfer admin role to real admin wallet ============
        
        bytes32 DEFAULT_ADMIN = 0x00; // DEFAULT_ADMIN_ROLE = 0x00
        bytes32 PAUSER_ROLE = keccak256("PAUSER_ROLE");
        
        // VouchifyVoucher: grant admin + pauser to admin wallet, renounce deployer's admin
        voucherContract.grantRole(DEFAULT_ADMIN, admin);
        voucherContract.grantRole(PAUSER_ROLE, admin);
        voucherContract.renounceRole(DEFAULT_ADMIN, deployer);
        // deployer keeps PAUSER_ROLE on VoucherNFT (granted in constructor)
        
        // VouchifyEscrowFactory: grant admin to admin wallet, renounce deployer's admin
        factoryContract.grantRole(DEFAULT_ADMIN, admin);
        factoryContract.renounceRole(DEFAULT_ADMIN, deployer);
        // deployer keeps OPERATOR_ROLE + PAUSER_ROLE
        
        // VouchifyPaymentWalletFactory: grant admin to admin wallet, renounce deployer's admin
        paymentFactoryContract.grantRole(DEFAULT_ADMIN, admin);
        paymentFactoryContract.renounceRole(DEFAULT_ADMIN, deployer);
        // deployer keeps OPERATOR_ROLE + PAUSER_ROLE
        
        // VouchifyMembershipFactory: grant admin to admin wallet, renounce deployer's admin
        membershipFactoryContract.grantRole(DEFAULT_ADMIN, admin);
        membershipFactoryContract.renounceRole(DEFAULT_ADMIN, deployer);
        // deployer keeps OPERATOR_ROLE + PAUSER_ROLE
        
        console.log("Admin role transferred to admin wallet!");
        console.log("Deployer admin role renounced on all contracts!");
        
        vm.stopBroadcast();
        
        // Output deployment summary
        console.log("\n========== DEPLOYMENT SUMMARY ==========");
        console.log("VouchifyEscrow (Implementation):", escrowImpl);
        console.log("VouchifyEscrowFactory:", escrowFactory);
        console.log("VouchifyVoucher (NFT):", voucherNFT);
        console.log("VouchifyPaymentWallet (Implementation):", paymentWalletImpl);
        console.log("VouchifyPaymentWalletFactory:", paymentWalletFactory);
        console.log("VouchifyMembership (Implementation):", membershipImpl);
        console.log("VouchifyMembershipFactory:", membershipFactory);
        console.log("==========================================");
        console.log("\nRoles:");
        console.log("  Admin (DEFAULT_ADMIN_ROLE):", admin);
        console.log("  Operator (OPERATOR_ROLE):", deployer);
        console.log("  Pauser (PAUSER_ROLE):", deployer);
        console.log("  Cold Wallet:", coldWallet);
    }
}
