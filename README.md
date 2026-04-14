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

- [x] Add Tron RPC placeholders to Foundry config for research and local validation
- [x] Add environment examples for Tron deployment
- [ ] Decide on the final deployment toolchain for Tron testnet and mainnet

### Step 3. Audit the contracts for chain-specific risks

- [x] Identify `tx.origin` usage that should not survive the migration unchanged
- [x] Refactor redemption attribution to remove `tx.origin`
- [x] Identify deterministic clone deployment paths that need Tron validation
- [x] Document deterministic clone assumptions before Tron deployment
- [ ] Review token standard assumptions around ERC-20/ERC-721 vs Tron usage
- [ ] Confirm whether any contract depends on Ethereum-only runtime behavior

### Step 4. Validate the codebase locally

- [x] Build the copied contracts in this repository
- [x] Run the existing Foundry test suite here
- [ ] Separate generic EVM failures from Tron-specific failures

### Step 5. Prepare deployment and verification flow

- [x] Create initial Tron deployment notes
- [ ] Create Tron deployment scripts
- [ ] Define verification steps for Tron explorer tooling
- [ ] Deploy first to Tron Nile/Shasta-equivalent supported testnet

## Current Status

Work started on steps 1 through 3.

What has already been done:

- The source contracts repository has been copied into this folder.
- Tron RPC placeholders have been added to the config.
- A Tron `.env.example` template has been added.
- Initial migration risks have been documented in `MIGRATION_NOTES.md`.
- Redemption attribution now records the trusted factory caller instead of using `tx.origin`.
- Deterministic clone assumptions are documented in `TRON_CLONE_AUDIT.md`.
- The copied baseline compiles successfully with Foundry.
- The copied Foundry test suite passes in this repository.

## Immediate Risks

1. The escrow and membership flows currently record `tx.origin`. That is a weak pattern on any EVM-compatible chain and should be removed or redesigned before Tron deployment.
2. The factories rely on deterministic clones. Address prediction behavior must be validated on Tron testnet before using predicted addresses operationally.
3. Deployment and verification on Tron should be treated as a separate track from the current Ethereum-style Foundry deployment flow.

## Working Rules For This Repo

1. Keep protocol logic as close as possible to `vouchify-contracts` until a Tron-specific incompatibility is proven.
2. Prefer additive Tron-specific scripts and docs over invasive rewrites.
3. Do not assume that a successful local Foundry build implies Tron deployability.

## Next Actions

1. Choose the concrete Tron deployment toolchain and wire scripts around it.
2. Validate deterministic clone behavior on Tron testnet.
3. Review Tron token standard and explorer verification constraints.
