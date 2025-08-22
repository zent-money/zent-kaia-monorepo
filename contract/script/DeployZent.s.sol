// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentEscrow } from "src/ZentEscrow.sol";
import { ZentPayLink } from "src/ZentPayLink.sol";
import { KRWS } from "src/KRWS.sol";

contract DeployZent is Script {
    function run() external {
        // required
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 feeBps = _tryEnvOrDefault("ZENT_FEE_BPS", 50);

        // optional
        address existingKrws = _tryEnvAddr("KRWS_ADDRESS");

        vm.startBroadcast(pk);

        // 1) KRWS — use existing if provided, else deploy new
        address krwsAddr;
        if (existingKrws != address(0)) {
            krwsAddr = existingKrws;
        } else {
            KRWS krws = new KRWS();
            krwsAddr = address(krws);
        }

        // 2) Zent core contracts
        address feeRecipient = vm.addr(pk);
        ZentEscrow escrow = new ZentEscrow();
        ZentPayLink paylink = new ZentPayLink(feeRecipient, feeBps);

        vm.stopBroadcast();

        // Logs
        console2.log("=== Zent Deploy Results ===");
        console2.log("KRWS:", krwsAddr);
        console2.log("ZentEscrow:", address(escrow));
        console2.log("ZentPayLink:", address(paylink));
        console2.log("FeeRecipient:", feeRecipient);
        console2.log("FeeBps:", feeBps);
    }

    function _tryEnvOrDefault(string memory key, uint256 defVal) internal returns (uint256) {
        try vm.envUint(key) returns (uint256 v) {
            return v;
        } catch {
            return defVal;
        }
    }

    function _tryEnvAddr(string memory key) internal returns (address) {
        try vm.envAddress(key) returns (address a) {
            return a;
        } catch {
            return address(0);
        }
    }
}
