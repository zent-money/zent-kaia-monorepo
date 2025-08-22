// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentPayLink } from "src/ZentPayLink.sol";

contract CreateSampleInvoice is Script {
    function run(address payable paylinkAddr) external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);

        uint64 expiry = uint64(block.timestamp + 2 days);
        ZentPayLink(paylinkAddr).createInvoice(address(0), 2e15, expiry, "ipfs://demo");

        vm.stopBroadcast();
    }
}
