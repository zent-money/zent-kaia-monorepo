// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IZentPayLink } from "./interfaces/IZentPayLink.sol";
import { IZKVerifier } from "./zk/IZKVerifier.sol";

contract ZentPayLink is IZentPayLink, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IZKVerifier public immutable verifier;
    address public feeRecipient;
    uint256 public feeBps; // protocol fee in basis points (e.g., 50 = 0.5%)
    uint256 public constant BPS_DENOM = 10_000;

    // ZK storage
    struct ZKInvoice {
        address merchant;
        address asset;      // address(0) for native
        uint256 amount;     // 0 = variable
        uint64 dueAt;       // expiry
        string metadataURI;
        uint256 totalPaid;
        bool closed;
        bool claimed;       // for ZK claims
    }
    
    mapping(bytes32 => ZKInvoice) public zkInvoices;      // commitment => invoice
    mapping(bytes32 => bool) public nullifierUsed;        // nullifierHash => spent
    
    // Legacy storage
    uint256 public nextId;
    mapping(uint256 => Invoice) private invoices;
    
    // Events for ZK system
    event InvoiceIssuedZK(address indexed merchant, address asset, uint256 amount, bytes32 indexed commitment, uint64 dueAt);
    event InvoiceSettled(address indexed payer, address asset, uint256 amount, bytes32 indexed commitment, bytes32 nullifierHash);
    event InvoiceCancelledZK(address indexed merchant, bytes32 indexed commitment);

    constructor(address _verifier, address _feeRecipient, uint256 _feeBps) {
        require(_verifier != address(0), "verifier=0");
        verifier = IZKVerifier(_verifier);
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
    }

    // ZK invoice creation
    function issueInvoice(
        address asset,
        uint256 amount,
        bytes32 commitment,
        uint64 dueAt,
        string calldata metadataURI
    ) external nonReentrant {
        require(zkInvoices[commitment].merchant == address(0), "commitment exists");
        require(dueAt == 0 || dueAt > block.timestamp, "invalid due date");
        
        zkInvoices[commitment] = ZKInvoice({
            merchant: msg.sender,
            asset: asset,
            amount: amount,
            dueAt: dueAt,
            metadataURI: metadataURI,
            totalPaid: 0,
            closed: false,
            claimed: false
        });
        
        emit InvoiceIssuedZK(msg.sender, asset, amount, commitment, dueAt);
    }
    
    // ZK settlement with proof
    function settleWithProof(
        bytes32 commitment,
        bytes32 nullifierHash,
        address payer,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) external payable nonReentrant {
        ZKInvoice storage inv = zkInvoices[commitment];
        require(inv.merchant != address(0), "not found");
        require(!inv.closed && !inv.claimed, "closed or claimed");
        require(!nullifierUsed[nullifierHash], "nullifier used");
        require(inv.dueAt == 0 || block.timestamp <= inv.dueAt, "expired");
        
        // Verify proof
        uint256[2] memory publicInputs = [uint256(commitment), uint256(nullifierHash)];
        require(verifier.verifyProof(a, b, c, publicInputs), "invalid proof");
        
        // Mark as used
        inv.claimed = true;
        nullifierUsed[nullifierHash] = true;
        
        uint256 paymentAmount = inv.amount > 0 ? inv.amount : msg.value; // Fixed or variable
        require(paymentAmount > 0, "amount=0");
        
        // Collect payment
        address actualPayer = payer == address(0) ? msg.sender : payer;
        if (inv.asset == address(0)) {
            require(msg.value == paymentAmount, "native mismatch");
        } else {
            require(msg.value == 0, "no msg.value");
            IERC20(inv.asset).safeTransferFrom(actualPayer, address(this), paymentAmount);
        }
        
        // Calculate and distribute fees
        uint256 fee = (paymentAmount * feeBps) / BPS_DENOM;
        uint256 toMerchant = paymentAmount - fee;
        
        if (inv.asset == address(0)) {
            if (fee > 0) {
                (bool ok1,) = payable(feeRecipient).call{value: fee}("");
                require(ok1, "fee transfer failed");
            }
            (bool ok2,) = payable(inv.merchant).call{value: toMerchant}("");
            require(ok2, "merchant transfer failed");
        } else {
            if (fee > 0) IERC20(inv.asset).safeTransfer(feeRecipient, fee);
            IERC20(inv.asset).safeTransfer(inv.merchant, toMerchant);
        }
        
        inv.totalPaid += paymentAmount;
        emit InvoiceSettled(actualPayer, inv.asset, paymentAmount, commitment, nullifierHash);
    }
    
    // Close ZK invoice
    function closeZKInvoice(bytes32 commitment) external {
        ZKInvoice storage inv = zkInvoices[commitment];
        require(inv.merchant == msg.sender, "not merchant");
        inv.closed = true;
        emit InvoiceCancelledZK(msg.sender, commitment);
    }
    
    // ============ Legacy functions for backward compatibility ============
    
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