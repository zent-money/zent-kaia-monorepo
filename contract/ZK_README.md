# Zent ZK-Verified Share-Code Transfers

Zero-knowledge proof implementation for addressless escrow and invoice settlement on KAIA blockchain.

## Overview

This system replaces plaintext secret verification with ZK proof verification, enabling:
- **Addressless UX**: Share codes without revealing recipient address
- **Double-spend prevention**: Nullifier-based claim tracking
- **Backward compatibility**: Legacy functions remain functional
- **Gas efficient**: ~150k gas for proof verification

## Architecture

### Core Components

1. **ZK Circuits** (Circom + SnarkJS)
   - Poseidon hash-based commitment scheme
   - Groth16 proof system
   - Deterministic trusted setup

2. **Smart Contracts** (Solidity + Foundry)
   - `ZentEscrow.sol`: ZK-verified escrow with share codes
   - `ZentPayLink.sol`: ZK-verified invoice settlement
   - `Verifier.sol`: Groth16 proof verification

3. **Commitment Model**
   - Commitment: `C = Poseidon(secret, nullifier)`
   - NullifierHash: `N = Poseidon(nullifier)`
   - Share code: Base58/Hex encoding of secret

## Quick Start

### Prerequisites

```bash
# Install dependencies
npm install
forge install
```

### Build Circuits

```bash
npm run build:circuits
# or
cd circuits && ./build.sh
```

### Run Tests

```bash
forge test -vvv
```

### Deploy Contracts

```bash
# Set environment variables
export PRIVATE_KEY=<your-private-key>
export RPC_URL=<kaia-rpc-url>
export FEE_RECIPIENT=<fee-recipient-address>

# Deploy
forge script script/DeployZK.s.sol --rpc-url $RPC_URL --broadcast
```

## Usage Flow

### Escrow (Share-Code Transfers)

1. **Sender creates deposit:**
   ```solidity
   // Generate off-chain: secret, nullifier
   bytes32 commitment = Poseidon(secret, nullifier);
   escrow.deposit{value: 1 ether}(address(0), 1 ether, commitment, expiry);
   ```

2. **Share code off-chain:**
   ```
   Share code: base58(secret)
   Give to recipient privately
   ```

3. **Recipient claims:**
   ```javascript
   // Generate proof off-chain
   const proof = await generateProof(secret, nullifier);
   
   // Claim on-chain
   escrow.claim(commitment, nullifierHash, recipient, proof.a, proof.b, proof.c);
   ```

### Invoice (ZK Settlement)

1. **Merchant issues invoice:**
   ```solidity
   bytes32 commitment = Poseidon(secret, nullifier);
   payLink.issueInvoice(asset, amount, commitment, dueAt, metadata);
   ```

2. **Payer settles with proof:**
   ```solidity
   payLink.settleWithProof{value: amount}(
       commitment, nullifierHash, payer, proof.a, proof.b, proof.c
   );
   ```

## Contract Interfaces

### ZentEscrow

```solidity
// ZK functions
function deposit(address asset, uint256 amount, bytes32 commitment, uint64 expiry) payable
function claim(bytes32 commitment, bytes32 nullifierHash, address recipient, uint256[2] a, uint256[2][2] b, uint256[2] c)
function cancelExpired(bytes32 commitment)

// Legacy functions (backward compatible)
function createPass(address token, uint256 amount, bytes32 hashSecret, uint64 expiry) payable returns (uint256)
function claimPass(uint256 id, bytes secret, address receiver)
function refundPass(uint256 id)
```

### ZentPayLink

```solidity
// ZK functions
function issueInvoice(address asset, uint256 amount, bytes32 commitment, uint64 dueAt, string metadata)
function settleWithProof(bytes32 commitment, bytes32 nullifierHash, address payer, uint256[2] a, uint256[2][2] b, uint256[2] c) payable
function closeZKInvoice(bytes32 commitment)

// Legacy functions (backward compatible)
function createInvoice(address token, uint256 amount, uint64 expiry, string metadata) returns (uint256)
function pay(uint256 id, uint256 amount, address payer) payable
function close(uint256 id)
```

## Gas Costs

| Operation | Gas Usage |
|-----------|-----------|
| ZK Claim/Settle | ~180,000 |
| Proof Verification | ~150,000 |
| Deposit | ~80,000 |
| Legacy Claim | ~60,000 |

## Security Considerations

⚠️ **Important Notes:**
- This provides addressless UX, NOT full privacy
- Amounts and assets remain visible on-chain
- Production requires proper trusted setup ceremony
- Circuit should be audited before mainnet deployment

## Development

### Project Structure

```
contract/
├── circuits/           # Circom circuits
│   ├── code_claim.circom
│   ├── build.sh
│   └── artifacts/      # Generated keys and verifier
├── src/               # Solidity contracts
│   ├── ZentEscrow.sol
│   ├── ZentPayLink.sol
│   └── zk/
│       ├── IZKVerifier.sol
│       └── Verifier.sol
├── test/              # Foundry tests
│   ├── ZK_Escrow.t.sol
│   └── ZK_Invoice.t.sol
└── script/            # Deployment scripts
    └── DeployZK.s.sol
```

### Testing with Vectors

Test vectors are included in `circuits/artifacts/vectors/` for deterministic testing.

### Generating Proofs (JavaScript)

```javascript
const snarkjs = require("snarkjs");
const circomlibjs = require("circomlibjs");

async function generateProof(secret, nullifier) {
    const poseidon = await circomlibjs.buildPoseidon();
    const commitment = poseidon.F.toObject(poseidon([secret, nullifier]));
    const nullifierHash = poseidon.F.toObject(poseidon([nullifier]));
    
    const input = {
        s: secret,
        n: nullifier,
        C: commitment,
        N: nullifierHash
    };
    
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        input,
        "circuits/artifacts/code_claim_js/code_claim.wasm",
        "circuits/artifacts/code_claim.zkey"
    );
    
    return {
        proof: {
            a: [proof.pi_a[0], proof.pi_a[1]],
            b: [[proof.pi_b[0][1], proof.pi_b[0][0]], [proof.pi_b[1][1], proof.pi_b[1][0]]],
            c: [proof.pi_c[0], proof.pi_c[1]]
        },
        commitment,
        nullifierHash
    };
}
```

## License

MIT

## Audit Status

⚠️ **UNAUDITED** - This code has not been audited and should not be used in production without proper security review.