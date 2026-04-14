# Tron Deployment Workflow

This document starts the deployment-preparation track for the Tron migration.

## Objective

Deploy the existing Vouchify Solidity contracts to a Tron testnet with the fewest protocol-level changes possible, then verify which deployment assumptions still hold.

## Current position

- The contracts compile successfully with TronBox.
- The repo now uses TronBox migrations instead of Foundry scripts.
- Shasta is the preferred first validation network if funded wallets and funded test USDT already exist there.
- A Shasta migration now completes end-to-end deployment and validation.

## Latest validated Shasta deployment

- Voucher NFT: `TJkRenXTd1LB4ErmmewCmaR5zdwdggqdNF`
- Escrow factory: `TYRirtwpYGWWpWhkda5XoJRA8aryQ9v3D9`
- Membership factory: `TDKi2thiTHdZ9aR2PvNc6A5AcFXQ3mpXXw`
- Payment wallet factory: `THVSQ7KWSLVaQbJ3kwxwxerhQLFx3wxAER`

Recommended env workflow for Shasta integration testing:

- keep `TRON_USDT_TOKEN=TG3XXyExBkPp9nzdajDZsozEu4BkaSJozs`
- point backend and app test environments at the factory addresses above
- treat `getEscrowByVoucherId`, `getMembershipByMembershipId`, and `getWallet` as authoritative on Tron
- do not treat `getEscrowAddress`, `getMembershipAddress`, or `getWalletAddress` as authoritative on Tron

## Deployment track

### Phase 1. Select the Tron deployment path

Selected path:

1. Use TronBox as the compile and migration tool for TRON networks.
2. Keep Solidity contracts in `src/` and point TronBox at that directory with `contracts_directory`.
3. Use JavaScript migrations under `migrations/` for deployment and validation.

### Phase 2. Validate one end-to-end deployment on testnet

The first testnet run should deploy only enough contracts to validate the migration assumptions:

1. VouchifyVoucher
2. VouchifyEscrow implementation
3. VouchifyEscrowFactory

Success criteria:

- deployment succeeds
- admin and operator roles are assigned correctly
- factory can create an escrow clone
- predicted address and actual address match if deterministic deployment is claimed

Recommended first validation command:

```sh
tronbox migrate --network shasta --reset --compile-all
```

Fallback option if Shasta is unavailable in your environment:

```sh
tronbox migrate --network nile --reset --compile-all
```

Required environment values:

- `PRIVATE_KEY`
- `ADMIN_WALLET`
- `COLD_WALLET`
- `TRON_USDT_TOKEN`
- `VALIDATION_BUYER`: any nonzero recipient address used as the synthetic buyer in validation
- `VALIDATION_MERCHANT_ID`: the backend merchant id stored in the voucher and membership data
- `VALIDATION_PAYMENT_AMOUNT`
- `VALIDATION_MEMBERSHIP_CREDITS`

Validation scope of the script:

1. deploy escrow, membership, payment wallet implementations and factories
2. link voucher and factory roles
3. validate predicted versus actual escrow clone address
4. validate predicted versus actual membership clone address
5. validate predicted versus actual payment wallet clone address
6. validate redemption attribution after the `tx.origin` removal

Current confirmed behavior from the latest Shasta run:

- Tron accepted the updated deployer key and completed implementation and factory deployments.
- The full validation migration completed successfully for voucher, escrow, membership, and payment wallet flows.
- OpenZeppelin `predictDeterministicAddress` still does not match the actual clone address returned by the factories on Shasta.
- This is now an integration constraint, not a deployment blocker.

Important constraint:

- the script assumes Tron USDT is the only ERC-20 payment token in scope
- it does not validate native TRX payment flows, because TRX is only needed for deployment fees
- on Shasta, `TRON_USDT_TOKEN` must be the specific Shasta USDT contract address you already hold test funds in

### Phase 3. Expand to the full contract set

After the first deployment works, add:

1. payment wallet implementation and factory
2. membership implementation and factory
3. backend-facing deployment and verification wiring only for the contracts the backend actually uses

## Verification track

Verification still needs a concrete tool decision. At minimum, the selected flow must support:

1. source submission or flattening
2. constructor argument handling
3. deterministic reproducibility for later deployments

## Blocking questions

1. Confirm that the address derived from `PRIVATE_KEY` is the funded and activated Shasta account you intend to use.
2. Confirm the exact Shasta USDT contract address to use for the first validation run.
3. What explorer verification constraints apply to clone-based deployments on Tron?