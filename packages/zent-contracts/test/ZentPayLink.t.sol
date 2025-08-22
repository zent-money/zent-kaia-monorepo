// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { ZentPayLink } from "src/ZentPayLink.sol";
import { IZentPayLink } from "src/interfaces/IZentPayLink.sol";

contract ZentPayLinkTest is Test {
    ZentPayLink pay;
    address merchant;
    address payer;

    function setUp() public {
        address feeRecipient = makeAddr("fee");
        pay = new ZentPayLink(feeRecipient, 50); // feeRecipient=EOA, 0.5%
        merchant = makeAddr("merchant");
        payer = makeAddr("payer");
        vm.deal(payer, 10 ether);
    }

    function test_CreateAndPay_Fixed_Native() public {
        vm.prank(merchant);
        uint64 expiry = uint64(block.timestamp + 1 days);
        uint256 id = pay.createInvoice(address(0), 1 ether, expiry, "demo");

        vm.startPrank(payer);
        pay.pay{ value: 1 ether }(id, 0, payer);
        vm.stopPrank();

        IZentPayLink.Invoice memory inv = pay.getInvoice(id);
        assertEq(inv.paid, 1 ether);
    }
}
