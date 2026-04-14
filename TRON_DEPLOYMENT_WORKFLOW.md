# Tron Deployment Workflow

This document starts the deployment-preparation track for the Tron migration.

## Objective

Deploy the existing Vouchify Solidity contracts to a Tron testnet with the fewest protocol-level changes possible, then verify which deployment assumptions still hold.

## Current position

- The contracts compile successfully in this repository.
- The copied Foundry test suite passes locally.
- The deployment toolchain for Tron is still undecided.
- A dedicated validation script now exists at `script/ValidateTronTestnet.s.sol`.
- Shasta is the preferred first validation network if funded wallets and funded test USDT already exist there.

## Deployment track

### Phase 1. Select the Tron deployment path

Candidate options to evaluate:

1. Keep Foundry for compilation and use a Tron-specific deploy script or SDK for broadcasting.
2. Add a Tron-native deployment layer and keep Foundry only for local compile and test work.
3. Use a hybrid flow where Foundry produces artifacts and Tron tooling handles deployment and verification.

Decision criteria:

- reliable testnet deployment
- support for constructor arguments and linked deployments
- ability to verify contracts in the target explorer
- operational simplicity for repeat deployments

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
forge script script/ValidateTronTestnet.s.sol:ValidateTronTestnet --rpc-url tron_shasta --broadcast
```

Fallback option if Shasta is unavailable in your environment:

```sh
forge script script/ValidateTronTestnet.s.sol:ValidateTronTestnet --rpc-url tron_nile --broadcast
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

1. Confirm the exact Shasta RPC/provider and funded Shasta USDT contract address to use for the first validation run.
2. Which deployment path has the least operational friction for this codebase?
3. What explorer verification constraints apply to clone-based deployments on Tron?