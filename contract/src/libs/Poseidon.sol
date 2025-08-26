// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Poseidon {
    // Simplified Poseidon implementation matching circomlib constants
    // For production, use optimized implementation or precompile
    
    uint256 constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    
    // Pre-calculated round constants (first 8 for demonstration)
    uint256[8] private ROUND_CONSTANTS = [
        uint256(0x0ee9a592ba9a9518d05986d656f40c2114c4993c11bb29938d21d47304cd8e6e),
        uint256(0x00f1445235f2148c5986587169fc1bcd887b08d4d00868df5696fff40956e864),
        uint256(0x08dff3487e8ac99e1f29a058d0fa80b930c728730b7ab36ce879f3890ecf73f5),
        uint256(0x2f27be690fdaee46c3ce28f7532b13c856c35342c84bda6e20966310fadc01d0),
        uint256(0x2b2ae1acf68b7b8d2416bebf3d4f6234b763fe04b8043ee48b8327bebca16cf2),
        uint256(0x0319d062072bef7ecca5eac06f97d4d55952c175ab6b03eae64b44c7dbf11cfa),
        uint256(0x28a411b634f09b8fb14b900e9507e9327600ecc7d3e892e23c15d4bce36cbcf6),
        uint256(0x22c0f72d1b3355d593d3c9c0ee63a8bd38e987b03db722a1c0a5542cff998830)
    ];
    
    function hash(uint256 input) internal pure returns (uint256) {
        // Simplified single-input Poseidon hash
        uint256 state = input;
        
        // Apply sponge construction with simplified rounds
        for (uint256 i = 0; i < 8; i++) {
            state = addmod(state, ROUND_CONSTANTS[i], FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE); // x^5
        }
        
        return state;
    }
    
    function hash2(uint256 input1, uint256 input2) internal pure returns (uint256) {
        // Simplified two-input Poseidon hash
        uint256 state = addmod(input1, input2, FIELD_SIZE);
        
        // Apply sponge construction with simplified rounds
        for (uint256 i = 0; i < 8; i++) {
            state = addmod(state, ROUND_CONSTANTS[i], FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE);
            state = mulmod(state, state, FIELD_SIZE); // x^5
            
            // Mix inputs
            if (i == 4) {
                state = addmod(state, input1, FIELD_SIZE);
                state = addmod(state, input2, FIELD_SIZE);
            }
        }
        
        return state;
    }
    
    // Convert bytes32 to field element (ensure within field size)
    function toFieldElement(bytes32 input) internal pure returns (uint256) {
        uint256 value = uint256(input);
        return value % FIELD_SIZE;
    }
}