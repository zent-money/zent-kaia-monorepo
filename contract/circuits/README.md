# ZK Circuits for Share-Code Transfers

This directory contains the Circom circuits implementing zero-knowledge proofs for code-based claiming without revealing the secret code on-chain.

## Architecture

The system uses a commitment-nullifier pattern similar to privacy protocols:
- **Commitment**: `C = Poseidon(secret, nullifier)` - stored on-chain when depositing
- **Nullifier Hash**: `N = Poseidon(nullifier)` - revealed during claim to prevent double-spending
- **Secret**: Off-chain share code given to recipient

## Circuit Details

### `code_claim.circom`

**Inputs:**
- Private: `s` (secret), `n` (nullifier)
- Public: `C` (commitment), `N` (nullifierHash)

**Constraints:**
- `C == Poseidon(s, n)` - Proves knowledge of secret and nullifier
- `N == Poseidon(n)` - Proves correct nullifier hash

## Building Circuits

### Prerequisites

```bash
npm install
```

### Build Process

```bash
./build.sh
```

This will:
1. Download Powers of Tau file (if not present)
2. Compile the circuit to R1CS and WASM
3. Generate proving/verification keys (trusted setup)
4. Export Solidity verifier contract
5. Copy verifier to contracts directory

### Generated Artifacts

- `artifacts/code_claim.r1cs` - Circuit constraint system
- `artifacts/code_claim_js/` - WASM witness generator
- `artifacts/code_claim.zkey` - Proving key
- `artifacts/code_claim_vk.json` - Verification key
- `artifacts/Verifier.sol` - Solidity verifier contract

## Generating Proofs (Off-chain)

### JavaScript/TypeScript

```javascript
const snarkjs = require("snarkjs");
const circomlibjs = require("circomlibjs");

async function generateProof(secret, nullifier) {
    // Calculate commitment and nullifier hash
    const poseidon = await circomlibjs.buildPoseidon();
    const commitment = poseidon.F.toObject(poseidon([secret, nullifier]));
    const nullifierHash = poseidon.F.toObject(poseidon([nullifier]));
    
    // Generate witness
    const input = {
        s: secret,
        n: nullifier,
        C: commitment,
        N: nullifierHash
    };
    
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        input,
        "artifacts/code_claim_js/code_claim.wasm",
        "artifacts/code_claim.zkey"
    );
    
    // Format proof for Solidity
    const solidityProof = {
        a: [proof.pi_a[0], proof.pi_a[1]],
        b: [[proof.pi_b[0][1], proof.pi_b[0][0]], [proof.pi_b[1][1], proof.pi_b[1][0]]],
        c: [proof.pi_c[0], proof.pi_c[1]]
    };
    
    return { proof: solidityProof, commitment, nullifierHash };
}
```

## Security Considerations

⚠️ **IMPORTANT**: This implementation provides "addressless UX" not full privacy:
- Amounts and assets are visible on-chain
- Transaction graph is visible
- Only the link between depositor and claimer is obscured

**Production Requirements:**
1. Proper trusted setup ceremony (current uses fixed entropy)
2. Circuit audit by security professionals
3. Optimized Poseidon implementation or precompile
4. Rate limiting and monitoring

## Testing

Run circuit tests:
```bash
npm test
```

Verify proof locally:
```bash
snarkjs groth16 verify artifacts/code_claim_vk.json public.json proof.json
```

## Gas Costs

Approximate gas usage:
- Proof verification: ~150,000 gas
- Total claim transaction: ~180,000 gas

## Troubleshooting

**Circuit compilation fails:**
- Ensure circom 2.x is installed
- Check circomlib is properly installed

**Proof verification fails on-chain:**
- Ensure verifier contract matches circuit
- Check public inputs order matches circuit outputs
- Verify field elements are within BN254 range

**Powers of Tau download fails:**
- Manually download from Hermez ceremony
- Place in `artifacts/` directory