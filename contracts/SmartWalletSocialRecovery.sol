// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    bool private _nonReentrant;
    constructor() { _nonReentrant = false; }
    modifier nonReentrant() {
        require(!_nonReentrant, "ReentrancyGuard: reentrant call");
        _nonReentrant = true;
        _;
        _nonReentrant = false;
    }
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function owner() public view returns (address) { return _owner; }
}

contract SmartWalletSocialRecovery is ReentrancyGuard, Ownable {
    // FIX: chain guard bookkeeping is keyed per wallet record ("wallet key"), not per
    // current owner.
    struct Guardian {
        address guardian;
        uint256 weight;
        bool active;
    }
    struct Wallet {
        address owner;
        uint256 threshold;
        uint256 recoveryNonce;
        address pendingNewOwner; // FIX: chosen new owner stored at initiation, gated on guardian weight at completion
        bool locked;
        uint256 guardianCount;
    }
    mapping(address => Wallet) public wallets;
    mapping(address => mapping(address => Guardian)) public guardians;
    mapping(address => address[]) public userGuardians;
    // FIX: guardian approvals for the current recovery request, keyed by
    // walletKey -> recoveryNonce -> guardian. Nonce keying means a fresh request
    // always starts from zero approvals.
    mapping(address => mapping(uint256 => mapping(address => bool))) public guardianApprovals;
    mapping(address => mapping(uint256 => uint256)) public approvalWeight;
    uint256 public walletCount;
    // FIX: sane upper bound on guardian count.
    uint256 public constant MAX_GUARDIANS = 8;

    event WalletCreated(address indexed owner, uint256 threshold);
    event GuardianAdded(address indexed wallet, address indexed guardian, uint256 weight);
    event RecoveryInitiated(address indexed wallet, address indexed recoveryTarget);
    event RecoveryApproved(address indexed wallet, address indexed guardian, uint256 approvalWeight, uint256 threshold);
    event RecoveryCompleted(address indexed wallet, address indexed newOwner);

    function createWallet(uint256 threshold) external nonReentrant {
        require(threshold > 0, "Zero threshold");
        // FIX: was `require(!wallets[msg.sender].locked == false && ...)` — for a fresh
        // mapping entry `locked` is false so `!locked == false` evaluates to false and
        // createWallet always reverted. A wallet exists iff its owner is set.
        require(wallets[msg.sender].owner == address(0), "Wallet exists");
        Wallet storage w = wallets[msg.sender];
        w.owner = msg.sender;
        w.threshold = threshold;
        w.recoveryNonce = 0;
        w.locked = false;
        w.guardianCount = 0;
        walletCount += 1;
        emit WalletCreated(msg.sender, threshold);
    }

    // FIX: guardian management is keyed by the wallet record (walletKey) and gated on
    // CURRENT ownership, not on msg.sender being the mapping key — otherwise after a
    // recovery the new owner could not manage guardians. Anchor = contract owner is
    // not involved here; wallet owners control their own wallets.
    function addGuardian(address walletKey, address guardian, uint256 weight) external nonReentrant {
        require(guardian != address(0), "Zero address");
        require(weight > 0, "Zero weight");
        Wallet storage w = wallets[walletKey];
        require(w.owner != address(0), "No wallet");
        require(w.owner == msg.sender, "Not owner");
        require(!w.locked, "Wallet locked");
        // FIX: deduplicate — the same guardian could previously be pushed repeatedly.
        require(!guardians[walletKey][guardian].active, "Already guardian");
        require(w.guardianCount < MAX_GUARDIANS, "Too many guardians");
        guardians[walletKey][guardian] = Guardian({guardian: guardian, weight: weight, active: true});
        userGuardians[walletKey].push(guardian);
        w.guardianCount += 1;
        emit GuardianAdded(walletKey, guardian, weight);
    }

    // FIX: was caller-operates-on-self — any address could lock ANY wallet and even
    // pick the new owner, letting anyone seize any wallet. Recovery is now
    // guardian-driven: only an active guardian of `walletKey`'s wallet can start a
    // recovery, and the chosen newOwner is stored as pending; completion is gated on
    // guardian weight meeting the threshold (see completeRecovery).
    function initiateRecovery(address walletKey, address newOwner) external nonReentrant {
        require(newOwner != address(0), "Zero owner");
        Wallet storage w = wallets[walletKey];
        require(w.owner != address(0), "No wallet");
        require(w.owner != newOwner, "Same owner");
        require(!w.locked, "Recovery pending");
        require(guardians[walletKey][msg.sender].active, "Not guardian");
        w.pendingNewOwner = newOwner;
        w.recoveryNonce += 1;
        w.locked = true;
        emit RecoveryInitiated(walletKey, newOwner);
    }

    // FIX: guardian-driven completion. Each active guardian calls this to approve the
    // pending newOwner for the current nonce; once accumulated weight >= threshold the
    // rotation executes: owner moves to the pending newOwner, lock clears, pending
    // resets. Weight/owner checks replace the old unrestricted direct takeover.
    function completeRecovery(address walletKey, address newOwner) external nonReentrant {
        Wallet storage w = wallets[walletKey];
        require(w.owner != address(0), "No wallet");
        require(w.locked, "No recovery pending");
        require(newOwner == w.pendingNewOwner, "Owner mismatch");
        require(guardians[walletKey][msg.sender].active, "Not guardian");
        require(!guardianApprovals[walletKey][w.recoveryNonce][msg.sender], "Already approved");
        guardianApprovals[walletKey][w.recoveryNonce][msg.sender] = true;
        uint256 weight = approvalWeight[walletKey][w.recoveryNonce] + guardians[walletKey][msg.sender].weight;
        approvalWeight[walletKey][w.recoveryNonce] = weight;
        if (weight < w.threshold) {
            emit RecoveryApproved(walletKey, msg.sender, weight, w.threshold);
            return;
        }
        w.owner = newOwner;
        w.locked = false;
        w.pendingNewOwner = address(0);
        emit RecoveryCompleted(walletKey, newOwner);
    }

    // FIX: exposes pendingNewOwner so integrators can verify what recovery is pending.
    function getWallet(address user) external view returns (address ownerAddress, uint256 threshold, uint256 recoveryNonce, bool locked, uint256 guardianCount, address pendingNewOwner) {
        Wallet storage w = wallets[user];
        return (w.owner, w.threshold, w.recoveryNonce, w.locked, w.guardianCount, w.pendingNewOwner);
    }
}
