// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { ZentEscrow } from "src/ZentEscrow.sol";

contract ZentEscrowTest is Test {
    ZentEscrow esc;
    address alice;
    address bob;

    function setUp() public {
        esc = new ZentEscrow();
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        vm.deal(alice, 10 ether);
    }

    function test_CreateClaimRefund_Native() public {
        vm.startPrank(alice);
        bytes memory secret = bytes("s");
        bytes32 hashSecret = keccak256(secret);
        uint64 expiry = uint64(block.timestamp + 1 days);

        uint256 id = esc.createPass{ value: 1 ether }(address(0), 1 ether, hashSecret, expiry);
        vm.stopPrank();

        // claim by bob
        vm.prank(bob);
        uint256 balBefore = bob.balance;
        esc.claimPass(id, secret, bob);
        assertGt(bob.balance, balBefore);
    }
}
