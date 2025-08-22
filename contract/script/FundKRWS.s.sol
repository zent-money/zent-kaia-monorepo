// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { KRWS } from "src/KRWS.sol";

contract FundKRWS is Script {
    function run(address token, address to, uint256 amountUnits) external {
        // amountUnits are token units (KRWS has 6 decimals)
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);
        KRWS(token).mintTo(to, amountUnits);
        vm.stopBroadcast();

        console2.log("Funded KRWS");
        console2.log("token:", token);
        console2.log("to:", to);
        console2.log("amount (units):", amountUnits);
    }
}
