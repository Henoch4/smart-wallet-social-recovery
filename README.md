# Social Recovery Wallet — Wallets You Can Recover

> A wallet whose primary key is a guardian quorum. Lose a key and your guardians - friends, family, other wallets - can vote a replacement in; no seed phrase means no single point of failure.

## What it does

A wallet whose primary key is a guardian quorum. Lose a key and your guardians - friends, family, other wallets - can vote a replacement in; no seed phrase means no single point of failure. The entire lifecycle lives in one contract, every button in the UI calls a real function on it — there is no mock backend.

## Contract

| | |
|---|---|
| File | `contracts/SmartWalletSocialRecovery.sol` |
| Contract name | `SmartWalletSocialRecovery` (inherits `ReentrancyGuard, Ownable`) |
| Solidity | `^0.8.20` |
| State functions | 6 (of which 0 payable) |
| Deployed (mainnet 677) | not yet deployed — placeholder `0x000…000` |

### Function surface

| Function | Type | Returns |
|---|---|---|
| `owner` | view | address |
| `createWallet` | write | result / revert |
| `addGuardian` | write | result / revert |
| `initiateRecovery` | write | result / revert |
| `completeRecovery` | write | result / revert |
| `getWallet` | view | address ownerAddress, uint256 threshold, uint256 recoveryNonce, bool locked, uint256 guardianCount, address pendingNewOwner |

### Events

| Event | Signature |
|---|---|
| `OwnershipTransferred` | (address indexed previousOwner, address indexed newOwner) |
| `WalletCreated` | (address indexed owner, uint256 threshold) |
| `GuardianAdded` | (address indexed wallet, address indexed guardian, uint256 weight) |
| `RecoveryInitiated` | (address indexed wallet, address indexed recoveryTarget) |
| `RecoveryApproved` | (address indexed wallet, address indexed guardian, uint256 approvalWeight, uint256 threshold) |
| `RecoveryCompleted` | (address indexed wallet, address indexed newOwner) |

## Network

| | |
|---|---|
| Chain | BOT Chain Mainnet (chainId `677`) |
| RPC | `https://rpc.botchain.ai` |
| Explorer | `https://scan.botchain.ai` |
| Native currency | BOT (18 decimals) |
| Testnet | BOT Chain Testnet (chainId `968`) - `https://rpc.bohr.life` |

## Frontend

- **Wallet connection** - [Reown/AppKit](https://reown.com) (Web3Modal v2, inline modal, `subscribeAccount` / `subscribeNetwork`)
- **Web3 library** - ethers.js v6 (`BrowserProvider`, `Contract`, `parseEther`)
- **Animation** - GSAP 3 + ScrollTrigger (`expo.out` entrances, `prefers-reduced-motion` fallback renders content instantly)
- **Zero build step** - single `index.html`, CDN imports via ESM import map; no bundler, no framework runtime
- **Accessibility** - auto-generated `aria-label`s on all binary and form controls, focus-visible styles, button busy states

## Run it locally

```bash
git clone https://github.com/Henoch4/smart-wallet-social-recovery.git
cd smart-wallet-social-recovery
# open the frontend directly (no build step)
start frontend/index.html   # Windows
# or serve it if your browser blocks file:// modules:
npx serve frontend
```

> **Note** — contract addresses: the UI reads its deploy target from the `CA` constant at the top of the inline script. Until the contract is deployed to mainnet 677, the demo runs against the deterministic sample data built into the page; after deployment, set `CA['677']` to the real address and every button goes live.