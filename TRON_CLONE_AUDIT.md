# Tron Clone Audit

This document records the deterministic clone assumptions in the current codebase before any Tron deployment.

## Scope

Reviewed files:

- `src/core/VouchifyEscrowFactory.sol`
- `src/core/VouchifyMembershipFactory.sol`
- `src/payment/VouchifyPaymentWalletFactory.sol`
- `lib/openzeppelin-contracts/contracts/proxy/Clones.sol`

## Findings

### 1. Application code does not implement custom CREATE2 math

The Vouchify contracts do not compute deterministic clone addresses manually. All three factories delegate clone deployment and prediction to OpenZeppelin `Clones`.

That reduces project-specific risk because there is only one deterministic deployment implementation to validate.

### 2. The deterministic path depends on OpenZeppelin's EVM-oriented prediction logic

The exposed prediction functions are:

- `getEscrowAddress(bytes32 voucherId)`
- `getMembershipAddress(bytes32 membershipId)`
- `getWalletAddress(bytes32 paymentId)`

Those functions call `predictDeterministicAddress` from OpenZeppelin `Clones`.

The OpenZeppelin implementation embeds CREATE2 prediction logic directly in assembly and includes the standard `0xff` prefix used in Ethereum CREATE2 address derivation.

Implication:

- on ordinary EVM chains this is the right assumption
- on Tron this must be validated on testnet before predicted addresses are treated as authoritative

### 3. Deployment and prediction are coupled

Each factory uses the same OpenZeppelin library for both:

- actual deployment via `cloneDeterministic`
- address prediction via `predictDeterministicAddress`

That means the local EVM test suite can only prove internal consistency on normal EVM behavior. It cannot prove that TVM will preserve identical deterministic-address semantics.

## Required testnet validation

For each factory on Tron testnet:

1. deploy the implementation
2. deploy the factory
3. call the prediction function with a known salt
4. create the clone using the same salt-driving identifier
5. compare predicted address with the actual emitted or stored address
6. repeat for escrow, membership, and payment wallet flows

## Current conclusion

The codebase is in a better state than a custom CREATE2 implementation would be, because the deterministic clone logic is centralized in OpenZeppelin.

However, Tron deployability still depends on proving that TVM honors the same clone deployment and prediction assumptions for this library. Until that test is run, deterministic address predictions in the factories should be treated as unverified on Tron.