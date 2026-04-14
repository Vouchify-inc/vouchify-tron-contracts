# Vouchify Tron Contracts

This repository is the Tron-targeted migration of the Solidity contracts from `vouchify-contracts`.

The goal is not to rewrite the protocol. The goal is to preserve the existing business logic where possible, isolate Tron-specific changes, and prove deployment on Tron testnet before making any production assumptions.

## Plan

### Step 1. Bootstrap the Tron repo

- [x] Copy the current Solidity contracts baseline from `vouchify-contracts`
- [x] Preserve this repository's own Git history
- [x] Remove the empty-repo state and establish a working baseline
- [ ] Remove or replace Ethereum-only deployment assumptions

### Step 2. Add Tron-specific configuration

- [x] Add TronBox network configuration for Shasta, Nile, and mainnet
- [x] Add environment examples for Tron deployment
- [x] Switch the repo from Foundry entrypoints to TronBox

### Step 3. Audit the contracts for chain-specific risks

- [x] Identify `tx.origin` usage that should not survive the migration unchanged
- [x] Refactor redemption attribution to remove `tx.origin`
- [x] Identify deterministic clone deployment paths that need Tron validation
- [x] Document deterministic clone assumptions before Tron deployment
- [ ] Review token standard assumptions around ERC-20/ERC-721 vs Tron usage
- [ ] Confirm whether any contract depends on Ethereum-only runtime behavior

### Step 4. Validate the codebase locally

- [x] Compile the copied contracts with TronBox
- [x] Reach Shasta with a real TronBox migration attempt
- [x] Separate toolchain misconfiguration from network/account issues

### Step 5. Prepare deployment and verification flow

- [x] Create initial Tron deployment notes
- [x] Create TronBox migration scripts
- [ ] Define verification steps for Tron explorer tooling
- [x] Complete the first successful Shasta deployment

## Current Status

Work started on steps 1 through 3.

What has already been done:

- The source contracts repository has been copied into this folder.
- TronBox configuration and migrations have been added to the repo.
- A Tron `.env.example` template has been added.
- Initial migration risks have been documented in `MIGRATION_NOTES.md`.
- Redemption attribution now records the trusted factory caller instead of using `tx.origin`.
- Deterministic clone assumptions are documented in `TRON_CLONE_AUDIT.md`.
- TronBox compile succeeds against the copied contract set.
- A real Shasta migration now deploys and validates the full payment, escrow, and membership stack on Shasta.
- The current Shasta deployment addresses are:
	- Voucher NFT: `TJkRenXTd1LB4ErmmewCmaR5zdwdggqdNF`
	- Escrow factory: `TYRirtwpYGWWpWhkda5XoJRA8aryQ9v3D9`
	- Membership factory: `TDKi2thiTHdZ9aR2PvNc6A5AcFXQ3mpXXw`
	- Payment wallet factory: `THVSQ7KWSLVaQbJ3kwxwxerhQLFx3wxAER`

## Immediate Risks

1. The factories rely on deterministic clones, so predicted-versus-actual address behavior must still be validated on Tron testnet before those predictions are treated as authoritative.
2. Live Shasta deployment now shows that predicted clone addresses do not match actual clone addresses, so deterministic factory address predictions cannot yet be treated as authoritative on Tron.

## Working Rules For This Repo

1. Keep protocol logic as close as possible to `vouchify-contracts` until a Tron-specific incompatibility is proven.
2. Use TronBox as the deployment and migration entrypoint for TRON networks.
3. Do not assume that OpenZeppelin deterministic clone prediction behaves identically on Tron testnet just because deployment succeeds.

## Next Actions

1. Update backend and app integrations so Tron uses stored actual clone addresses, not predicted ones.
2. Mirror these Shasta addresses into deployment env workflows for integration testing.
3. Review Tron token standard and explorer verification constraints.
