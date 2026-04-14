# Tron Deployment Workflow

This document starts the deployment-preparation track for the Tron migration.

## Objective

Deploy the existing Vouchify Solidity contracts to a Tron testnet with the fewest protocol-level changes possible, then verify which deployment assumptions still hold.

## Current position

- The contracts compile successfully in this repository.
- The copied Foundry test suite passes locally.
- The deployment toolchain for Tron is still undecided.

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

### Phase 3. Expand to the full contract set

After the first deployment works, add:

1. payment wallet implementation and factory
2. membership implementation and factory
3. registry and any operational wiring

## Verification track

Verification still needs a concrete tool decision. At minimum, the selected flow must support:

1. source submission or flattening
2. constructor argument handling
3. deterministic reproducibility for later deployments

## Blocking questions

1. Which Tron testnet should be used for the first deployment in April 2026?
2. Which deployment path has the least operational friction for this codebase?
3. What explorer verification constraints apply to clone-based deployments on Tron?