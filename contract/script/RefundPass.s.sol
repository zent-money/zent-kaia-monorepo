// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentEscrow } from "src/ZentEscrow.sol";

contract RefundPass is Script {
    function run(address payable escrowAddr, uint256 passId) external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);

        ZentEscrow(escrowAddr).refundPass(passId);

        vm.stopBroadcast();
        console2.log("Refunded pass:", passId, "on escrow:", escrowAddr);
    }
}
