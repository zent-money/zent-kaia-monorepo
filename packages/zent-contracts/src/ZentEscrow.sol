// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IZentEscrow } from "./interfaces/IZentEscrow.sol";

contract ZentEscrow is IZentEscrow, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public nextId;
    mapping(uint256 => Pass) private passes;

    function createPass(address token, uint256 amount, bytes32 hashSecret, uint64 expiry)
        external
        payable
        nonReentrant
        returns (uint256 id)
    {
        require(expiry > block.timestamp, "expiry");
        if (token == address(0)) {
            require(msg.value == amount, "native mismatch");
        } else {
            require(msg.value == 0, "no msg.value");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        id = ++nextId;
        passes[id] = Pass({
            sender: msg.sender,
            token: token,
            amount: amount,
            hashSecret: hashSecret,
            expiry: expiry,
            claimedBy: address(0),
            refunded: false
        });

        emit PassCreated(id, msg.sender, token, amount, expiry);
    }

    function claimPass(uint256 id, bytes calldata secret, address receiver) external nonReentrant {
        Pass storage p = passes[id];
        require(p.sender != address(0), "not found");
        require(p.claimedBy == address(0) && !p.refunded, "spent");
        require(block.timestamp <= p.expiry, "expired");
        require(keccak256(secret) == p.hashSecret, "bad secret");

        p.claimedBy = receiver == address(0) ? msg.sender : receiver;
        if (p.token == address(0)) {
            (bool ok,) = p.claimedBy.call{ value: p.amount }("");
            require(ok, "xfer fail");
        } else {
            IERC20(p.token).safeTransfer(p.claimedBy, p.amount);
        }
        emit PassClaimed(id, p.claimedBy);
    }

    function refundPass(uint256 id) external nonReentrant {
        Pass storage p = passes[id];
        require(p.sender != address(0), "not found");
        require(p.claimedBy == address(0) && !p.refunded, "spent");
        require(block.timestamp > p.expiry, "not expired");
        p.refunded = true;
        if (p.token == address(0)) {
            (bool ok,) = p.sender.call{ value: p.amount }("");
            require(ok, "refund fail");
        } else {
            IERC20(p.token).safeTransfer(p.sender, p.amount);
        }
        emit PassRefunded(id);
    }

    function getPass(uint256 id) external view returns (Pass memory) {
        return passes[id];
    }

    receive() external payable { }
}
