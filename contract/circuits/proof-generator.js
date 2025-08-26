#!/usr/bin/env node
const snarkjs = require("snarkjs");
const circomlibjs = require("circomlibjs");
const fs = require("fs");
const path = require("path");

/**
 * Generate a ZK proof for code claiming
 * @param {string|bigint} secret - The secret code
 * @param {string|bigint} nullifier - The nullifier
 * @returns {Object} Proof data formatted for Solidity
 */
async function generateProof(secret, nullifier) {
    // Convert to BigInt if needed
    const s = typeof secret === 'string' ? BigInt(secret) : secret;
    const n = typeof nullifier === 'string' ? BigInt(nullifier) : nullifier;
    
    // Build Poseidon hash function
    const poseidon = await circomlibjs.buildPoseidon();
    const F = poseidon.F;
    
    // Calculate commitment and nullifier hash
    const commitment = F.toObject(poseidon([s, n]));
    const nullifierHash = F.toObject(poseidon([n]));
    
    // Prepare input for circuit
    const input = {
        s: s.toString(),
        n: n.toString(),
        C: commitment.toString(),
        N: nullifierHash.toString()
    };
    
    console.log("Generating proof with inputs:");
    console.log("  Secret:", s.toString());
    console.log("  Nullifier:", n.toString());
    console.log("  Commitment:", commitment.toString());
    console.log("  NullifierHash:", nullifierHash.toString());
    
    // Generate proof
    const wasmPath = path.join(__dirname, "artifacts/code_claim_js/code_claim.wasm");
    const zkeyPath = path.join(__dirname, "artifacts/code_claim.zkey");
    
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        input,
        wasmPath,
        zkeyPath
    );
    
    // Verify the proof locally
    const vkeyPath = path.join(__dirname, "artifacts/code_claim_vk.json");
    const vKey = JSON.parse(fs.readFileSync(vkeyPath));
    
    const res = await snarkjs.groth16.verify(vKey, publicSignals, proof);
    if (!res) {
        throw new Error("Proof verification failed!");
    }
    
    console.log("Proof verified successfully!");
    
    // Format proof for Solidity
    const solidityProof = {
        a: [proof.pi_a[0], proof.pi_a[1]],
        b: [[proof.pi_b[0][1], proof.pi_b[0][0]], [proof.pi_b[1][1], proof.pi_b[1][0]]],
        c: [proof.pi_c[0], proof.pi_c[1]]
    };
    
    return {
        proof: solidityProof,
        commitment: "0x" + BigInt(commitment).toString(16).padStart(64, '0'),
        nullifierHash: "0x" + BigInt(nullifierHash).toString(16).padStart(64, '0'),
        publicSignals
    };
}

/**
 * Generate test vectors for unit tests
 */
async function generateTestVectors() {
    const vectors = [];
    
    // Test vector 1: Simple values
    vectors.push(await generateProof(BigInt(123456), BigInt(789012)));
    
    // Test vector 2: Large values
    vectors.push(await generateProof(
        BigInt("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"),
        BigInt("0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321")
    ));
    
    // Save to file
    const outputPath = path.join(__dirname, "artifacts/vectors/test_vectors.json");
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, JSON.stringify(vectors, null, 2));
    
    console.log(`Test vectors saved to ${outputPath}`);
    return vectors;
}

/**
 * CLI interface
 */
async function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0 || args[0] === '--help') {
        console.log("Usage:");
        console.log("  node proof-generator.js <secret> <nullifier>");
        console.log("  node proof-generator.js --test-vectors");
        console.log("");
        console.log("Example:");
        console.log("  node proof-generator.js 123456 789012");
        console.log("  node proof-generator.js 0x1234...abcd 0xfedc...4321");
        return;
    }
    
    if (args[0] === '--test-vectors') {
        await generateTestVectors();
        return;
    }
    
    if (args.length !== 2) {
        console.error("Error: Expected 2 arguments (secret and nullifier)");
        process.exit(1);
    }
    
    const secret = args[0].startsWith('0x') ? args[0] : BigInt(args[0]);
    const nullifier = args[1].startsWith('0x') ? args[1] : BigInt(args[1]);
    
    const result = await generateProof(secret, nullifier);
    
    console.log("\n=== PROOF DATA ===");
    console.log("Commitment:", result.commitment);
    console.log("NullifierHash:", result.nullifierHash);
    console.log("\nProof components:");
    console.log("a:", result.proof.a);
    console.log("b:", result.proof.b);
    console.log("c:", result.proof.c);
    
    // Save to file for easy use
    const outputFile = `proof_${Date.now()}.json`;
    fs.writeFileSync(outputFile, JSON.stringify(result, null, 2));
    console.log(`\nProof saved to ${outputFile}`);
}

// Export for use as module
module.exports = {
    generateProof,
    generateTestVectors
};

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}