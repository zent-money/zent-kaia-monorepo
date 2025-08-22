// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentEscrow } from "src/ZentEscrow.sol";
import { KRWS } from "src/KRWS.sol";

contract CreateSamplePass is Script {
    function run(address payable escrowAddr, address krwsAddr) external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);

        // Mint KRWS to deployer so they can lock funds
        KRWS(krwsAddr).mint(50_000 * 1e6);

        // Approve escrow to pull tokens
        KRWS(krwsAddr).approve(escrowAddr, type(uint256).max);

        // Secret & hash
        bytes memory secret = bytes("sample-secret");
        bytes32 hashSecret = keccak256(secret);

        // Create pass: 5,000 KRWS locked, valid 1 day
        uint64 expiry = uint64(block.timestamp + 1 days);
        uint256 amt = 5_000 * 1e6;
        ZentEscrow(escrowAddr).createPass(krwsAddr, amt, hashSecret, expiry);

        vm.stopBroadcast();

        console2.log("Created sample pass (5,000 KRWS). hash:");
        console2.logBytes32(hashSecret);
    }
}
