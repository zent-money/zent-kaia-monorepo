// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { ZentEscrow } from "src/ZentEscrow.sol";
import { KRWS } from "src/KRWS.sol";

contract ZentEscrow_CreatorRefund_Test is Test {
    ZentEscrow esc;
    KRWS token;

    address alice = address(0xA11CE); // creator
    address bob = address(0xB0B); // non-creator

    function setUp() public {
        esc = new ZentEscrow();
        token = new KRWS();

        // fund alice and approve escrow
        token.mintTo(alice, 1_000_000 * 1e6);
        vm.prank(alice);
        token.approve(address(esc), type(uint256).max);
    }

    function test_OnlyCreatorCanRefund() public {
        // alice creates a pass
        vm.startPrank(alice);
        bytes32 h = keccak256(bytes("s"));
        uint64 expiry = uint64(block.timestamp + 1 hours);
        uint256 amount = 10_000 * 1e6;
        uint256 id = esc.createPass(address(token), amount, h, expiry);
        vm.stopPrank();

        // time passes past expiry
        vm.warp(block.timestamp + 2 hours);

        // bob (non-creator) tries to refund -> revert NotSender()
        vm.expectRevert(ZentEscrow.NotSender.selector);
        vm.prank(bob);
        esc.refundPass(id);

        // creator (alice) can refund
        uint256 beforeBal = token.balanceOf(alice);
        vm.prank(alice);
        esc.refundPass(id);
        assertEq(token.balanceOf(alice), beforeBal + amount);
    }
}
