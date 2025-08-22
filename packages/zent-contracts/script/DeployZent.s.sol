// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentEscrow } from "src/ZentEscrow.sol";
import { ZentPayLink } from "src/ZentPayLink.sol";

contract DeployZent is Script {
    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address feeRecipient = vm.addr(pk);
        uint256 feeBps = 50; // 0.5% default; adjust as needed

        vm.startBroadcast(pk);
        ZentEscrow escrow = new ZentEscrow();
        ZentPayLink paylink = new ZentPayLink(feeRecipient, feeBps);
        vm.stopBroadcast();

        console2.log("ZentEscrow:", address(escrow));
        console2.log("ZentPayLink:", address(paylink));
    }
}
