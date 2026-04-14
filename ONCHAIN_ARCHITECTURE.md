# Vouchify On-Chain Architecture

## Overview

Vouchify uses a hybrid on-chain/off-chain architecture to enable secure voucher purchases, transparent tracking, and flexible payment options. This document outlines the smart contract architecture and payment flows.

**Key Design Decision**: We use the **EIP-1167 Minimal Proxy (Clone) pattern** for per-voucher escrows, providing individual tracking while keeping deployment costs low (~$0.05-0.20 per voucher on Base L2).

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Clone Factory Pattern](#clone-factory-pattern)
3. [Payment Flows](#payment-flows)
4. [Smart Contracts](#smart-contracts)
5. [Wallet Architecture](#wallet-architecture)
6. [Redemption & Payout Flow](#redemption--payout-flow)
7. [Security Considerations](#security-considerations)
8. [Contract Interfaces](#contract-interfaces)
9. [Deployment Plan](#deployment-plan)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              VOUCHIFY PLATFORM                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │    User     │    │  Flutterwave │    │   Backend   │    │  Blockchain │  │
│  │  (Buyer)    │    │   Gateway    │    │    API      │    │   (Base)    │  │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘  │
│         │                  │                  │                   │         │
│         │  Card/MoMo/Bank  │                  │                   │         │
│         ├─────────────────►│                  │                   │         │
│         │                  │  Webhook         │                   │         │
│         │                  ├─────────────────►│                   │         │
│         │                  │                  │  Deploy Escrow    │         │
│         │                  │                  │  Clone            │         │
│         │                  │                  ├──────────────────►│         │
│         │                  │                  │  Mint Voucher NFT │         │
│         │                  │                  ├──────────────────►│         │
│         │◄─────────────────┼──────────────────┤                   │         │
│         │        Voucher NFT Received         │                   │         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Clone Factory Pattern

### Why Per-Voucher Escrows?

| Approach | Pros | Cons |
|----------|------|------|
| **Single Escrow** | Simple, one deployment | Growing storage forever, hard to track individual vouchers |
| **Full Contract Per Voucher** | Clean lifecycle | Expensive ($2-5 per contract) |
| **Clone Factory (Chosen)** | Best of both worlds | Slightly more complex |

### How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         VouchifyEscrowFactory                                │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │              EscrowImplementation (deployed ONCE)                    │   │
│   │              Contains all the logic (~2000+ bytes)                   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│          ┌─────────────────────────┼─────────────────────────┐              │
│          │                         │                         │              │
│          ▼                         ▼                         ▼              │
│   ┌─────────────┐          ┌─────────────┐          ┌─────────────┐        │
│   │  Clone #1   │          │  Clone #2   │          │  Clone #3   │        │
│   │  (45 bytes) │          │  (45 bytes) │          │  (45 bytes) │        │
│   │             │          │             │          │             │        │
│   │ Voucher A   │          │ Voucher B   │          │ Voucher C   │        │
│   │ Buyer: 0x1  │          │ Buyer: 0x2  │          │ Buyer: 0x3  │        │
│   │ Amount: $50 │          │ Amount: $100│          │ Amount: $25 │        │
│   └─────────────┘          └─────────────┘          └─────────────┘        │
│                                                                              │
│   Each clone: ~$0.05-0.20 on Base L2                                        │
│   Each clone has its OWN storage but delegates logic to implementation      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Benefits

1. **Individual Tracking**: Each voucher has its own contract address
2. **Cheap Deployment**: ~$0.05-0.20 per clone on Base L2 (vs $2-5 for full contract)
3. **Clean Lifecycle**: When voucher is redeemed/expired, the clone is "done"
4. **No Storage Bloat**: No growing mappings in a single contract
5. **Easy Querying**: NFT tokenId can map directly to escrow address
6. **Upgradeable**: Can deploy new implementation without affecting existing clones

### Voucher Lifecycle

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Payment    │───►│ Deploy Clone │───►│  Mint NFT    │───►│   Active     │
│   Received   │    │   Escrow     │    │  to Buyer    │    │   Voucher    │
└──────────────┘    └──────────────┘    └──────────────┘    └──────┬───────┘
                                                                   │
                    ┌──────────────────────────────────────────────┤
                    │                                              │
                    ▼                                              ▼
           ┌──────────────┐                               ┌──────────────┐
           │   Redeemed   │                               │   Expired    │
           │  (Clone Done)│                               │  (Clone Done)│
           └──────────────┘                               └──────────────┘
```

---

## Payment Flows

### Flow 1: Fiat Payment (Card, Mobile Money, Bank Transfer)

```
User ──► Flutterwave ──► Webhook ──► Backend ──► Deploy Escrow Clone ──► Mint Voucher NFT
                              │
                              ▼
                    Fiat held in Flutterwave
                    (Available for merchant payouts)
```

**Steps:**
1. User selects payment method (Card, Mobile Money, Bank Transfer)
2. Payment processed via Flutterwave
3. Flutterwave sends webhook confirmation to backend
4. Backend calls `EscrowFactory.createEscrow()` - deploys a new clone
5. Backend calls `VoucherNFT.mint()` - mints NFT linked to escrow clone address
6. User receives Voucher NFT
7. Fiat remains in Flutterwave balance for merchant payouts

### Flow 2: Crypto Payment (USDC/USDT)

```
User ──► Factory Creates Payment Wallet ──► User Transfers Crypto ──► Backend Detects
                                                                            │
         ┌──────────────────────────────────────────────────────────────────┘
         │
         ▼
Deploy Escrow Clone ──► Mint Voucher NFT ──► Sweep Crypto to Cold Wallet
```

**Steps:**
1. User selects crypto payment (USDC/USDT)
2. Backend calls `PaymentWalletFactory.createPaymentWallet()` - deploys temporary wallet
3. User receives wallet address and transfers exact crypto amount
4. Backend detects incoming transfer (event listener or polling)
5. Backend calls `EscrowFactory.createEscrow()` - deploys escrow clone
6. Backend calls `VoucherNFT.mint()` - mints NFT to user
7. Backend calls `PaymentWallet.sweep()` - moves crypto to cold storage
8. Cold wallet manager manually converts crypto to fiat (for payout liquidity)

---

## Smart Contracts

### Contract Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CORE CONTRACTS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐    ┌─────────────────────┐                        │
│  │ VouchifyEscrowFactory│    │ VouchifyVoucher     │                        │
│  │ (Deploys Clones)     │◄──►│ (ERC-721 NFT)       │                        │
│  └──────────┬──────────┘    └─────────────────────┘                        │
│             │                                                               │
│             │ creates                                                       │
│             ▼                                                               │
│  ┌─────────────────────┐                                                   │
│  │ VouchifyEscrow      │ ◄── Implementation (logic)                        │
│  │ (Clone Template)    │                                                   │
│  └─────────────────────┘                                                   │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                            SUPPORTING CONTRACTS                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐    ┌─────────────────────┐                        │
│  │ VouchifyPaymentWallet│    │ VouchifyMerchant    │                        │
│  │ Factory              │    │ Registry            │                        │
│  └──────────┬──────────┘    └─────────────────────┘                        │
│             │                                                               │
│             │ creates                                                       │
│             ▼                                                               │
│  ┌─────────────────────┐                                                   │
│  │ VouchifyPaymentWallet│ ◄── Minimal wallet for crypto payments           │
│  │ (Clone Template)     │                                                   │
│  └─────────────────────┘                                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 1. VouchifyEscrowFactory.sol

Factory contract that deploys minimal proxy clones for each voucher.

```solidity
contract VouchifyEscrowFactory {
    address public implementation;          // Escrow logic contract
    address public voucherNFT;              // VouchifyVoucher contract
    address public admin;                   // Platform admin
    
    // Mapping: voucherId => escrow clone address
    mapping(bytes32 => address) public escrows;
    
    // Mapping: NFT tokenId => escrow clone address
    mapping(uint256 => address) public tokenIdToEscrow;
    
    event EscrowCreated(
        bytes32 indexed voucherId,
        address indexed escrowAddress,
        address buyer,
        address merchant,
        uint256 amount
    );
}
```

**Key Functions:**
- `createEscrow()` - Deploy new escrow clone and mint NFT
- `getEscrowAddress()` - Predict escrow address (CREATE2) before deployment
- `setImplementation()` - Update implementation for future clones (admin)

---

### 2. VouchifyEscrow.sol (Clone Template)

Each clone holds data for ONE voucher. Logic is delegated to implementation.

```solidity
contract VouchifyEscrow {
    // ============ Voucher Data ============
    bytes32 public voucherId;           // Unique identifier
    uint256 public tokenId;             // NFT token ID
    
    // ============ Parties ============
    address public buyer;               // Original purchaser
    address public merchant;            // Merchant wallet
    address public currentOwner;        // Current NFT holder (for gifts)
    
    // ============ Payment Details ============
    uint256 public amount;              // Total amount (in base units)
    uint256 public remainingAmount;     // Remaining after partial redemptions
    uint256 public platformFee;         // Platform fee amount
    PaymentMethod public paymentMethod; // FIAT, USDC, USDT
    string public externalTxId;         // Flutterwave tx ID (fiat only)
    
    // ============ Status ============
    EscrowStatus public status;         // PENDING, ACTIVE, PARTIALLY_REDEEMED, REDEEMED, REFUNDED, EXPIRED
    
    // ============ Timestamps ============
    uint256 public createdAt;
    uint256 public expiresAt;
    uint256 public redeemedAt;
    
    // ============ Redemption History ============
    Redemption[] public redemptions;    // For partial redemptions
    
    struct Redemption {
        uint256 amount;
        uint256 timestamp;
        address redeemedBy;     // Merchant who processed
    }
    
    enum PaymentMethod { FIAT, USDC, USDT }
    enum EscrowStatus { PENDING, ACTIVE, PARTIALLY_REDEEMED, REDEEMED, REFUNDED, EXPIRED }
}
```

**Key Functions:**
- `initialize()` - Called once after clone deployment
- `activate()` - Move from PENDING to ACTIVE (after payment confirmed)
- `redeem()` - Full or partial redemption by merchant
- `refund()` - Refund to buyer (admin only, before redemption)
- `expire()` - Mark as expired (after expiresAt)
- `syncOwner()` - Update currentOwner when NFT is transferred

---

### 3. VouchifyVoucher.sol (ERC-721)

NFT contract for voucher ownership. Each token is linked to an escrow clone.

```solidity
contract VouchifyVoucher is ERC721, ERC721Enumerable, AccessControl {
    // ============ Mappings ============
    mapping(uint256 => address) public tokenEscrow;     // tokenId => escrow address
    mapping(uint256 => VoucherMetadata) public metadata;
    
    struct VoucherMetadata {
        address escrowAddress;      // Link to escrow clone
        uint256 merchantId;         // Off-chain merchant ID
        uint256 originalAmount;     // Purchase amount
        uint256 purchasedAt;
        uint256 expiresAt;
        bool isGift;                // Was this gifted?
        address originalBuyer;
    }
    
    // ============ Events ============
    event VoucherMinted(uint256 indexed tokenId, address indexed escrow, address indexed owner);
    event VoucherRedeemed(uint256 indexed tokenId, uint256 amount, bool fullyRedeemed);
    event VoucherTransferred(uint256 indexed tokenId, address from, address to);
}
```

**Key Functions:**
- `mint()` - Mint new voucher NFT (only callable by EscrowFactory)
- `burn()` - Burn fully redeemed/expired vouchers
- `getVoucher()` - Get voucher metadata
- `_afterTokenTransfer()` - Override to sync owner with escrow

---

### 4. VouchifyPaymentWalletFactory.sol

Creates temporary wallets for crypto payments.

```solidity
contract VouchifyPaymentWalletFactory {
    address public implementation;      // PaymentWallet logic
    address public coldWallet;          // Multi-sig cold storage
    address public admin;
    
    // Mapping: paymentId => wallet address
    mapping(bytes32 => address) public wallets;
    
    event WalletCreated(bytes32 indexed paymentId, address indexed wallet, address token, uint256 amount);
    event WalletSwept(bytes32 indexed paymentId, address indexed wallet, uint256 amount);
}
```

**Key Functions:**
- `createPaymentWallet()` - Deploy wallet clone for specific payment
- `getWalletAddress()` - Predict address (CREATE2)
- `sweepWallet()` - Move funds to cold storage
- `sweepAll()` - Batch sweep multiple wallets

---

### 5. VouchifyPaymentWallet.sol (Clone Template)

Minimal wallet for receiving crypto payments.

```solidity
contract VouchifyPaymentWallet {
    address public factory;
    bytes32 public paymentId;
    address public expectedToken;       // USDC or USDT address
    uint256 public expectedAmount;
    address public buyer;
    bool public swept;
    
    event PaymentReceived(address token, uint256 amount);
    event Swept(address to, uint256 amount);
}
```

**Key Functions:**
- `initialize()` - Set up wallet parameters
- `getBalance()` - Check token balance
- `sweep()` - Move funds to cold wallet (factory only)

---

### 6. VouchifyMerchantRegistry.sol

On-chain registry of verified merchants with balance tracking.

```solidity
contract VouchifyMerchantRegistry {
    struct MerchantRecord {
        uint256 merchantId;             // Off-chain ID
        address walletAddress;          // Verified wallet
        bool isVerified;                // KYB approved
        bool isActive;                  // Can receive vouchers
        uint256 totalEarned;            // Lifetime earnings
        uint256 pendingBalance;         // Available for withdrawal
        uint256 withdrawnTotal;         // Total withdrawn
        uint256 registeredAt;
    }
    
    mapping(uint256 => MerchantRecord) public merchants;
    mapping(address => uint256) public walletToMerchant;
    
    event MerchantRegistered(uint256 indexed merchantId, address wallet);
    event MerchantVerified(uint256 indexed merchantId);
    event BalanceCredited(uint256 indexed merchantId, uint256 amount, bytes32 voucherId);
    event BalanceDebited(uint256 indexed merchantId, uint256 amount, string reason);
}
```

**Key Functions:**
- `registerMerchant()` - Register new merchant (admin)
- `verifyMerchant()` - Mark as KYB verified (admin)
- `creditBalance()` - Add to pending balance (on redemption)
- `debitBalance()` - Deduct from balance (on withdrawal)
- `getMerchant()` - Get merchant details

---

## Wallet Architecture

### Platform Wallets

| Wallet Type | Purpose | Control |
|-------------|---------|---------|
| **Platform Admin Wallet** | Deploys contracts, manages system | Multi-sig (2-of-3 or 3-of-5) |
| **Factory Owner** | Creates escrow/payment clones | Platform Admin Wallet |
| **Cold Storage Wallet** | Holds crypto reserves | Multi-sig (cold storage, manual access) |
| **Hot Wallet** | Day-to-day operations, gas | Platform Admin (limited funds) |

### User Wallets

| Wallet Type | Purpose | Notes |
|-------------|---------|-------|
| **User EOA/Smart Wallet** | Receives voucher NFTs | User-controlled |
| **Payment Smart Wallet** | Temporary for crypto payments | Platform-controlled, single-use, auto-swept |

### Merchant Wallets

| Wallet Type | Purpose | Notes |
|-------------|---------|-------|
| **On-chain Balance** | Tracked in MerchantRegistry | Credits from redemptions |
| **Withdrawal Target** | Merchant's bank account | Via Flutterwave payout |

---

## Redemption & Payout Flow

### Voucher Redemption

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│  Customer  │────►│  Merchant  │────►│  Backend   │────►│  Escrow    │
│  (Shows    │     │  (Scans    │     │  (Calls    │     │  Clone     │
│   QR/NFT)  │     │   Code)    │     │  redeem()) │     │ (Updates)  │
└────────────┘     └────────────┘     └────────────┘     └─────┬──────┘
                                                               │
                                             ┌─────────────────┘
                                             ▼
                                   ┌────────────────────┐
                                   │ MerchantRegistry   │
                                   │ creditBalance()    │
                                   └────────────────────┘
```

**Steps:**
1. Customer presents voucher (QR code containing secret or shows NFT)
2. Merchant scans/verifies via Vouchify app
3. Backend verifies ownership and voucher validity
4. Backend calls `Escrow.redeem(amount)` on the clone
5. Escrow updates status and remaining amount
6. Backend calls `MerchantRegistry.creditBalance()`
7. If fully redeemed, NFT can be burned

### Partial Redemption Example

```
Voucher: $100
├── Redemption 1: $30 → Remaining: $70, Status: PARTIALLY_REDEEMED
├── Redemption 2: $50 → Remaining: $20, Status: PARTIALLY_REDEEMED
└── Redemption 3: $20 → Remaining: $0,  Status: REDEEMED (can burn NFT)
```

### Merchant Withdrawal

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│  Merchant  │────►│  Backend   │────►│  Merchant  │────►│ Flutterwave│
│  (Request  │     │ (Validates)│     │  Registry  │     │  (Payout)  │
│   $500)    │     │            │     │ debit()    │     │            │
└────────────┘     └────────────┘     └────────────┘     └─────┬──────┘
                                                               │
                                                               ▼
                                                      ┌────────────────┐
                                                      │  Merchant's    │
                                                      │  Bank Account  │
                                                      └────────────────┘
```

**Funds Source:**
- **Fiat payments**: Held in Flutterwave balance → Direct payout
- **Crypto payments**: Held in cold wallet → Manual conversion to fiat → Then payout

---

## Security Considerations

### Smart Contract Security

- [x] **EIP-1167 Clones**: Minimal proxy pattern for cheap deployment
- [ ] **Access Control**: OpenZeppelin AccessControl for role management
- [ ] **Reentrancy Guard**: On all state-changing functions
- [ ] **Pausable**: Emergency pause on factory and registry
- [ ] **Input Validation**: Check all parameters
- [ ] **Time Checks**: Validate expiry timestamps
- [ ] **Overflow Protection**: Solidity 0.8+ built-in checks

### Factory Security

- [ ] Only factory can initialize clones
- [ ] CREATE2 for predictable addresses
- [ ] Implementation cannot be reinitialized
- [ ] Admin functions behind timelock

### Wallet Security

- [ ] Multi-sig for admin wallet (Gnosis Safe)
- [ ] Cold storage for crypto reserves (multi-sig, offline keys)
- [ ] Payment wallets can only be swept to cold wallet
- [ ] Rate limiting on withdrawals

### Payment Security

- [ ] Verify Flutterwave webhook signatures
- [ ] Idempotent payment processing (check if escrow exists)
- [ ] Timeout for pending crypto payments (auto-refund)
- [ ] Amount validation (expectedAmount vs received)

---

## Contract Interfaces

### IVouchifyEscrowFactory

```solidity
interface IVouchifyEscrowFactory {
    event EscrowCreated(
        bytes32 indexed voucherId,
        address indexed escrowAddress,
        address buyer,
        address merchant,
        uint256 amount
    );
    
    function createEscrow(
        bytes32 voucherId,
        address buyer,
        address merchant,
        uint256 amount,
        uint256 platformFee,
        uint256 expiresAt,
        PaymentMethod method,
        string calldata externalTxId
    ) external returns (address escrowAddress, uint256 tokenId);
    
    function getEscrowAddress(bytes32 voucherId) external view returns (address);
    function getEscrowByTokenId(uint256 tokenId) external view returns (address);
}
```

### IVouchifyEscrow

```solidity
interface IVouchifyEscrow {
    event Activated(uint256 timestamp);
    event Redeemed(uint256 amount, uint256 remaining, address redeemedBy);
    event Refunded(uint256 amount, address refundedTo);
    event Expired(uint256 timestamp);
    event OwnerSynced(address newOwner);
    
    function initialize(
        bytes32 voucherId,
        uint256 tokenId,
        address buyer,
        address merchant,
        uint256 amount,
        uint256 platformFee,
        uint256 expiresAt,
        PaymentMethod method,
        string calldata externalTxId
    ) external;
    
    function activate() external;
    function redeem(uint256 amount) external returns (uint256 remaining);
    function refund() external;
    function expire() external;
    function syncOwner(address newOwner) external;
    
    // View functions
    function getDetails() external view returns (
        bytes32 voucherId,
        address buyer,
        address merchant,
        uint256 amount,
        uint256 remainingAmount,
        EscrowStatus status,
        uint256 expiresAt
    );
    function isRedeemable() external view returns (bool);
    function isExpired() external view returns (bool);
}
```

### IVouchifyVoucher

```solidity
interface IVouchifyVoucher {
    event VoucherMinted(uint256 indexed tokenId, address indexed escrow, address indexed owner);
    event VoucherRedeemed(uint256 indexed tokenId, uint256 amount, bool fullyRedeemed);
    event VoucherBurned(uint256 indexed tokenId);
    
    function mint(
        address to,
        address escrowAddress,
        uint256 merchantId,
        uint256 amount,
        uint256 expiresAt,
        bool isGift
    ) external returns (uint256 tokenId);
    
    function burn(uint256 tokenId) external;
    function getVoucher(uint256 tokenId) external view returns (VoucherMetadata memory);
    function getEscrow(uint256 tokenId) external view returns (address);
}
```

---

## Deployment Plan

### Phase 1: Development & Testing

1. [ ] Implement VouchifyEscrow.sol (clone template)
2. [ ] Implement VouchifyEscrowFactory.sol
3. [ ] Implement VouchifyVoucher.sol (ERC-721)
4. [ ] Implement VouchifyPaymentWallet.sol (clone template)
5. [ ] Implement VouchifyPaymentWalletFactory.sol
6. [ ] Implement VouchifyMerchantRegistry.sol
7. [ ] Write comprehensive Foundry tests
8. [ ] Gas optimization

### Phase 2: Testnet (Base Sepolia)

1. [ ] Deploy all contracts
2. [ ] Backend integration
3. [ ] End-to-end testing
4. [ ] Security review / audit

### Phase 3: Mainnet (Base)

1. [ ] Deploy with multi-sig ownership (Gnosis Safe)
2. [ ] Initialize with production parameters
3. [ ] Gradual rollout with limits
4. [ ] Monitor and iterate

### Contract Addresses

| Contract | Testnet (Base Sepolia) | Mainnet (Base) |
|----------|------------------------|----------------|
| VouchifyEscrow (Implementation) | - | - |
| VouchifyEscrowFactory | - | - |
| VouchifyVoucher | - | - |
| VouchifyPaymentWallet (Implementation) | - | - |
| VouchifyPaymentWalletFactory | - | - |
| VouchifyMerchantRegistry | - | - |

---

## Tech Stack

- **Blockchain**: Base (Ethereum L2)
- **Language**: Solidity 0.8.24+
- **Framework**: Foundry
- **Clone Pattern**: EIP-1167 (OpenZeppelin Clones)
- **Token Standards**: ERC-721 (Vouchers), ERC-20 (USDC/USDT)
- **Access Control**: OpenZeppelin AccessControl
- **Multi-sig**: Gnosis Safe
- **Deployment**: Foundry scripts with CREATE2

---

## Gas Estimates (Base L2)

| Operation | Estimated Gas | Estimated Cost (@ $0.001/gas) |
|-----------|---------------|-------------------------------|
| Deploy Escrow Clone | ~50,000 | ~$0.05 |
| Deploy Payment Wallet Clone | ~45,000 | ~$0.045 |
| Mint Voucher NFT | ~100,000 | ~$0.10 |
| Redeem Voucher | ~60,000 | ~$0.06 |
| **Total per Voucher Purchase** | ~150,000 | ~$0.15 |

*Note: Gas costs on Base L2 are significantly lower than Ethereum mainnet.*

---

## File Structure

```
vouchify-contracts/
├── src/
│   ├── core/
│   │   ├── VouchifyEscrow.sol              # Escrow clone template
│   │   ├── VouchifyEscrowFactory.sol       # Deploys escrow clones
│   │   └── VouchifyVoucher.sol             # ERC-721 voucher NFT
│   ├── payment/
│   │   ├── VouchifyPaymentWallet.sol       # Payment wallet template
│   │   └── VouchifyPaymentWalletFactory.sol
│   ├── registry/
│   │   └── VouchifyMerchantRegistry.sol    # Merchant balance tracking
│   ├── interfaces/
│   │   ├── IVouchifyEscrow.sol
│   │   ├── IVouchifyEscrowFactory.sol
│   │   ├── IVouchifyVoucher.sol
│   │   └── IVouchifyMerchantRegistry.sol
│   └── libraries/
│       └── VouchifyErrors.sol              # Custom errors
├── test/
│   ├── VouchifyEscrow.t.sol
│   ├── VouchifyEscrowFactory.t.sol
│   ├── VouchifyVoucher.t.sol
│   └── integration/
│       └── FullFlow.t.sol
├── script/
│   ├── Deploy.s.sol
│   └── DeployTestnet.s.sol
├── ONCHAIN_ARCHITECTURE.md
└── foundry.toml
```

---

## Next Steps

1. **Set up Foundry project structure** - Create folders and foundry.toml
2. **Implement interfaces first** - Define clean contract boundaries
3. **Build VouchifyEscrow** - Clone template with all voucher logic
4. **Build VouchifyEscrowFactory** - Clone deployment with OpenZeppelin Clones
5. **Build VouchifyVoucher** - ERC-721 with escrow linking
6. **Write unit tests** - Test each contract in isolation
7. **Write integration tests** - Full purchase → redemption flow
8. **Deploy to Base Sepolia** - Test with backend integration
