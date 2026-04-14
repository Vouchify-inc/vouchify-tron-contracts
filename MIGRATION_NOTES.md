# Tron Migration Notes

This file tracks the first contract-level risks identified while moving the Solidity codebase into the Tron repository.

## Confirmed review targets

### 1. `tx.origin` usage

The following files previously used `tx.origin` for redemption attribution:

- `src/core/VouchifyEscrow.sol`
- `src/core/VouchifyMembership.sol`
- `src/core/VouchifyMembershipFactory.sol`

This was treated as a migration blocker, not as a Tron feature. The fix in this repo is to pass the trusted factory caller explicitly into the clone redemption functions instead of reading transaction origin inside the contract.

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

Additional audit finding:

- the current clone deployment flow depends entirely on OpenZeppelin `Clones.cloneDeterministic` and `predictDeterministicAddress`
- the project does not implement its own CREATE2 math anywhere in application code
- that is good for maintainability, but it means Tron compatibility rises or falls with how TVM handles the same deterministic deployment assumptions at runtime
- do not trust `getEscrowAddress`, `getMembershipAddress`, or `getWalletAddress` on Tron until testnet validation proves predicted and actual addresses match

### 3. Token behavior to validate

The payment wallet currently assumes standard ERC-20 style token behavior through OpenZeppelin interfaces and `SafeERC20`.

That is promising for Tron-compatible tokens, but actual token contracts used on Tron still need to be tested for:

- transfer return behavior
- decimals assumptions
- explorer visibility and indexing

## First implementation priorities

1. Compile and migrate through TronBox rather than Foundry.
2. Add Tron environment examples and deployment placeholders.
3. Validate deterministic clone behavior on Tron testnet.
4. Review token-standard and verification constraints for Tron deployment.