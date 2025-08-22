// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { KRWS } from "src/KRWS.sol";

contract DeployKRWS is Script {
    function run() external {
        // 1) Read secrets
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // 2) Broadcast
        vm.startBroadcast(pk);
        KRWS krws = new KRWS();
        vm.stopBroadcast();

        // 3) Logs
        console2.log("=== KRWS Deployed ===");
        console2.log("KRWS address:", address(krws));
        console2.log("decimals:", krws.decimals());
    }
}
