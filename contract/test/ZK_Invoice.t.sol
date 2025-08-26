// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ZentPayLink.sol";
import "../src/zk/IZKVerifier.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 for testing
contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// Mock Verifier for testing
contract MockInvoiceVerifier is IZKVerifier {
    mapping(bytes32 => bool) public validProofs;
    
    function setValidProof(bytes32 commitment, bytes32 nullifierHash) external {
        validProofs[keccak256(abi.encode(commitment, nullifierHash))] = true;
    }
    
    function verifyProof(
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory,
        uint256[2] memory input
    ) external view override returns (bool) {
        bytes32 key = keccak256(abi.encode(bytes32(input[0]), bytes32(input[1])));
        return validProofs[key];
    }
}

contract ZK_InvoiceTest is Test {
    ZentPayLink public payLink;
    MockInvoiceVerifier public verifier;
    MockToken public token;
    
    address public merchant = address(0x1);
    address public payer = address(0x2);
    address public feeRecipient = address(0x3);
    uint256 public feeBps = 50; // 0.5%
    
    // Test vectors
    bytes32 constant SECRET = bytes32(uint256(123456));
    bytes32 constant NULLIFIER = bytes32(uint256(789012));
    bytes32 public commitment;
    bytes32 public nullifierHash;
    
    // Mock proof components
    uint256[2] mockA = [1, 2];
    uint256[2][2] mockB = [[3, 4], [5, 6]];
    uint256[2] mockC = [7, 8];
    
    event InvoiceIssuedZK(address indexed merchant, address asset, uint256 amount, bytes32 indexed commitment, uint64 dueAt);
    event InvoiceSettled(address indexed payer, address asset, uint256 amount, bytes32 indexed commitment, bytes32 nullifierHash);
    event InvoiceCancelledZK(address indexed merchant, bytes32 indexed commitment);
    
    function setUp() public {
        verifier = new MockInvoiceVerifier();
        payLink = new ZentPayLink(address(verifier), feeRecipient, feeBps);
        token = new MockToken();
        
        // Setup test accounts
        vm.deal(merchant, 10 ether);
        vm.deal(payer, 10 ether);
        vm.deal(feeRecipient, 10 ether);
        token.mint(payer, 1000 * 10**18);
        
        // Calculate commitment and nullifier hash
        commitment = keccak256(abi.encode(SECRET, NULLIFIER));
        nullifierHash = keccak256(abi.encode(NULLIFIER));
        
        // Set up valid proof
        verifier.setValidProof(commitment, nullifierHash);
    }
    
    // ============ Invoice Issuance Tests ============
    
    function testIssueInvoiceNative() public {
        uint256 amount = 1 ether;
        uint64 dueAt = uint64(block.timestamp + 7 days);
        string memory metadata = "Invoice for services";
        
        vm.prank(merchant);
        vm.expectEmit(true, true, false, true);
        emit InvoiceIssuedZK(merchant, address(0), amount, commitment, dueAt);
        
        payLink.issueInvoice(address(0), amount, commitment, dueAt, metadata);
        
        // Verify invoice
        (
            address _merchant,
            address asset,
            uint256 amt,
            uint64 due,
            string memory meta,
            uint256 paid,
            bool closed,
            bool claimed
        ) = payLink.zkInvoices(commitment);
        
        assertEq(_merchant, merchant);
        assertEq(asset, address(0));
        assertEq(amt, amount);
        assertEq(due, dueAt);
        assertEq(meta, metadata);
        assertEq(paid, 0);
        assertFalse(closed);
        assertFalse(claimed);
    }
    
    function testIssueInvoiceERC20() public {
        uint256 amount = 100 * 10**18;
        uint64 dueAt = uint64(block.timestamp + 7 days);
        
        vm.prank(merchant);
        payLink.issueInvoice(address(token), amount, commitment, dueAt, "ERC20 Invoice");
        
        (address _merchant, address asset, uint256 amt, , , , , ) = payLink.zkInvoices(commitment);
        assertEq(_merchant, merchant);
        assertEq(asset, address(token));
        assertEq(amt, amount);
    }
    
    function testIssueVariableAmountInvoice() public {
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 0, commitment, 0, "Variable amount invoice");
        
        (, , uint256 amt, , , , , ) = payLink.zkInvoices(commitment);
        assertEq(amt, 0); // Variable amount
    }
    
    function testCannotIssueDuplicateCommitment() public {
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment, 0, "Invoice 1");
        
        vm.prank(merchant);
        vm.expectRevert("commitment exists");
        payLink.issueInvoice(address(0), 2 ether, commitment, 0, "Invoice 2");
    }
    
    // ============ Settlement Tests ============
    
    function testSettleWithProofNative() public {
        uint256 amount = 1 ether;
        uint256 expectedFee = (amount * feeBps) / 10000;
        uint256 expectedMerchantAmount = amount - expectedFee;
        
        vm.prank(merchant);
        payLink.issueInvoice(address(0), amount, commitment, 0, "Native invoice");
        
        uint256 merchantBalanceBefore = merchant.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        vm.expectEmit(true, false, false, true);
        emit InvoiceSettled(payer, address(0), amount, commitment, nullifierHash);
        
        payLink.settleWithProof{value: amount}(
            commitment,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
        
        // Verify balances
        assertEq(merchant.balance, merchantBalanceBefore + expectedMerchantAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + expectedFee);
        
        // Verify invoice state
        (, , , , , uint256 totalPaid, , bool claimed) = payLink.zkInvoices(commitment);
        assertEq(totalPaid, amount);
        assertTrue(claimed);
        assertTrue(payLink.nullifierUsed(nullifierHash));
    }
    
    function testSettleWithProofERC20() public {
        uint256 amount = 100 * 10**18;
        uint256 expectedFee = (amount * feeBps) / 10000;
        uint256 expectedMerchantAmount = amount - expectedFee;
        
        vm.prank(merchant);
        payLink.issueInvoice(address(token), amount, commitment, 0, "ERC20 invoice");
        
        vm.prank(payer);
        token.approve(address(payLink), amount);
        
        uint256 merchantBalanceBefore = token.balanceOf(merchant);
        uint256 feeRecipientBalanceBefore = token.balanceOf(feeRecipient);
        
        payLink.settleWithProof(
            commitment,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
        
        assertEq(token.balanceOf(merchant), merchantBalanceBefore + expectedMerchantAmount);
        assertEq(token.balanceOf(feeRecipient), feeRecipientBalanceBefore + expectedFee);
    }
    
    function testSettleVariableAmount() public {
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 0, commitment, 0, "Variable invoice");
        
        uint256 paymentAmount = 2.5 ether;
        uint256 expectedFee = (paymentAmount * feeBps) / 10000;
        uint256 expectedMerchantAmount = paymentAmount - expectedFee;
        
        uint256 merchantBalanceBefore = merchant.balance;
        
        payLink.settleWithProof{value: paymentAmount}(
            commitment,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
        
        assertEq(merchant.balance, merchantBalanceBefore + expectedMerchantAmount);
    }
    
    function testCannotDoubleSettle() public {
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment, 0, "Invoice");
        
        payLink.settleWithProof{value: 1 ether}(
            commitment,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
        
        vm.expectRevert("closed or claimed");
        payLink.settleWithProof{value: 1 ether}(
            commitment,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
    }
    
    function testCannotReuseNullifier() public {
        bytes32 commitment2 = keccak256(abi.encode(SECRET, bytes32(uint256(999))));
        verifier.setValidProof(commitment2, nullifierHash);
        
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment, 0, "Invoice 1");
        
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment2, 0, "Invoice 2");
        
        // First settlement succeeds
        payLink.settleWithProof{value: 1 ether}(
            commitment,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
        
        // Second settlement with same nullifier fails
        vm.expectRevert("nullifier used");
        payLink.settleWithProof{value: 1 ether}(
            commitment2,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
    }
    
    function testCannotSettleExpired() public {
        uint64 dueAt = uint64(block.timestamp + 1 hours);
        
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment, dueAt, "Invoice");
        
        vm.warp(block.timestamp + 2 hours);
        
        vm.expectRevert("expired");
        payLink.settleWithProof{value: 1 ether}(
            commitment,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
    }
    
    function testCannotSettleWithInvalidProof() public {
        bytes32 wrongNullifier = keccak256(abi.encode(bytes32(uint256(999))));
        
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment, 0, "Invoice");
        
        vm.expectRevert("invalid proof");
        payLink.settleWithProof{value: 1 ether}(
            commitment,
            wrongNullifier,
            payer,
            mockA,
            mockB,
            mockC
        );
    }
    
    // ============ Close Invoice Tests ============
    
    function testCloseInvoice() public {
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment, 0, "Invoice");
        
        vm.prank(merchant);
        vm.expectEmit(true, true, false, false);
        emit InvoiceCancelledZK(merchant, commitment);
        payLink.closeZKInvoice(commitment);
        
        (, , , , , , bool closed, ) = payLink.zkInvoices(commitment);
        assertTrue(closed);
    }
    
    function testOnlyMerchantCanClose() public {
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment, 0, "Invoice");
        
        vm.prank(payer);
        vm.expectRevert("not merchant");
        payLink.closeZKInvoice(commitment);
    }
    
    // ============ Gas Tests ============
    
    function testGasForSettlement() public {
        vm.prank(merchant);
        payLink.issueInvoice(address(0), 1 ether, commitment, 0, "Invoice");
        
        uint256 gasBefore = gasleft();
        payLink.settleWithProof{value: 1 ether}(
            commitment,
            nullifierHash,
            payer,
            mockA,
            mockB,
            mockC
        );
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for settlement:", gasUsed);
        assertTrue(gasUsed < 200000, "Gas usage too high");
    }
    
    // ============ Legacy Compatibility Tests ============
    
    function testLegacyCreateInvoice() public {
        uint256 amount = 100 * 10**18;
        uint64 expiry = uint64(block.timestamp + 7 days);
        
        vm.prank(merchant);
        uint256 invoiceId = payLink.createInvoice(address(token), amount, expiry, "Legacy invoice");
        
        assertEq(invoiceId, 1);
        IZentPayLink.Invoice memory invoice = payLink.getInvoice(invoiceId);
        assertEq(invoice.merchant, merchant);
        assertEq(invoice.amount, amount);
    }
    
    function testLegacyPayInvoice() public {
        uint256 amount = 100 * 10**18;
        uint64 expiry = uint64(block.timestamp + 7 days);
        
        vm.prank(merchant);
        uint256 invoiceId = payLink.createInvoice(address(token), amount, expiry, "Legacy invoice");
        
        vm.prank(payer);
        token.approve(address(payLink), amount);
        
        uint256 merchantBalanceBefore = token.balanceOf(merchant);
        payLink.pay(invoiceId, amount, payer);
        
        uint256 expectedFee = (amount * feeBps) / 10000;
        uint256 expectedMerchantAmount = amount - expectedFee;
        
        assertEq(token.balanceOf(merchant), merchantBalanceBefore + expectedMerchantAmount);
    }
}