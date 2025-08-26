#!/usr/bin/env bash
set -euo pipefail

CIRCUIT=code_claim
ARTIFACTS_DIR="./artifacts"

echo "Building circuit: $CIRCUIT"

# Create artifacts directory if it doesn't exist
mkdir -p "$ARTIFACTS_DIR"

# Check if we have the powers of tau file, if not download it
PTAU_FILE="$ARTIFACTS_DIR/powersOfTau28_hez_final_12.ptau"
if [ ! -f "$PTAU_FILE" ]; then
    echo "Downloading Powers of Tau file..."
    curl -L "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_12.ptau" -o "$PTAU_FILE"
fi

# Compile circuit
echo "Compiling circuit..."
circom "$CIRCUIT.circom" --r1cs --wasm --sym -o "$ARTIFACTS_DIR"

# Generate zkey (trusted setup)
echo "Generating zkey..."
snarkjs groth16 setup "$ARTIFACTS_DIR/$CIRCUIT.r1cs" "$PTAU_FILE" "$ARTIFACTS_DIR/${CIRCUIT}_0000.zkey"

# Contribute to the ceremony (fixed entropy for deterministic build)
echo "Contributing to ceremony..."
snarkjs zkey contribute "$ARTIFACTS_DIR/${CIRCUIT}_0000.zkey" "$ARTIFACTS_DIR/$CIRCUIT.zkey" \
    --name="krws-zk" -e="krws-zk-deterministic-entropy"

# Export verification key
echo "Exporting verification key..."
snarkjs zkey export verificationkey "$ARTIFACTS_DIR/$CIRCUIT.zkey" "$ARTIFACTS_DIR/${CIRCUIT}_vk.json"

# Export Solidity verifier
echo "Exporting Solidity verifier..."
snarkjs zkey export solidityverifier "$ARTIFACTS_DIR/$CIRCUIT.zkey" "$ARTIFACTS_DIR/Verifier.sol"

# Copy verifier to contracts directory
echo "Copying verifier to contracts..."
mkdir -p ../src/zk
cp "$ARTIFACTS_DIR/Verifier.sol" ../src/zk/Verifier.sol

echo "Circuit build complete!"