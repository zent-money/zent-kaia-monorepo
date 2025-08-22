// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IZentEscrow {
    struct Pass {
        address sender;
        address token; // address(0) = native KAIA
        uint256 amount;
        bytes32 hashSecret; // keccak256(secret)
        uint64 expiry; // unix seconds
        address claimedBy;
        bool refunded;
    }

    event PassCreated(uint256 indexed id, address indexed sender, address token, uint256 amount, uint64 expiry);
    event PassClaimed(uint256 indexed id, address indexed receiver);
    event PassRefunded(uint256 indexed id);

    function createPass(address token, uint256 amount, bytes32 hashSecret, uint64 expiry)
        external
        payable
        returns (uint256 id);
    function claimPass(uint256 id, bytes calldata secret, address receiver) external;
    function refundPass(uint256 id) external;
    function getPass(uint256 id) external view returns (Pass memory);
}
