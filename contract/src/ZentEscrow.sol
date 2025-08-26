// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IZentEscrow } from "./interfaces/IZentEscrow.sol";
import { IZKVerifier } from "./zk/IZKVerifier.sol";

contract ZentEscrow is IZentEscrow, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    IZKVerifier public immutable verifier;
    
    // ZK storage
    struct Deposit {
        address payer;
        address asset;   // address(0) for native
        uint256 amount;
        uint64 expiry;   // optional, 0 means no expiry
        bool claimed;
    }
    
    mapping(bytes32 => Deposit) public deposits;          // commitment => deposit metadata
    mapping(bytes32 => bool) public nullifierUsed;        // nullifierHash => spent
    
    // Legacy storage (for backward compatibility)
    uint256 public nextId;
    mapping(uint256 => Pass) private passes;
    
    // Events for ZK system
    event Deposited(address indexed payer, address asset, uint256 amount, bytes32 indexed commitment, uint64 expiry);
    event Claimed(address indexed recipient, address asset, uint256 amount, bytes32 indexed commitment, bytes32 nullifierHash);
    event Cancelled(address indexed payer, bytes32 indexed commitment);
    
    constructor(address _verifier) {
        require(_verifier != address(0), "verifier=0");
        verifier = IZKVerifier(_verifier);
    }
    
    // ZK deposit function
    function deposit(address asset, uint256 amount, bytes32 commitment, uint64 expiry) 
        external 
        payable 
        nonReentrant 
    {
        require(amount > 0, "amount=0");
        require(deposits[commitment].payer == address(0), "commitment exists");
        require(expiry == 0 || expiry > block.timestamp, "invalid expiry");
        
        // Handle native vs ERC20
        if (asset == address(0)) {
            require(msg.value == amount, "native mismatch");
        } else {
            require(msg.value == 0, "no msg.value");
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        }
        
        deposits[commitment] = Deposit({
            payer: msg.sender,
            asset: asset,
            amount: amount,
            expiry: expiry,
            claimed: false
        });
        
        emit Deposited(msg.sender, asset, amount, commitment, expiry);
    }
    
    // ZK claim with proof
    function claim(
        bytes32 commitment,
        bytes32 nullifierHash,
        address recipient,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) external nonReentrant {
        Deposit storage d = deposits[commitment];
        require(d.payer != address(0), "not found");
        require(!d.claimed, "already claimed");
        require(!nullifierUsed[nullifierHash], "nullifier used");
        require(d.expiry == 0 || block.timestamp <= d.expiry, "expired");
        
        // Verify proof with public inputs [commitment, nullifierHash]
        uint256[2] memory publicInputs = [uint256(commitment), uint256(nullifierHash)];
        require(verifier.verifyProof(a, b, c, publicInputs), "invalid proof");
        
        // Mark as claimed
        d.claimed = true;
        nullifierUsed[nullifierHash] = true;
        
        // Transfer to recipient
        address to = recipient == address(0) ? msg.sender : recipient;
        if (d.asset == address(0)) {
            (bool success,) = to.call{value: d.amount}("");
            require(success, "native transfer failed");
        } else {
            IERC20(d.asset).safeTransfer(to, d.amount);
        }
        
        emit Claimed(to, d.asset, d.amount, commitment, nullifierHash);
    }
    
    // Cancel expired deposit
    function cancelExpired(bytes32 commitment) external nonReentrant {
        Deposit storage d = deposits[commitment];
        require(d.payer != address(0), "not found");
        require(d.payer == msg.sender, "not payer");
        require(!d.claimed, "already claimed");
        require(d.expiry > 0 && block.timestamp > d.expiry, "not expired");
        
        d.claimed = true;
        
        if (d.asset == address(0)) {
            (bool success,) = d.payer.call{value: d.amount}("");
            require(success, "refund failed");
        } else {
            IERC20(d.asset).safeTransfer(d.payer, d.amount);
        }
        
        emit Cancelled(d.payer, commitment);
    }
    
    // ============ Legacy functions for backward compatibility ============
    
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
        require(msg.sender == p.sender, "not sender");
        
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