// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentPayLink } from "src/ZentPayLink.sol";

contract CreateSampleInvoice is Script {
    function run(address payable paylinkAddr) external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address krws = _tryEnvAddr("KRWS_ADDRESS"); // optional

        vm.startBroadcast(pk);

        uint64 expiry = uint64(block.timestamp + 2 days);
        address token = krws != address(0) ? krws : address(0); // KRWS if available, else native
        // NOTE: amount 단위는 토큰 decimals에 맞게 세팅 필요 (KRWS=6)
        ZentPayLink(paylinkAddr).createInvoice(
            token, 2_000_000, /* 2,000,000 KRWS units = 2,000 KRWS if 6d */ expiry, "ipfs://demo"
        );

        vm.stopBroadcast();
    }

    function _tryEnvAddr(string memory key) internal returns (address) {
        try vm.envAddress(key) returns (address a) {
            return a;
        } catch {
            return address(0);
        }
    }
}
