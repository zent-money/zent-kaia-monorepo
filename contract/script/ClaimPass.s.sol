// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentEscrow } from "src/ZentEscrow.sol";

contract ClaimPass is Script {
    /// @param escrowAddr ZentEscrow 주소
    /// @param passId 청구할 패스 ID
    /// @param secret 패스 생성 시 사용한 secret (bytes로 변환 가능한 hex 또는 짧은 문자열)
    /// @param receiver 수취자 주소 (msg.sender 사용시 0x000...0)
    function run(address payable escrowAddr, uint256 passId, bytes calldata secret, address receiver) external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);

        ZentEscrow(escrowAddr).claimPass(passId, secret, receiver);

        vm.stopBroadcast();
        console2.log("Claimed pass:", passId, "from escrow:", escrowAddr);
    }
}
