# Tron Migration Notes

This file tracks the first contract-level risks identified while moving the Solidity codebase into the Tron repository.

## Confirmed review targets

### 1. `tx.origin` usage

The following files currently use `tx.origin` for redemption attribution:

- `src/core/VouchifyEscrow.sol`
- `src/core/VouchifyMembership.sol`
- `src/core/VouchifyMembershipFactory.sol`

This should be treated as a migration blocker, not as a Tron feature. The likely fix is to pass the actor explicitly from the trusted caller path instead of reading transaction origin inside the contract.

### 2. Deterministic clone deployment

The following factories rely on deterministic clones and predicted addresses:

- `src/core/VouchifyEscrowFactory.sol`
- `src/core/VouchifyMembershipFactory.sol`
- `src/payment/VouchifyPaymentWalletFactory.sol`

Before production use on Tron:

- deploy each factory on Tron testnet
- create at least one clone per factory
- compare predicted addresses against actual deployed addresses
- verify explorer behavior for clone contracts

### 3. Token behavior to validate

The payment wallet currently assumes standard ERC-20 style token behavior through OpenZeppelin interfaces and `SafeERC20`.

That is promising for Tron-compatible tokens, but actual token contracts used on Tron still need to be tested for:

- transfer return behavior
- decimals assumptions
- explorer visibility and indexing

## First implementation priorities

1. Build and run the existing Foundry tests inside this repo.
2. Add Tron environment examples and deployment placeholders.
3. Refactor redemption attribution away from `tx.origin`.
4. Validate deterministic clone behavior on Tron testnet.