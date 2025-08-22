// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Test KRW Stablecoin (KRWS)
 * @notice Test-only token (6 decimals).
 *         Anyone can mint:
 *           - faucet():              100,000 KRWS to msg.sender
 *           - mint(uint256 amount):  arbitrary amount to msg.sender
 *           - mintTo(address,uint256): arbitrary amount to any address
 *
 * ⚠️ TEST ONLY — no access control.
 */
contract KRWS is ERC20 {
    uint8 public constant DECIMALS = 6;
    uint256 public constant FAUCET_AMOUNT = 100_000 * 10 ** DECIMALS;

    constructor() ERC20("Test KRW Stablecoin", "KRWS") { }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /// @notice Anyone can mint 100,000 KRWS to themselves.
    function faucet() external {
        _mint(msg.sender, FAUCET_AMOUNT);
    }

    /// @notice Anyone can mint arbitrary amount to themselves.
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    /// @notice Anyone can mint arbitrary amount to any address.
    function mintTo(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
