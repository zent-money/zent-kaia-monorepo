// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/ZentEscrow.sol";
import "../src/ZentPayLink.sol";
import "../src/zk/Verifier.sol";

contract DeployZK is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT");
        uint256 feeBps = vm.envOr("FEE_BPS", uint256(50)); // Default 0.5%
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Verifier
        Verifier verifier = new Verifier();
        console.log("Verifier deployed at:", address(verifier));
        
        // Deploy ZentEscrow with ZK support
        ZentEscrow escrow = new ZentEscrow(address(verifier));
        console.log("ZentEscrow deployed at:", address(escrow));
        
        // Deploy ZentPayLink with ZK support
        ZentPayLink payLink = new ZentPayLink(address(verifier), feeRecipient, feeBps);
        console.log("ZentPayLink deployed at:", address(payLink));
        
        vm.stopBroadcast();
        
        // Log deployment info
        console.log("========================================");
        console.log("Deployment Summary:");
        console.log("========================================");
        console.log("Verifier:", address(verifier));
        console.log("ZentEscrow:", address(escrow));
        console.log("ZentPayLink:", address(payLink));
        console.log("Fee Recipient:", feeRecipient);
        console.log("Fee BPS:", feeBps);
        console.log("========================================");
        
        // Write deployment addresses to file for frontend integration
        string memory deploymentJson = string(abi.encodePacked(
            '{\n',
            '  "verifier": "', vm.toString(address(verifier)), '",\n',
            '  "escrow": "', vm.toString(address(escrow)), '",\n',
            '  "payLink": "', vm.toString(address(payLink)), '",\n',
            '  "feeRecipient": "', vm.toString(feeRecipient), '",\n',
            '  "feeBps": ', vm.toString(feeBps), ',\n',
            '  "chainId": ', vm.toString(block.chainid), '\n',
            '}'
        ));
        
        vm.writeFile("./deployments/latest.json", deploymentJson);
        console.log("Deployment addresses saved to deployments/latest.json");
    }
}