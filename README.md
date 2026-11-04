# Social Recovery Wallet

Deposit and send native BOT through a guardian-protected wallet. Recovery changes the owner’s spending authority after the required guardian approvals. Token custody is not supported.

## Mainnet status

Contract on BOT Chain mainnet (677): [0x7F02b8b67b72C394D4e1e479D6d2326ce5E9aec4](https://scan.botchain.ai/address/0x7F02b8b67b72C394D4e1e479D6d2326ce5E9aec4).

Wallet actions require BOT Chain mainnet, deployed bytecode, and a connected compatible wallet. Every action is simulated before a transaction review; only a subsequent wallet confirmation can send it.

## Interface

- Live reads use the configured mainnet address; an unavailable RPC produces an explicit error.
- No seeded financial metrics, synthetic receipts, or assessment traces appear in the product.
- Management actions require proof of the connected account’s owner, creator, oracle, merchant, guardian, or record role. The contract remains the authority.
- Account/network changes invalidate an open transaction review.
- The footer provides BOT Chain and BOTScan homepage links; deployed products also link to their contract.
- Ethers is vendored locally with its license. No CDN script is required for wallet or contract operations.

## Contract interface

`frontend/product.json` uses the current-source ABI, matched against the deployed mainnet runtime bytecode. Explorer source publication is tracked separately.

| Action | Contract signature |
|---|---|
| Add a guardian | `addGuardian(address,address,uint256)` |
| Cancel pending recovery | `cancelRecovery(address)` |
| Approve recovery | `completeRecovery(address,address)` |
| Create your recovery registry | `createWallet(uint256)` |
| Deposit tokens | `deposit(address)` |
| Start recovery | `initiateRecovery(address,address)` |
| Remove a guardian | `removeGuardian(address,address)` |
| Send from your recovered wallet | `sendBOT(address,address,uint256)` |
| Set the recovery quorum | `setThreshold(address,uint256)` |

## Run locally

Serve the frontend over HTTP so the browser can load its configuration:

```sh
python -m http.server 8080 --directory frontend
```

Open http://localhost:8080. Only connect a wallet when you intend to use the configured mainnet contract.

## Regression test

```sh
npm install
npm test
```

The test requires Chromium or Edge. Windows defaults to the standard Edge installation; set `BROWSER_PATH` to another Chromium executable when needed. It mocks all chain requests and broadcasts no transactions. Tests cover pending deployment, RPC failure, read-only initialization and missing-wallet handling.

## Deployment and assessment

Update `frontend/product.json` only after confirming the new contract's network, bytecode and ABI. Do not substitute placeholder addresses or remove truthful limitations. Operator-wallet testing proves technical activity, not independent users. Official social accounts, launch posts, independent users and continuous operation require separate evidence.
