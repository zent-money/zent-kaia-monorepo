pragma circom 2.0.0;

include "circomlib/circuits/poseidon.circom";

template CodeClaim() {
    signal input s;      // secret (private)
    signal input n;      // nullifier (private)
    signal output C;     // commitment (public)
    signal output N;     // nullifierHash (public)
    
    // Compute commitment C = Poseidon(s, n)
    component hasher1 = Poseidon(2);
    hasher1.inputs[0] <== s;
    hasher1.inputs[1] <== n;
    C <== hasher1.out;
    
    // Compute nullifier hash N = Poseidon(n)
    component hasher2 = Poseidon(1);
    hasher2.inputs[0] <== n;
    N <== hasher2.out;
}

component main = CodeClaim();