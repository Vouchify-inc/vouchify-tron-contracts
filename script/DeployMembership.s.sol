// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { VouchifyMembership } from "../src/core/VouchifyMembership.sol";
import { VouchifyMembershipFactory } from "../src/core/VouchifyMembershipFactory.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title DeployMembership
/// @notice Deploys only VouchifyMembership + Factory, then links to an existing VouchifyVoucher NFT.
/// @dev Usage: VOUCHER_NFT=0x... forge script script/DeployMembership.s.sol --rpc-url <alias> --broadcast --verify
///      Optionally set VOUCHER_ADMIN_KEY if the voucher admin is a different wallet.
contract DeployMembership is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address voucherNFT = vm.envAddress("VOUCHER_NFT");

        // Optional: separate admin key for granting FACTORY_ROLE on the voucher NFT
        // If not set, uses the deployer key (works when deployer == voucher admin)
        uint256 adminKey = vm.envOr("VOUCHER_ADMIN_KEY", deployerPrivateKey);
        address adminAddr = vm.addr(adminKey);

        console.log("Deploying Membership contracts only...");
        console.log("Deployer:", deployer);
        console.log("Voucher admin:", adminAddr);
        console.log("Existing VouchifyVoucher:", voucherNFT);

        // ── Step 1: Deploy membership contracts using deployer key ──
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Membership Implementation
        VouchifyMembership membershipImpl = new VouchifyMembership();
        console.log("VouchifyMembership Implementation:", address(membershipImpl));

        // 2. Deploy Membership Factory
        VouchifyMembershipFactory membershipFactory = new VouchifyMembershipFactory(
            address(membershipImpl),
            deployer,  // admin
            deployer,  // operator
            deployer   // pauser
        );
        console.log("VouchifyMembershipFactory:", address(membershipFactory));

        // 3. Link factory to existing voucher NFT
        membershipFactory.setVoucherContract(voucherNFT);
        console.log("Linked MembershipFactory -> VoucherNFT");

        vm.stopBroadcast();

        // ── Step 2: Grant FACTORY_ROLE using the voucher admin key ──
        vm.startBroadcast(adminKey);

        // 4. Grant FACTORY_ROLE to membership factory on the voucher NFT
        bytes32 FACTORY_ROLE = keccak256("FACTORY_ROLE");
        AccessControl(voucherNFT).grantRole(FACTORY_ROLE, address(membershipFactory));
        console.log("Granted FACTORY_ROLE to MembershipFactory on VoucherNFT");

        vm.stopBroadcast();

        console.log("\n========== MEMBERSHIP DEPLOYMENT SUMMARY ==========");
        console.log("VouchifyMembership (Implementation):", address(membershipImpl));
        console.log("VouchifyMembershipFactory:", address(membershipFactory));
        console.log("Linked VoucherNFT:", voucherNFT);
        console.log("====================================================");
    }
}
