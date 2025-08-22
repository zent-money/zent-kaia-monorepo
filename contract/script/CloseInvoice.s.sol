// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentPayLink } from "src/ZentPayLink.sol";

contract CloseInvoice is Script {
    function run(address payable paylinkAddr, uint256 invoiceId) external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);

        ZentPayLink(paylinkAddr).close(invoiceId);

        vm.stopBroadcast();
        console2.log("Closed invoice:", invoiceId, "on paylink:", paylinkAddr);
    }
}
