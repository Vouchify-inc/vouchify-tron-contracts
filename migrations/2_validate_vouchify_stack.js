const VouchifyEscrow = artifacts.require("VouchifyEscrow");
const VouchifyEscrowFactory = artifacts.require("VouchifyEscrowFactory");
const VouchifyVoucher = artifacts.require("VouchifyVoucher");
const VouchifyPaymentWallet = artifacts.require("VouchifyPaymentWallet");
const VouchifyPaymentWalletFactory = artifacts.require("VouchifyPaymentWalletFactory");
const VouchifyMembership = artifacts.require("VouchifyMembership");
const VouchifyMembershipFactory = artifacts.require("VouchifyMembershipFactory");

function requireEnv(name, fallback) {
    const value = process.env[name] || fallback;
    if (!value) {
        throw new Error(`Missing required env: ${name}`);
    }
    return value;
}

function normalizeHexAddress(value) {
    if (!value) {
        return value;
    }

    const lowered = value.toLowerCase();
    if (lowered.startsWith("41") && lowered.length === 42) {
        return lowered;
    }
    if (lowered.startsWith("0x") && lowered.length === 42) {
        return `41${lowered.slice(2)}`;
    }
    return tronWeb.address.toHex(value).toLowerCase();
}

function sameAddress(left, right) {
    return normalizeHexAddress(left) === normalizeHexAddress(right);
}

function recordDeterministicCheck(warnings, label, predicted, actual) {
    if (sameAddress(predicted, actual)) {
        console.log(`${label} predicted address matches actual clone address.`);
        return;
    }

    const warning = `${label} predicted address mismatch: ${predicted} vs ${actual}`;
    warnings.push(warning);
    console.warn(`WARNING: ${warning}`);
}

function tupleField(tupleValue, index, key) {
    if (tupleValue && typeof tupleValue === "object" && key in tupleValue) {
        return tupleValue[key];
    }
    return tupleValue[index];
}

module.exports = async function (deployer, network, from) {
    if (!["shasta", "nile", "development", "mainnet"].includes(network)) {
        throw new Error(`Unsupported TronBox network for validation: ${network}`);
    }

    const admin = requireEnv("ADMIN_WALLET", from);
    const coldWallet = requireEnv("COLD_WALLET", from);
    const validationBuyer = requireEnv("VALIDATION_BUYER");
    const tronUsdt = requireEnv("TRON_USDT_TOKEN");
    const merchantId = Number(requireEnv("VALIDATION_MERCHANT_ID", "1"));
    const paymentAmount = Number(requireEnv("VALIDATION_PAYMENT_AMOUNT", "1000000"));
    const membershipCredits = Number(requireEnv("VALIDATION_MEMBERSHIP_CREDITS", "10"));
    const expiresAt = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
    const warnings = [];

    const voucherId = tronWeb.sha3("TRONBOX_ESCROW_VALIDATION");
    const membershipId = tronWeb.sha3("TRONBOX_MEMBERSHIP_VALIDATION");
    const paymentId = tronWeb.sha3("TRONBOX_PAYMENT_WALLET_VALIDATION");

    console.log(`Using TronBox network '${network}'`);
    console.log(`Validation buyer: ${validationBuyer}`);
    console.log(`Validation merchant id: ${merchantId}`);
    console.log(`Validation payment amount: ${paymentAmount}`);
    console.log(`Validation membership credits: ${membershipCredits}`);
    console.log(`Tron USDT token: ${tronUsdt}`);

    await deployer.deploy(VouchifyEscrow);
    await deployer.deploy(VouchifyVoucher, "Vouchify Voucher", "VOUCH", from, "https://api.usevouchify.com/voucher/");
    await deployer.deploy(VouchifyEscrowFactory, VouchifyEscrow.address, from, from, from);
    await deployer.deploy(VouchifyPaymentWallet);
    await deployer.deploy(VouchifyPaymentWalletFactory, VouchifyPaymentWallet.address, coldWallet, from, from, from);
    await deployer.deploy(VouchifyMembership);
    await deployer.deploy(VouchifyMembershipFactory, VouchifyMembership.address, from, from, from);

    const voucher = await VouchifyVoucher.deployed();
    const escrowFactory = await VouchifyEscrowFactory.deployed();
    const walletFactory = await VouchifyPaymentWalletFactory.deployed();
    const membershipFactory = await VouchifyMembershipFactory.deployed();

    await escrowFactory.setVoucherContract(voucher.address, { from });
    await voucher.setFactory(escrowFactory.address, { from });
    await membershipFactory.setVoucherContract(voucher.address, { from });
    const factoryRole = await voucher.FACTORY_ROLE();
    await voucher.grantRole(factoryRole, membershipFactory.address, { from });

    const predictedEscrow = await escrowFactory.getEscrowAddress.call(voucherId);
    await escrowFactory.createEscrow(
        [voucherId, validationBuyer, merchantId, paymentAmount, 0, expiresAt, 2, "TRONBOX_ESCROW_PAYMENT", false],
        { from }
    );
    const actualEscrow = await escrowFactory.getEscrowByVoucherId.call(voucherId);
    recordDeterministicCheck(warnings, "Escrow", predictedEscrow, actualEscrow);

    const escrow = await VouchifyEscrow.at(actualEscrow);
    const escrowOwner = await escrow.currentOwner.call();
    if (!sameAddress(escrowOwner, validationBuyer)) {
        throw new Error(`Escrow owner mismatch: ${escrowOwner}`);
    }
    await escrowFactory.redeemVoucher(voucherId, Math.floor(paymentAmount / 2), { from });
    const escrowRedemption = await escrow.getRedemption.call(0);
    const escrowRedeemedBy = tupleField(escrowRedemption, 2, "redeemedBy");
    if (!sameAddress(escrowRedeemedBy, from)) {
        throw new Error(`Escrow redemption actor mismatch: ${escrowRedeemedBy}`);
    }

    const predictedMembership = await membershipFactory.getMembershipAddress.call(membershipId);
    await membershipFactory.createMembership(
        [membershipId, validationBuyer, merchantId, membershipCredits, Math.floor(paymentAmount / 20), expiresAt, 2, "TRONBOX_MEMBERSHIP_PAYMENT"],
        { from }
    );
    const actualMembership = await membershipFactory.getMembershipByMembershipId.call(membershipId);
    recordDeterministicCheck(warnings, "Membership", predictedMembership, actualMembership);

    const membership = await VouchifyMembership.at(actualMembership);
    const membershipOwner = await membership.currentOwner.call();
    if (!sameAddress(membershipOwner, validationBuyer)) {
        throw new Error(`Membership owner mismatch: ${membershipOwner}`);
    }
    await membershipFactory.redeemCredit(membershipId, { from });
    const membershipRedemption = await membership.getRedemption.call(0);
    const membershipRedeemedBy = tupleField(membershipRedemption, 1, "redeemedBy");
    if (!sameAddress(membershipRedeemedBy, from)) {
        throw new Error(`Membership redemption actor mismatch: ${membershipRedeemedBy}`);
    }

    const predictedWallet = await walletFactory.getWalletAddress.call(paymentId);
    await walletFactory.createPaymentWallet(paymentId, tronUsdt, paymentAmount, validationBuyer, { from });
    const actualWallet = await walletFactory.getWallet.call(paymentId);
    recordDeterministicCheck(warnings, "Payment wallet", predictedWallet, actualWallet);

    const paymentWallet = await VouchifyPaymentWallet.at(actualWallet);
    const walletToken = await paymentWallet.getToken.call();
    const walletBuyer = await paymentWallet.buyer.call();
    if (!sameAddress(walletToken, tronUsdt)) {
        throw new Error(`Payment wallet token mismatch: ${walletToken}`);
    }
    if (!sameAddress(walletBuyer, validationBuyer)) {
        throw new Error(`Payment wallet buyer mismatch: ${walletBuyer}`);
    }

    if (!sameAddress(admin, from)) {
        const defaultAdminRole = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const pauserRole = await voucher.PAUSER_ROLE();
        await voucher.grantRole(defaultAdminRole, admin, { from });
        await voucher.grantRole(pauserRole, admin, { from });
        await escrowFactory.grantRole(defaultAdminRole, admin, { from });
        await walletFactory.grantRole(defaultAdminRole, admin, { from });
        await membershipFactory.grantRole(defaultAdminRole, admin, { from });
    }

    console.log("Validation stack deployed successfully.");
    if (warnings.length > 0) {
        console.log("Deterministic clone warnings observed on this network:");
        for (const warning of warnings) {
            console.log(`- ${warning}`);
        }
    }
    console.log(`Voucher NFT: ${voucher.address}`);
    console.log(`Escrow factory: ${escrowFactory.address}`);
    console.log(`Membership factory: ${membershipFactory.address}`);
    console.log(`Payment wallet factory: ${walletFactory.address}`);
};