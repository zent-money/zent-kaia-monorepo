// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentPayLink } from "src/ZentPayLink.sol";
import { KRWS } from "src/KRWS.sol";

contract CreateSampleInvoice is Script {
    function run(address payable paylinkAddr, address krwsAddr) external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);

        // Mint some KRWS to deployer (so they can pay invoice later)
        KRWS(krwsAddr).faucet();

        // Create invoice for 10,000 KRWS, 1 day expiry
        uint64 expiry = uint64(block.timestamp + 1 days);
        uint256 amt = 10_000 * 1e6; // 6 decimals
        ZentPayLink(paylinkAddr).createInvoice(krwsAddr, amt, expiry, "ipfs://demo-metadata");

        vm.stopBroadcast();
        console2.log("Created sample invoice for 10,000 KRWS on paylink:", paylinkAddr);
    }
}
