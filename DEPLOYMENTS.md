# Vouchify Contract Deployments

## Mainnet Deployments

**Deployed:** July 8, 2025  
**Deployer / Operator:** `0xC0c1e025e7CedF2a1BDAd918f68DeaD56882a3c4`  
**Admin:** `0xFd29b36c51beD3a1152E22064B5c7146CCeeD30D`  
**Cold Wallet:** `0x4A0c0320D09EA02344dB8629b176c263851AD2D5`

### Roles Configuration
| Role | Wallet | Purpose |
|------|--------|---------|
| DEFAULT_ADMIN_ROLE | Admin wallet | Manage roles, settings, upgrades |
| OPERATOR_ROLE | Deployer wallet | Create escrows, payment wallets, memberships |
| PAUSER_ROLE | Deployer wallet | Pause/unpause contracts |
| FACTORY_ROLE | EscrowFactory + MembershipFactory | Mint voucher NFTs |

---

### Base (Chain ID: 8453)

| Contract | Address |
|----------|---------|
| **VouchifyEscrow** (impl) | [`0xb0a1a63023616c6f4105866698b5d4122951c14b`](https://basescan.org/address/0xb0a1a63023616c6f4105866698b5d4122951c14b) |
| **VouchifyVoucher** (NFT) | [`0x5a5132941665208b2a8e25060c9e74fddcbb80e9`](https://basescan.org/address/0x5a5132941665208b2a8e25060c9e74fddcbb80e9) |
| **VouchifyEscrowFactory** | [`0x868d72a7a577e0bb00017eb7692ff2b2f7e13f0a`](https://basescan.org/address/0x868d72a7a577e0bb00017eb7692ff2b2f7e13f0a) |
| **VouchifyPaymentWallet** (impl) | [`0xb922b2719d5f37f831710643b81276156fbd55fb`](https://basescan.org/address/0xb922b2719d5f37f831710643b81276156fbd55fb) |
| **VouchifyPaymentWalletFactory** | [`0x65ab244d811efadc4b01587dbf5d7177596dc403`](https://basescan.org/address/0x65ab244d811efadc4b01587dbf5d7177596dc403) |
| **VouchifyMembership** (impl) | [`0xe44dd77c605d548a29e27bc2b8c43eb9c23ddb12`](https://basescan.org/address/0xe44dd77c605d548a29e27bc2b8c43eb9c23ddb12) |
| **VouchifyMembershipFactory** | [`0xbbf0fa835085f740ae60063969b247f216081649`](https://basescan.org/address/0xbbf0fa835085f740ae60063969b247f216081649) |

All 7 contracts verified on BaseScan ✅

---

### Arbitrum One (Chain ID: 42161)

**Deployed:** April 13, 2026  
**Explorer:** Arbiscan  
**Broadcast File:** `broadcast/Deploy.s.sol/42161/run-latest.json`

| Contract | Address |
|----------|---------|
| **VouchifyEscrow** (impl) | [`0x01028f6878d9bbff45b193310adf4d3e36ecd147`](https://arbiscan.io/address/0x01028f6878d9bbff45b193310adf4d3e36ecd147) |
| **VouchifyVoucher** (NFT) | [`0xd1ab661caf8d79cfebbab463914624678e929bfb`](https://arbiscan.io/address/0xd1ab661caf8d79cfebbab463914624678e929bfb) |
| **VouchifyEscrowFactory** | [`0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f`](https://arbiscan.io/address/0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f) |
| **VouchifyPaymentWallet** (impl) | [`0xb845c622eb403c27e9ef5d1ceca1662ae276239f`](https://arbiscan.io/address/0xb845c622eb403c27e9ef5d1ceca1662ae276239f) |
| **VouchifyPaymentWalletFactory** | [`0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f`](https://arbiscan.io/address/0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f) |
| **VouchifyMembership** (impl) | [`0xee370f5acc9f00c94203e90aa115f27f6e5d342a`](https://arbiscan.io/address/0xee370f5acc9f00c94203e90aa115f27f6e5d342a) |
| **VouchifyMembershipFactory** | [`0xf6eb797e15e16e169651cf126eb6b6d692206ee3`](https://arbiscan.io/address/0xf6eb797e15e16e169651cf126eb6b6d692206ee3) |

### Transaction Hashes

| Contract | Transaction Hash |
|----------|------------------|
| VouchifyEscrow | [`0x3596f151b6ce9b2335a9eff8f9b5387f3cca0262860dfa3b892308843774c58f`](https://arbiscan.io/tx/0x3596f151b6ce9b2335a9eff8f9b5387f3cca0262860dfa3b892308843774c58f) |
| VouchifyVoucher | [`0x35765cdf688de69d281336e7441badf5acb487cc5b97a0990ba4383a47dfce85`](https://arbiscan.io/tx/0x35765cdf688de69d281336e7441badf5acb487cc5b97a0990ba4383a47dfce85) |
| VouchifyEscrowFactory | [`0x60e7969ced786236e49a29540678ad06c906c9cdd856899d3905580a6dd49d2d`](https://arbiscan.io/tx/0x60e7969ced786236e49a29540678ad06c906c9cdd856899d3905580a6dd49d2d) |
| VouchifyPaymentWallet | [`0xcb48488b9914cb747a391f8430b3b203f9e13c9ed5012f880183e236ccd4b4b7`](https://arbiscan.io/tx/0xcb48488b9914cb747a391f8430b3b203f9e13c9ed5012f880183e236ccd4b4b7) |
| VouchifyPaymentWalletFactory | [`0xf531f9c1a4bcdb3e577d8117a075c303efe15412c53335574bd71c79fbbf65fc`](https://arbiscan.io/tx/0xf531f9c1a4bcdb3e577d8117a075c303efe15412c53335574bd71c79fbbf65fc) |
| VouchifyMembership | [`0x0be0ad959948adf4ade27d3f1765622e85a5de6c7bf482391dd2be92cdb78f40`](https://arbiscan.io/tx/0x0be0ad959948adf4ade27d3f1765622e85a5de6c7bf482391dd2be92cdb78f40) |
| VouchifyMembershipFactory | [`0x2ef9ad5d2b0864db2feff3fb950e95f4ddef5cb884c31b337dc7c1df4c58636a`](https://arbiscan.io/tx/0x2ef9ad5d2b0864db2feff3fb950e95f4ddef5cb884c31b337dc7c1df4c58636a) |
| Link: setVoucherContract | [`0xc52ef89f6ae7626254919ddf3fe2eb7a5577ee3ff903bde74f044ad161e066a3`](https://arbiscan.io/tx/0xc52ef89f6ae7626254919ddf3fe2eb7a5577ee3ff903bde74f044ad161e066a3) |
| Link: setFactory | [`0xdc3292c33dfd0619931b539bb44c3ecbb06f53f1c61d962f8bcd4ef3b67c4034`](https://arbiscan.io/tx/0xdc3292c33dfd0619931b539bb44c3ecbb06f53f1c61d962f8bcd4ef3b67c4034) |
| Link: membership setVoucherContract | [`0x66b236c635bb28cd1c1b6d90392ea913444078649b7703699152b62ed013359e`](https://arbiscan.io/tx/0x66b236c635bb28cd1c1b6d90392ea913444078649b7703699152b62ed013359e) |
| Link: grant FACTORY_ROLE | [`0x41910feaa95922e2c01f75b172a343ba6b39f0d6805766770f067ac1a058c207`](https://arbiscan.io/tx/0x41910feaa95922e2c01f75b172a343ba6b39f0d6805766770f067ac1a058c207) |

### Verification

All 7 contracts verified on Arbiscan ✅

---

### Plasma Mainnet (Chain ID: 9745)

**Deployed:** April 13, 2026  
**Explorer:** Routescan / PlasmaScan  
**RPC Used:** Alchemy Plasma Mainnet  
**Deployment Method:** Manual replay with `cast send` because the installed Foundry build rejected `forge script` broadcasts on chain `9745`.

| Contract | Address |
|----------|---------|
| **VouchifyEscrow** (impl) | [`0x01028f6878d9bbff45b193310adf4d3e36ecd147`](https://plasmascan.to/address/0x01028f6878d9bbff45b193310adf4d3e36ecd147) |
| **VouchifyVoucher** (NFT) | [`0xd1ab661caf8d79cfebbab463914624678e929bfb`](https://plasmascan.to/address/0xd1ab661caf8d79cfebbab463914624678e929bfb) |
| **VouchifyEscrowFactory** | [`0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f`](https://plasmascan.to/address/0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f) |
| **VouchifyPaymentWallet** (impl) | [`0xb845c622eb403c27e9ef5d1ceca1662ae276239f`](https://plasmascan.to/address/0xb845c622eb403c27e9ef5d1ceca1662ae276239f) |
| **VouchifyPaymentWalletFactory** | [`0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f`](https://plasmascan.to/address/0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f) |
| **VouchifyMembership** (impl) | [`0xee370f5acc9f00c94203e90aa115f27f6e5d342a`](https://plasmascan.to/address/0xee370f5acc9f00c94203e90aa115f27f6e5d342a) |
| **VouchifyMembershipFactory** | [`0xf6eb797e15e16e169651cf126eb6b6d692206ee3`](https://plasmascan.to/address/0xf6eb797e15e16e169651cf126eb6b6d692206ee3) |

### Notes

- All top-level contract addresses match Arbitrum, BSC, Polygon, and Celo because the same deployer replayed the same nonce sequence.
- Future unsupported-chain replays can use `node script/replay-broadcast.mjs --broadcast broadcast/Deploy.s.sol/9745/run-latest.json --rpc-url $PLASMA_RPC_URL --private-key $PRIVATE_KEY`.
- Post-deploy linkage was verified on-chain:
	- `VouchifyVoucher.factory()` returns `0xa215df5bc5010D4eBf98e8644AFb5fdC0cF34C0F`
	- `VouchifyEscrowFactory.voucherContract()` returns `0xD1Ab661CaF8d79CFebbAB463914624678E929BFB`
	- `VouchifyMembershipFactory.voucherContract()` returns `0xD1Ab661CaF8d79CFebbAB463914624678E929BFB`
- Contract verification was not run through `forge verify` because chain `9745` is not supported by the installed Foundry build.

---

### BSC (Chain ID: 56)

| Contract | Address |
|----------|---------|
| **VouchifyEscrow** (impl) | [`0x01028f6878d9bbff45b193310adf4d3e36ecd147`](https://bscscan.com/address/0x01028f6878d9bbff45b193310adf4d3e36ecd147) |
| **VouchifyVoucher** (NFT) | [`0xd1ab661caf8d79cfebbab463914624678e929bfb`](https://bscscan.com/address/0xd1ab661caf8d79cfebbab463914624678e929bfb) |
| **VouchifyEscrowFactory** | [`0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f`](https://bscscan.com/address/0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f) |
| **VouchifyPaymentWallet** (impl) | [`0xb845c622eb403c27e9ef5d1ceca1662ae276239f`](https://bscscan.com/address/0xb845c622eb403c27e9ef5d1ceca1662ae276239f) |
| **VouchifyPaymentWalletFactory** | [`0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f`](https://bscscan.com/address/0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f) |
| **VouchifyMembership** (impl) | [`0xee370f5acc9f00c94203e90aa115f27f6e5d342a`](https://bscscan.com/address/0xee370f5acc9f00c94203e90aa115f27f6e5d342a) |
| **VouchifyMembershipFactory** | [`0xf6eb797e15e16e169651cf126eb6b6d692206ee3`](https://bscscan.com/address/0xf6eb797e15e16e169651cf126eb6b6d692206ee3) |

All 7 contracts verified on BscScan ✅

---

### Polygon (Chain ID: 137)

| Contract | Address |
|----------|---------|
| **VouchifyEscrow** (impl) | [`0x01028f6878d9bbff45b193310adf4d3e36ecd147`](https://polygonscan.com/address/0x01028f6878d9bbff45b193310adf4d3e36ecd147) |
| **VouchifyVoucher** (NFT) | [`0xd1ab661caf8d79cfebbab463914624678e929bfb`](https://polygonscan.com/address/0xd1ab661caf8d79cfebbab463914624678e929bfb) |
| **VouchifyEscrowFactory** | [`0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f`](https://polygonscan.com/address/0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f) |
| **VouchifyPaymentWallet** (impl) | [`0xb845c622eb403c27e9ef5d1ceca1662ae276239f`](https://polygonscan.com/address/0xb845c622eb403c27e9ef5d1ceca1662ae276239f) |
| **VouchifyPaymentWalletFactory** | [`0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f`](https://polygonscan.com/address/0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f) |
| **VouchifyMembership** (impl) | [`0xee370f5acc9f00c94203e90aa115f27f6e5d342a`](https://polygonscan.com/address/0xee370f5acc9f00c94203e90aa115f27f6e5d342a) |
| **VouchifyMembershipFactory** | [`0xf6eb797e15e16e169651cf126eb6b6d692206ee3`](https://polygonscan.com/address/0xf6eb797e15e16e169651cf126eb6b6d692206ee3) |

All 7 contracts verified on PolygonScan ✅

---

### Celo (Chain ID: 42220)

| Contract | Address |
|----------|---------|
| **VouchifyEscrow** (impl) | [`0x01028f6878d9bbff45b193310adf4d3e36ecd147`](https://celoscan.io/address/0x01028f6878d9bbff45b193310adf4d3e36ecd147) |
| **VouchifyVoucher** (NFT) | [`0xd1ab661caf8d79cfebbab463914624678e929bfb`](https://celoscan.io/address/0xd1ab661caf8d79cfebbab463914624678e929bfb) |
| **VouchifyEscrowFactory** | [`0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f`](https://celoscan.io/address/0xa215df5bc5010d4ebf98e8644afb5fdc0cf34c0f) |
| **VouchifyPaymentWallet** (impl) | [`0xb845c622eb403c27e9ef5d1ceca1662ae276239f`](https://celoscan.io/address/0xb845c622eb403c27e9ef5d1ceca1662ae276239f) |
| **VouchifyPaymentWalletFactory** | [`0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f`](https://celoscan.io/address/0x6f0ab97d19bf7f3ae6660c60ffd81d5c4bdabb7f) |
| **VouchifyMembership** (impl) | [`0xee370f5acc9f00c94203e90aa115f27f6e5d342a`](https://celoscan.io/address/0xee370f5acc9f00c94203e90aa115f27f6e5d342a) |
| **VouchifyMembershipFactory** | [`0xf6eb797e15e16e169651cf126eb6b6d692206ee3`](https://celoscan.io/address/0xf6eb797e15e16e169651cf126eb6b6d692206ee3) |

All 7 contracts verified on CeloScan ✅

> **Note:** Arbitrum, Plasma, BSC, Polygon, and Celo share identical contract addresses due to deterministic CREATE deployment with the same deployer and nonce sequence.

---

## Testnet Deployments

### Base Sepolia (Testnet) — Redeployment

**Network:** Base Sepolia  
**Chain ID:** 84532  
**Deployed:** February 19, 2026  
**Deployer:** `0xEC891A037F932493624184970a283ab87398e0A6`  
**Cold Wallet:** `0xEC891A037F932493624184970a283ab87398e0A6` (deployer default)  
**Total Gas Cost:** 0.000019113609 ETH (6,371,203 gas × 0.003 gwei)

### Contract Addresses

| Contract | Address | Description |
|----------|---------|-------------|
| **VouchifyEscrow** | [`0x06BA5697518bEdD3dC772154abBf9f5E6A60C24D`](https://sepolia.basescan.org/address/0x06BA5697518bEdD3dC772154abBf9f5E6A60C24D) | Implementation template for escrow clones |
| **VouchifyVoucher** | [`0x57A2248EAf7f40BA3fBC0E8c51447d274c8b0610`](https://sepolia.basescan.org/address/0x57A2248EAf7f40BA3fBC0E8c51447d274c8b0610) | ERC-721 NFT representing vouchers |
| **VouchifyEscrowFactory** | [`0x1556D9Bfa81685Be75E3C6C55000A08BeC284774`](https://sepolia.basescan.org/address/0x1556D9Bfa81685Be75E3C6C55000A08BeC284774) | Factory for deploying escrow clones (EIP-1167) |
| **VouchifyPaymentWallet** | [`0x273E403fcfAeB7a455AAa1d956C34BdBc850230B`](https://sepolia.basescan.org/address/0x273E403fcfAeB7a455AAa1d956C34BdBc850230B) | Implementation template for payment wallet clones |
| **VouchifyPaymentWalletFactory** | [`0xa045bcf89E0Fb6BF1E4fDFca3E5A3c94E2b11216`](https://sepolia.basescan.org/address/0xa045bcf89E0Fb6BF1E4fDFca3E5A3c94E2b11216) | Factory for deploying payment wallet clones |
| **VouchifyMembership** | [`0xF08d4d4aC257920f6Ffcf60859Fa4CDB799ad19A`](https://sepolia.basescan.org/address/0xF08d4d4aC257920f6Ffcf60859Fa4CDB799ad19A) | Implementation template for membership clones |
| **VouchifyMembershipFactory** | [`0x06758921654Bf8e29297f34F931Eb3CE06dAE7d2`](https://sepolia.basescan.org/address/0x06758921654Bf8e29297f34F931Eb3CE06dAE7d2) | Factory for deploying membership clones |

### Transaction Hashes

| Contract | Transaction Hash |
|----------|------------------|
| VouchifyEscrow | [`0xf426ef19bd395e9126198faa4c484cd59abcf616430036d21d61580bd161dd82`](https://sepolia.basescan.org/tx/0xf426ef19bd395e9126198faa4c484cd59abcf616430036d21d61580bd161dd82) |
| VouchifyVoucher | [`0x913bf1280ffff4e833a4fc5d79d2eeb093cd527e121919f5c19f9760e06e40e0`](https://sepolia.basescan.org/tx/0x913bf1280ffff4e833a4fc5d79d2eeb093cd527e121919f5c19f9760e06e40e0) |
| VouchifyEscrowFactory | [`0x9b99976a285c9e8e0b13c4715d6e6e35331b9f2d89306b1e25d44cf2a93f337e`](https://sepolia.basescan.org/tx/0x9b99976a285c9e8e0b13c4715d6e6e35331b9f2d89306b1e25d44cf2a93f337e) |
| VouchifyPaymentWallet | [`0x1878f1f0ae1196853c3b3eada07c9a3b3ba67eeadab188b04a7cd6d728ad12dd`](https://sepolia.basescan.org/tx/0x1878f1f0ae1196853c3b3eada07c9a3b3ba67eeadab188b04a7cd6d728ad12dd) |
| VouchifyPaymentWalletFactory | [`0x579b0e13e3443e52b45affe442c996c5ebe76aebe88df5f5fcbc3919e54ce152`](https://sepolia.basescan.org/tx/0x579b0e13e3443e52b45affe442c996c5ebe76aebe88df5f5fcbc3919e54ce152) |
| VouchifyMembership | [`0x91a567848daec8395f1af2c4a7f4cd694572dc9f0dd32dfde722f1d4f734fe9b`](https://sepolia.basescan.org/tx/0x91a567848daec8395f1af2c4a7f4cd694572dc9f0dd32dfde722f1d4f734fe9b) |
| VouchifyMembershipFactory | [`0xcfbcab615c02a7fb0ad69d15122494345aea501917b218c3806350750decd4f3`](https://sepolia.basescan.org/tx/0xcfbcab615c02a7fb0ad69d15122494345aea501917b218c3806350750decd4f3) |
| Link: setVoucherContract | [`0x8cc1418f3ef0e39d33337e23ea43fcff650d5e6d4f042263e7d556c65c4f0196`](https://sepolia.basescan.org/tx/0x8cc1418f3ef0e39d33337e23ea43fcff650d5e6d4f042263e7d556c65c4f0196) |
| Link: setFactory | [`0x1ac0e2dfb99ad8f266b7c1bd38069375ad4aaef0e4e670fc5a0e93f41cef8abb`](https://sepolia.basescan.org/tx/0x1ac0e2dfb99ad8f266b7c1bd38069375ad4aaef0e4e670fc5a0e93f41cef8abb) |

### Verification

All 5 contracts verified on BaseScan ✅

Membership contracts (VouchifyMembership + Factory) verified ✅

---

## Previous Base Sepolia Deployment (January 12, 2026)

<details>
<summary>Superseded — click to expand</summary>

**Total Gas Cost:** 0.0000074576112 ETH

| Contract | Address |
|----------|---------|
| VouchifyEscrow | `0x0A27cF58dDD7F2721Cfa0E29B5A085157861B849` |
| VouchifyEscrowFactory | `0x21C76a1702C57BfC17dc6002fa41211a30769B24` |
| VouchifyVoucher | `0xf4ADD2aA69E0Be38AB66b7a582434A83177997CB` |
| VouchifyPaymentWallet | `0xddc108a72cC83e1b95D89E9D3010b42A0216B503` |
| VouchifyPaymentWalletFactory | `0x80b180Df0b921b32E38A702F2E9fF1Aff7cCc863` |

</details>

---

## BSC Testnet

**Network:** BNB Smart Chain Testnet  
**Chain ID:** 97  
**Deployed:** February 19, 2026  
**Deployer:** `0xEC891A037F932493624184970a283ab87398e0A6`  
**Cold Wallet:** `0xEC891A037F932493624184970a283ab87398e0A6` (deployer default)  
**Total Gas Cost:** 0.0006371215 BNB (6,371,215 gas × 0.1 gwei)

### Contract Addresses

| Contract | Address | Description |
|----------|---------|-------------|
| **VouchifyEscrow** | [`0x1A7E36a76dC36B32C6061B2fA897B854782E22e3`](https://testnet.bscscan.com/address/0x1A7E36a76dC36B32C6061B2fA897B854782E22e3) | Implementation template for escrow clones |
| **VouchifyVoucher** | [`0xf00193015128cCbd2b7C9482064221435b6Bb39D`](https://testnet.bscscan.com/address/0xf00193015128cCbd2b7C9482064221435b6Bb39D) | ERC-721 NFT representing vouchers |
| **VouchifyEscrowFactory** | [`0xaaBa585929Ee2F8A015d4f7378604d56d93Cb85D`](https://testnet.bscscan.com/address/0xaaBa585929Ee2F8A015d4f7378604d56d93Cb85D) | Factory for deploying escrow clones (EIP-1167) |
| **VouchifyPaymentWallet** | [`0xeEEb6f0884DE5a880dcA7ca22B10528413Aa66D2`](https://testnet.bscscan.com/address/0xeEEb6f0884DE5a880dcA7ca22B10528413Aa66D2) | Implementation template for payment wallet clones |
| **VouchifyPaymentWalletFactory** | [`0x224b6EfF956730EF0ca6C6299Cee9ac0855d3249`](https://testnet.bscscan.com/address/0x224b6EfF956730EF0ca6C6299Cee9ac0855d3249) | Factory for deploying payment wallet clones |
| **VouchifyMembership** | [`0x229e4A71F8A86fd87683C941F232875FFD371dEE`](https://testnet.bscscan.com/address/0x229e4A71F8A86fd87683C941F232875FFD371dEE) | Implementation template for membership clones |
| **VouchifyMembershipFactory** | [`0xc0B1eaa0A03248b2d122AA898F75c6aC33250ec5`](https://testnet.bscscan.com/address/0xc0B1eaa0A03248b2d122AA898F75c6aC33250ec5) | Factory for deploying membership clones |

### Transaction Hashes

| Contract | Transaction Hash |
|----------|------------------|
| VouchifyEscrow | [`0x1266a84cf59d0d36ec5b53dca078f361a5687ad1e8da3ee1b3fc5e8a7fe39427`](https://testnet.bscscan.com/tx/0x1266a84cf59d0d36ec5b53dca078f361a5687ad1e8da3ee1b3fc5e8a7fe39427) |
| VouchifyVoucher | [`0xb9bb05541f113237c80c289e58d942e4a25fae452d20d24d8054bd6f691aed8d`](https://testnet.bscscan.com/tx/0xb9bb05541f113237c80c289e58d942e4a25fae452d20d24d8054bd6f691aed8d) |
| VouchifyEscrowFactory | [`0x182edc2d48d8e1c1f5c5550918f4478978f724857d1d83eeeadee28250768f5a`](https://testnet.bscscan.com/tx/0x182edc2d48d8e1c1f5c5550918f4478978f724857d1d83eeeadee28250768f5a) |
| VouchifyPaymentWallet | [`0xf6b3c8d3932fadf43dfb09bfc0db9a49a3777ef27215b076d9f1088c9ed2287a`](https://testnet.bscscan.com/tx/0xf6b3c8d3932fadf43dfb09bfc0db9a49a3777ef27215b076d9f1088c9ed2287a) |
| VouchifyPaymentWalletFactory | [`0xb8d8e6acf8bdb46a24ba9088d66b96565ecb3a47ab334803b9a2db10e888ecc5`](https://testnet.bscscan.com/tx/0xb8d8e6acf8bdb46a24ba9088d66b96565ecb3a47ab334803b9a2db10e888ecc5) |
| VouchifyMembership | [`0xa317d292757623d18afe08eab42871ade14b82343a20ae98abac5b60cb6df41f`](https://testnet.bscscan.com/tx/0xa317d292757623d18afe08eab42871ade14b82343a20ae98abac5b60cb6df41f) |
| VouchifyMembershipFactory | [`0x14c30aca9f6bc293ffd77f05736413e8ea4d7a24abba26c2d81ec5871d8f67b4`](https://testnet.bscscan.com/tx/0x14c30aca9f6bc293ffd77f05736413e8ea4d7a24abba26c2d81ec5871d8f67b4) |
| Link: setVoucherContract | [`0xd54b3d9ac6ed782b3e7bb3bcdd3f25ec67f119148817bde111e4e48aafeb603b`](https://testnet.bscscan.com/tx/0xd54b3d9ac6ed782b3e7bb3bcdd3f25ec67f119148817bde111e4e48aafeb603b) |
| Link: setFactory | [`0x3ed771fcd4bcefa9b916569c4b567def8c9765a28f03dc52d2d8a660a302a4b8`](https://testnet.bscscan.com/tx/0x3ed771fcd4bcefa9b916569c4b567def8c9765a28f03dc52d2d8a660a302a4b8) |

### Verification

All 5 contracts verified on BscScan ✅

Membership contracts (VouchifyMembership + Factory) verified ✅

---

## Polygon Amoy (Testnet)

**Network:** Polygon Amoy  
**Chain ID:** 80002  
**Deployed:** February 19, 2026  
**Deployer:** `0xEC891A037F932493624184970a283ab87398e0A6`  
**Cold Wallet:** `0xEC891A037F932493624184970a283ab87398e0A6` (deployer default)  
**Total Gas Cost:** 0.225128037081680995 POL (6,371,215 gas × avg 35.335181293 gwei)

### Contract Addresses

| Contract | Address | Description |
|----------|---------|-------------|
| **VouchifyEscrow** | [`0x5Db793A2187DF397C687bdCEf58eE221cfb95EB4`](https://amoy.polygonscan.com/address/0x5Db793A2187DF397C687bdCEf58eE221cfb95EB4) | Implementation template for escrow clones |
| **VouchifyVoucher** | [`0x96fb78d1256aC4bfdc2d26a4DadAFf9d58B8e597`](https://amoy.polygonscan.com/address/0x96fb78d1256aC4bfdc2d26a4DadAFf9d58B8e597) | ERC-721 NFT representing vouchers |
| **VouchifyEscrowFactory** | [`0x1E2DeE06593186F3eb4E62D5bb2d5275e857dbf7`](https://amoy.polygonscan.com/address/0x1E2DeE06593186F3eb4E62D5bb2d5275e857dbf7) | Factory for deploying escrow clones (EIP-1167) |
| **VouchifyPaymentWallet** | [`0x09bca54070702B5B12254F66412AF1F29BA8adC1`](https://amoy.polygonscan.com/address/0x09bca54070702B5B12254F66412AF1F29BA8adC1) | Implementation template for payment wallet clones |
| **VouchifyPaymentWalletFactory** | [`0x440150ef4A9D89ED6d72F11608550bD035a8CEE7`](https://amoy.polygonscan.com/address/0x440150ef4A9D89ED6d72F11608550bD035a8CEE7) | Factory for deploying payment wallet clones |
| **VouchifyMembership** | [`0xD2F483fbd6b9d138a4116c6E0c3223f0083b71c6`](https://amoy.polygonscan.com/address/0xD2F483fbd6b9d138a4116c6E0c3223f0083b71c6) | Implementation template for membership clones |
| **VouchifyMembershipFactory** | [`0xE7D5963FB224682d5504510B300c5F745558D53d`](https://amoy.polygonscan.com/address/0xE7D5963FB224682d5504510B300c5F745558D53d) | Factory for deploying membership clones |

### Transaction Hashes

| Contract | Transaction Hash |
|----------|------------------|
| VouchifyEscrow | [`0xd26ab573d6585b057fc8cd2a4048383bcefc9309e78ac68c6e03cfa8467f34ef`](https://amoy.polygonscan.com/tx/0xd26ab573d6585b057fc8cd2a4048383bcefc9309e78ac68c6e03cfa8467f34ef) |
| VouchifyVoucher | [`0x5226025e329f6660abc224d4277336eecafefad69895fa84c66daeb6ac4efe6a`](https://amoy.polygonscan.com/tx/0x5226025e329f6660abc224d4277336eecafefad69895fa84c66daeb6ac4efe6a) |
| VouchifyEscrowFactory | [`0xacd1f233466e442c6258ed0025828794fa93880f19eba6c6d4f1a048ae45002e`](https://amoy.polygonscan.com/tx/0xacd1f233466e442c6258ed0025828794fa93880f19eba6c6d4f1a048ae45002e) |
| VouchifyPaymentWallet | [`0xb630199d57062a954a2ef04a6872929907f72f0d7d652e8444c5eb7921059f37`](https://amoy.polygonscan.com/tx/0xb630199d57062a954a2ef04a6872929907f72f0d7d652e8444c5eb7921059f37) |
| VouchifyPaymentWalletFactory | [`0x3f72ae5c5fed2833da86233a051c1f7f53c7ef59c669e12bb1a8e6d3a7b30d03`](https://amoy.polygonscan.com/tx/0x3f72ae5c5fed2833da86233a051c1f7f53c7ef59c669e12bb1a8e6d3a7b30d03) |
| VouchifyMembership | [`0x0bf3ec6a557ea83080ab8ac3dd11aa3708e818d4bd67a33916ff25f411a2f482`](https://amoy.polygonscan.com/tx/0x0bf3ec6a557ea83080ab8ac3dd11aa3708e818d4bd67a33916ff25f411a2f482) |
| VouchifyMembershipFactory | [`0x40fedf33a5dc3101cfc8c2182bf3168c776666d05e8877667e61968de00038c5`](https://amoy.polygonscan.com/tx/0x40fedf33a5dc3101cfc8c2182bf3168c776666d05e8877667e61968de00038c5) |
| Link: setVoucherContract | [`0x45477b8cc94849b62056da1a14359502a4837fec497ce4a2c84a7f8dfbccce6d`](https://amoy.polygonscan.com/tx/0x45477b8cc94849b62056da1a14359502a4837fec497ce4a2c84a7f8dfbccce6d) |
| Link: setFactory | [`0xc2d322d3e0ae76878def060e56b19f656bd46d72004078aa1c128a80aaaa5c9a`](https://amoy.polygonscan.com/tx/0xc2d322d3e0ae76878def060e56b19f656bd46d72004078aa1c128a80aaaa5c9a) |

### Verification

All 5 contracts verified on PolygonScan ✅

Membership contracts (VouchifyMembership + Factory) verified ✅

---

## Celo Alfajores (Testnet)

**Network:** Celo L2 Testnet (Sepolia)  
**Chain ID:** 11142220  
**Deployed:** February 19, 2026  
**Deployer:** `0xEC891A037F932493624184970a283ab87398e0A6`  
**Cold Wallet:** `0xEC891A037F932493624184970a283ab87398e0A6` (deployer default)  
**RPC:** `https://celo-sepolia.drpc.org`

### Contract Addresses

| Contract | Address | Description |
|----------|---------|-------------|
| **VouchifyEscrow** | [`0x1A7E36a76dC36B32C6061B2fA897B854782E22e3`](https://sepolia.celoscan.io/address/0x1A7E36a76dC36B32C6061B2fA897B854782E22e3) | Implementation template for escrow clones |
| **VouchifyVoucher** | [`0xf00193015128cCbd2b7C9482064221435b6Bb39D`](https://sepolia.celoscan.io/address/0xf00193015128cCbd2b7C9482064221435b6Bb39D) | ERC-721 NFT representing vouchers |
| **VouchifyEscrowFactory** | [`0xaaBa585929Ee2F8A015d4f7378604d56d93Cb85D`](https://sepolia.celoscan.io/address/0xaaBa585929Ee2F8A015d4f7378604d56d93Cb85D) | Factory for deploying escrow clones (EIP-1167) |
| **VouchifyPaymentWallet** | [`0xeEEb6f0884DE5a880dcA7ca22B10528413Aa66D2`](https://sepolia.celoscan.io/address/0xeEEb6f0884DE5a880dcA7ca22B10528413Aa66D2) | Implementation template for payment wallet clones |
| **VouchifyPaymentWalletFactory** | [`0x224b6EfF956730EF0ca6C6299Cee9ac0855d3249`](https://sepolia.celoscan.io/address/0x224b6EfF956730EF0ca6C6299Cee9ac0855d3249) | Factory for deploying payment wallet clones |
| **VouchifyMembership** | [`0x1b98C54502590deed1D41EBb318051a1C37b7157`](https://sepolia.celoscan.io/address/0x1b98C54502590deed1D41EBb318051a1C37b7157) | Implementation template for membership clones |
| **VouchifyMembershipFactory** | [`0x173e3B2A4Ccc21e6178d333c4336c1A7Eb333D5e`](https://sepolia.celoscan.io/address/0x173e3B2A4Ccc21e6178d333c4336c1A7Eb333D5e) | Factory for deploying membership clones |

### Transaction Hashes

| Contract | Transaction Hash |
|----------|------------------|
| VouchifyEscrow | [`0xa6f6f6f5748b45cb2befd04951564a106ce07a396e8f2961c6dd82ce2389b7b1`](https://sepolia.celoscan.io/tx/0xa6f6f6f5748b45cb2befd04951564a106ce07a396e8f2961c6dd82ce2389b7b1) |
| VouchifyVoucher | [`0xaf3f64e20de231cfef4405b96655bd71258aed54586d78bf4111d37123eb8ab3`](https://sepolia.celoscan.io/tx/0xaf3f64e20de231cfef4405b96655bd71258aed54586d78bf4111d37123eb8ab3) |
| VouchifyEscrowFactory | [`0x05f9b509e8750b5f547a7ea810b472802e2bc81ae60d0aad65a48c6c92cda655`](https://sepolia.celoscan.io/tx/0x05f9b509e8750b5f547a7ea810b472802e2bc81ae60d0aad65a48c6c92cda655) |
| VouchifyPaymentWallet | [`0x7ee0ea34e52f3e4f53286365915fddbe87a323477deb0d0ec83530d2a08067a1`](https://sepolia.celoscan.io/tx/0x7ee0ea34e52f3e4f53286365915fddbe87a323477deb0d0ec83530d2a08067a1) |
| VouchifyPaymentWalletFactory | [`0xcc5af65b6ffc269742ab58caf4b643159803360722ac3f132ebba472dcaf6d63`](https://sepolia.celoscan.io/tx/0xcc5af65b6ffc269742ab58caf4b643159803360722ac3f132ebba472dcaf6d63) |
| VouchifyMembership | [`0x3bb6404c8d7574d65da53836ca01e93798ee69b33c7dded2cbea4745eb3a2ed3`](https://sepolia.celoscan.io/tx/0x3bb6404c8d7574d65da53836ca01e93798ee69b33c7dded2cbea4745eb3a2ed3) |
| VouchifyMembershipFactory | [`0xf353f10771963ee29f77912bd0aa22e646dad425b44479a8914100bdabd10b1f`](https://sepolia.celoscan.io/tx/0xf353f10771963ee29f77912bd0aa22e646dad425b44479a8914100bdabd10b1f) |
| Link: setVoucherContract | [`0xa6ca86b43c83072be818a6a64938f029cd5f68c348b1b7e13b23fd23c9d49d97`](https://sepolia.celoscan.io/tx/0xa6ca86b43c83072be818a6a64938f029cd5f68c348b1b7e13b23fd23c9d49d97) |
| Link: setFactory | [`0x689b6d3a1d2c2e895d2220b54937e12492c243b9983b70c508c2aad03a90c381`](https://sepolia.celoscan.io/tx/0x689b6d3a1d2c2e895d2220b54937e12492c243b9983b70c508c2aad03a90c381) |

### Verification

Contracts not yet verified (Foundry does not natively support chain 11142220 for `--verify`). Verify manually via [CeloScan Sepolia](https://sepolia.celoscan.io/verifyContract).

---

## Mainnets

### Base Mainnet

**Network:** Base  
**Chain ID:** 8453  
**Deployed:** February 24, 2026  
**Deployer:** `0xc0C1e025E7Cedf2A1bdad918F68dEAD56882a3C4`  
**Cold Wallet:** `0x4A0c0320D09EA02344dB8629b176c263851AD2D5`  
**Total Gas Cost:** 0.000042631128526224 ETH (8,526,224 gas × avg 0.005 gwei)

#### Contract Addresses

| Contract | Address | Description |
|----------|---------|-------------|
| **VouchifyEscrow** | [`0x01028F6878D9BBFF45B193310aDF4D3e36ECD147`](https://basescan.org/address/0x01028F6878D9BBFF45B193310aDF4D3e36ECD147) | Implementation template for escrow clones |
| **VouchifyVoucher** | [`0xD1Ab661CaF8d79CFebbAB463914624678E929BFB`](https://basescan.org/address/0xD1Ab661CaF8d79CFebbAB463914624678E929BFB) | ERC-721 NFT representing vouchers |
| **VouchifyEscrowFactory** | [`0xa215df5bc5010D4eBf98e8644AFb5fdC0cF34C0F`](https://basescan.org/address/0xa215df5bc5010D4eBf98e8644AFb5fdC0cF34C0F) | Factory for deploying escrow clones (EIP-1167) |
| **VouchifyPaymentWallet** | [`0xB845c622Eb403c27e9Ef5D1CecA1662Ae276239f`](https://basescan.org/address/0xB845c622Eb403c27e9Ef5D1CecA1662Ae276239f) | Implementation template for payment wallet clones |
| **VouchifyPaymentWalletFactory** | [`0x6F0ab97d19Bf7F3Ae6660C60Ffd81d5c4bdaBB7f`](https://basescan.org/address/0x6F0ab97d19Bf7F3Ae6660C60Ffd81d5c4bdaBB7f) | Factory for deploying payment wallet clones |
| **VouchifyMembership** | [`0xaACe9F8916B6642bd8a5B4390D83caE42a02A8dC`](https://basescan.org/address/0xaACe9F8916B6642bd8a5B4390D83caE42a02A8dC) | Implementation template for membership clones |
| **VouchifyMembershipFactory** | [`0xb763aA63A34DB988ca9EB632753909A8d3361d82`](https://basescan.org/address/0xb763aA63A34DB988ca9EB632753909A8d3361d82) | Factory for deploying membership clones |

#### Transaction Hashes

| Contract | Transaction Hash |
|----------|------------------|
| VouchifyEscrow | [`0x706304e7b40e88c26bf4db79f9d13e06308d5a3fe620e8e633d1665e0838df39`](https://basescan.org/tx/0x706304e7b40e88c26bf4db79f9d13e06308d5a3fe620e8e633d1665e0838df39) |
| VouchifyVoucher | [`0xdf671aba7ea659a0b88b3be636a20f801a1239bf01082f7d8e61d83fc61e8733`](https://basescan.org/tx/0xdf671aba7ea659a0b88b3be636a20f801a1239bf01082f7d8e61d83fc61e8733) |
| VouchifyEscrowFactory | [`0x052df19a7ab73f91d823e00d1472548c6c13c159976b883deb2c71eec6d60a3b`](https://basescan.org/tx/0x052df19a7ab73f91d823e00d1472548c6c13c159976b883deb2c71eec6d60a3b) |
| VouchifyPaymentWallet | [`0x33765fb076ea1f7822d9ebf968b75899cbc15e2556d683942da9edef880c3c10`](https://basescan.org/tx/0x33765fb076ea1f7822d9ebf968b75899cbc15e2556d683942da9edef880c3c10) |
| VouchifyPaymentWalletFactory | [`0x5eb61a81957e8ac7231921f24d73a717465095ab59e2930919aa0b0e8141458e`](https://basescan.org/tx/0x5eb61a81957e8ac7231921f24d73a717465095ab59e2930919aa0b0e8141458e) |
| VouchifyMembership | [`0x958729123e46970a643c6f134b72a1254a873782f7325193b132a53b0780f54d`](https://basescan.org/tx/0x958729123e46970a643c6f134b72a1254a873782f7325193b132a53b0780f54d) |
| VouchifyMembershipFactory | [`0xb0228e70c42f581777e078669cef92fb193032de20a23ab365f7e26f49b4d004`](https://basescan.org/tx/0xb0228e70c42f581777e078669cef92fb193032de20a23ab365f7e26f49b4d004) |
| Link: setVoucherContract (Escrow) | [`0xb642487d98a904692291294b767f3a0af0b888ef08d97e3b93061ffc524003cc`](https://basescan.org/tx/0xb642487d98a904692291294b767f3a0af0b888ef08d97e3b93061ffc524003cc) |
| Link: setFactory | [`0x3a4c2582075726bb8c790acaedd35604b2964b60fec6dbb156ffdf73fd7cd644`](https://basescan.org/tx/0x3a4c2582075726bb8c790acaedd35604b2964b60fec6dbb156ffdf73fd7cd644) |
| Link: setVoucherContract (Membership) | [`0x96f440e46877dc0d55db074e1060f4bc3232ddf9169783b4980d5b3f9cbc7f76`](https://basescan.org/tx/0x96f440e46877dc0d55db074e1060f4bc3232ddf9169783b4980d5b3f9cbc7f76) |
| Link: grantRole FACTORY_ROLE | [`0x6e922bd69c6e617e3c42453761690c158e78fdefa8400723fda880045a98d4bd`](https://basescan.org/tx/0x6e922bd69c6e617e3c42453761690c158e78fdefa8400723fda880045a98d4bd) |

#### Verification

All 7 contracts verified on BaseScan ✅

#### Roles Configuration

| Role | Address |
|------|---------|
| Admin | `0xc0C1e025E7Cedf2A1bdad918F68dEAD56882a3C4` |
| Operator | `0xc0C1e025E7Cedf2A1bdad918F68dEAD56882a3C4` |
| Pauser | `0xc0C1e025E7Cedf2A1bdad918F68dEAD56882a3C4` |
| Cold Wallet | `0x4A0c0320D09EA02344dB8629b176c263851AD2D5` |

### BSC Mainnet

*Not yet deployed*

### Polygon Mainnet

*Not yet deployed*

### Celo Mainnet

*Not yet deployed*

---

## Deployment Commands

```bash
# Deploy to testnets (uses foundry.toml [rpc_endpoints] aliases)
forge script script/Deploy.s.sol --rpc-url base_sepolia    --broadcast --verify
forge script script/Deploy.s.sol --rpc-url bsc_testnet      --broadcast --verify
forge script script/Deploy.s.sol --rpc-url polygon_amoy     --broadcast --verify
forge script script/Deploy.s.sol --rpc-url celo_alfajores   --broadcast --verify

# Deploy to mainnets
forge script script/Deploy.s.sol --rpc-url base     --broadcast --verify
forge script script/Deploy.s.sol --rpc-url bsc      --broadcast --verify
forge script script/Deploy.s.sol --rpc-url polygon  --broadcast --verify
forge script script/Deploy.s.sol --rpc-url celo     --broadcast --verify
```

## Post-Deployment Checklist

- [ ] Transfer admin role to multisig
- [ ] Set separate operator wallet for backend
- [ ] Set separate pauser wallet for emergency response
- [ ] Set production cold wallet for payment sweeps
- [ ] Update API with contract addresses
- [ ] Test escrow creation flow
- [ ] Test payment wallet creation and sweep flow


Base Mainnet:
VouchifyVoucher: 0x5a5132941665208b2a8e25060c9e74fddcbb80e9
VouchifyEscrowFactory: 0x868d72a7a577e0bb00017eb7692ff2b2f7e13f0a
VouchifyEscrowFactory: 0x868d72a7a577e0bb00017eb7692ff2b2f7e13f0a
VouchifyPaymentWalletFactory: 0x65ab244d811efadc4b01587dbf5d7177596dc403
VouchifyPaymentWalletFactory: 0x65ab244d811efadc4b01587dbf5d7177596dc403
VouchifyMembershipFactory: 0xbbf0fa835085f740ae60063969b247f216081649
VouchifyMembershipFactory: 0xbbf0fa835085f740ae60063969b247f216081649