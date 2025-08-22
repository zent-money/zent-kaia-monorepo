// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentEscrow } from "src/ZentEscrow.sol";

contract CreateSamplePass is Script {
    function run(address payable escrowAddr) external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);

        bytes32 hashSecret = keccak256(bytes("demo-secret"));
        uint64 expiry = uint64(block.timestamp + 2 days);
        ZentEscrow(escrowAddr).createPass{ value: 1e15 }(address(0), 1e15, hashSecret, expiry);

        vm.stopBroadcast();
    }
}
