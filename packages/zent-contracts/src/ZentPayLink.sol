// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IZentPayLink } from "./interfaces/IZentPayLink.sol";

contract ZentPayLink is IZentPayLink, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public feeRecipient;
    uint256 public feeBps; // protocol fee in basis points (e.g., 50 = 0.5%)
    uint256 public constant BPS_DENOM = 10_000;

    uint256 public nextId;
    mapping(uint256 => Invoice) private invoices;

    constructor(address _feeRecipient, uint256 _feeBps) {
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
    }

    function createInvoice(address token, uint256 amount, uint64 expiry, string calldata metadataURI)
        external
        returns (uint256 id)
    {
        require(expiry > block.timestamp, "expiry");
        id = ++nextId;
        invoices[id] = Invoice({
            merchant: msg.sender,
            token: token,
            amount: amount,
            expiry: expiry,
            metadataURI: metadataURI,
            paid: 0,
            closed: false
        });
        emit InvoiceCreated(id, msg.sender);
    }

    function pay(uint256 id, uint256 amount, address payer) external payable nonReentrant {
        Invoice storage inv = invoices[id];
        require(inv.merchant != address(0), "not found");
        require(!inv.closed, "closed");
        require(block.timestamp <= inv.expiry, "expired");

        uint256 amt = inv.amount == 0 ? amount : inv.amount;
        require(amt > 0, "amt=0");

        // collect funds
        if (inv.token == address(0)) {
            require(msg.value == amt, "native mismatch");
        } else {
            require(msg.value == 0, "no msg.value");
            IERC20(inv.token).safeTransferFrom(payer == address(0) ? msg.sender : payer, address(this), amt);
        }

        // fee calc
        uint256 fee = (amt * feeBps) / BPS_DENOM;
        uint256 toMerchant = amt - fee;

        // payout
        if (inv.token == address(0)) {
            if (fee > 0) {
                (bool ok1,) = payable(feeRecipient).call{ value: fee }("");
                require(ok1, "fee fail");
            }
            (bool ok2,) = payable(inv.merchant).call{ value: toMerchant }("");
            require(ok2, "pay fail");
        } else {
            if (fee > 0) IERC20(inv.token).safeTransfer(feeRecipient, fee);
            IERC20(inv.token).safeTransfer(inv.merchant, toMerchant);
        }

        inv.paid += amt;
        emit InvoicePaid(id, payer == address(0) ? msg.sender : payer, amt, fee);
    }

    function close(uint256 id) external {
        Invoice storage inv = invoices[id];
        require(inv.merchant == msg.sender, "not owner");
        inv.closed = true;
        emit InvoiceClosed(id);
    }

    function getInvoice(uint256 id) external view returns (Invoice memory) {
        return invoices[id];
    }

    receive() external payable { }
}
