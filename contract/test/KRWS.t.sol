// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { KRWS } from "src/KRWS.sol";

contract KRWSTest is Test {
    KRWS token;
    address alice = address(0xA11CE);

    function setUp() public {
        token = new KRWS();
    }

    function test_Decimals() public {
        assertEq(token.decimals(), 6);
    }

    function test_Faucet() public {
        vm.prank(alice);
        token.faucet();
        assertEq(token.balanceOf(alice), 100_000 * 1e6);
    }

    function test_Mint() public {
        vm.prank(alice);
        token.mint(123 * 1e6);
        assertEq(token.balanceOf(alice), 123 * 1e6);
    }

    function test_MintTo() public {
        token.mintTo(alice, 777 * 1e6);
        assertEq(token.balanceOf(alice), 777 * 1e6);
    }
}
