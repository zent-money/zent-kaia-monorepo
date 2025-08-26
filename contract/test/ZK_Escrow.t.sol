// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ZentEscrow.sol";
import "../src/zk/IZKVerifier.sol";
import "../src/libs/Poseidon.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// Mock Verifier for testing
contract MockVerifier is IZKVerifier {
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

contract ZK_EscrowTest is Test {
    ZentEscrow public escrow;
    MockVerifier public verifier;
    MockERC20 public token;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    
    // Test vectors (would be generated from circuit)
    bytes32 constant SECRET = bytes32(uint256(123456));
    bytes32 constant NULLIFIER = bytes32(uint256(789012));
    bytes32 public commitment;
    bytes32 public nullifierHash;
    
    // Mock proof components
    uint256[2] mockA = [1, 2];
    uint256[2][2] mockB = [[3, 4], [5, 6]];
    uint256[2] mockC = [7, 8];
    
    event Deposited(address indexed payer, address asset, uint256 amount, bytes32 indexed commitment, uint64 expiry);
    event Claimed(address indexed recipient, address asset, uint256 amount, bytes32 indexed commitment, bytes32 nullifierHash);
    event Cancelled(address indexed payer, bytes32 indexed commitment);
    
    function setUp() public {
        verifier = new MockVerifier();
        escrow = new ZentEscrow(address(verifier));
        token = new MockERC20();
        
        // Setup test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
        token.mint(alice, 1000 * 10**18);
        token.mint(bob, 1000 * 10**18);
        
        // Calculate commitment and nullifier hash (simplified for testing)
        commitment = keccak256(abi.encode(SECRET, NULLIFIER));
        nullifierHash = keccak256(abi.encode(NULLIFIER));
        
        // Set up valid proof in mock verifier
        verifier.setValidProof(commitment, nullifierHash);
    }
    
    // ============ ZK Deposit Tests ============
    
    function testDepositNative() public {
        uint256 amount = 1 ether;
        uint64 expiry = uint64(block.timestamp + 1 days);
        
        vm.startPrank(alice);
        vm.expectEmit(true, true, false, true);
        emit Deposited(alice, address(0), amount, commitment, expiry);
        
        escrow.deposit{value: amount}(address(0), amount, commitment, expiry);
        vm.stopPrank();
        
        // Verify deposit
        (address payer, address asset, uint256 amt, uint64 exp, bool claimed) = escrow.deposits(commitment);
        assertEq(payer, alice);
        assertEq(asset, address(0));
        assertEq(amt, amount);
        assertEq(exp, expiry);
        assertFalse(claimed);
    }
    
    function testDepositERC20() public {
        uint256 amount = 100 * 10**18;
        uint64 expiry = uint64(block.timestamp + 1 days);
        
        vm.startPrank(alice);
        token.approve(address(escrow), amount);
        
        vm.expectEmit(true, true, false, true);
        emit Deposited(alice, address(token), amount, commitment, expiry);
        
        escrow.deposit(address(token), amount, commitment, expiry);
        vm.stopPrank();
        
        // Verify deposit
        (address payer, address asset, uint256 amt, uint64 exp, bool claimed) = escrow.deposits(commitment);
        assertEq(payer, alice);
        assertEq(asset, address(token));
        assertEq(amt, amount);
        assertEq(exp, expiry);
        assertFalse(claimed);
    }
    
    function testCannotDepositDuplicateCommitment() public {
        uint256 amount = 1 ether;
        
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, 0);
        
        vm.prank(bob);
        vm.expectRevert("commitment exists");
        escrow.deposit{value: amount}(address(0), amount, commitment, 0);
    }
    
    // ============ ZK Claim Tests ============
    
    function testClaimWithValidProof() public {
        uint256 amount = 1 ether;
        uint256 bobBalanceBefore = bob.balance;
        
        // Alice deposits
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, 0);
        
        // Bob claims with valid proof
        vm.expectEmit(true, false, false, true);
        emit Claimed(bob, address(0), amount, commitment, nullifierHash);
        
        escrow.claim(commitment, nullifierHash, bob, mockA, mockB, mockC);
        
        // Verify claim
        assertEq(bob.balance, bobBalanceBefore + amount);
        assertTrue(escrow.nullifierUsed(nullifierHash));
        (, , , , bool claimed) = escrow.deposits(commitment);
        assertTrue(claimed);
    }
    
    function testCannotDoubleClaimWithSameNullifier() public {
        uint256 amount = 1 ether;
        bytes32 commitment2 = keccak256(abi.encode(SECRET, bytes32(uint256(999))));
        
        // Setup two deposits
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, 0);
        
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment2, 0);
        
        verifier.setValidProof(commitment2, nullifierHash);
        
        // First claim succeeds
        escrow.claim(commitment, nullifierHash, bob, mockA, mockB, mockC);
        
        // Second claim with same nullifier fails
        vm.expectRevert("nullifier used");
        escrow.claim(commitment2, nullifierHash, bob, mockA, mockB, mockC);
    }
    
    function testCannotClaimWithInvalidProof() public {
        uint256 amount = 1 ether;
        bytes32 wrongNullifier = keccak256(abi.encode(bytes32(uint256(999))));
        
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, 0);
        
        vm.expectRevert("invalid proof");
        escrow.claim(commitment, wrongNullifier, bob, mockA, mockB, mockC);
    }
    
    function testCannotClaimExpired() public {
        uint256 amount = 1 ether;
        uint64 expiry = uint64(block.timestamp + 1 hours);
        
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, expiry);
        
        // Fast forward past expiry
        vm.warp(block.timestamp + 2 hours);
        
        vm.expectRevert("expired");
        escrow.claim(commitment, nullifierHash, bob, mockA, mockB, mockC);
    }
    
    // ============ Cancel Tests ============
    
    function testCancelExpired() public {
        uint256 amount = 1 ether;
        uint64 expiry = uint64(block.timestamp + 1 hours);
        uint256 aliceBalanceBefore = alice.balance;
        
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, expiry);
        
        // Fast forward past expiry
        vm.warp(block.timestamp + 2 hours);
        
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit Cancelled(alice, commitment);
        escrow.cancelExpired(commitment);
        
        assertEq(alice.balance, aliceBalanceBefore);
        (, , , , bool claimed) = escrow.deposits(commitment);
        assertTrue(claimed); // Marked as claimed to prevent double-spend
    }
    
    function testOnlyPayerCanCancel() public {
        uint256 amount = 1 ether;
        uint64 expiry = uint64(block.timestamp + 1 hours);
        
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, expiry);
        
        vm.warp(block.timestamp + 2 hours);
        
        vm.prank(bob);
        vm.expectRevert("not payer");
        escrow.cancelExpired(commitment);
    }
    
    function testCannotCancelBeforeExpiry() public {
        uint256 amount = 1 ether;
        uint64 expiry = uint64(block.timestamp + 1 hours);
        
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, expiry);
        
        vm.prank(alice);
        vm.expectRevert("not expired");
        escrow.cancelExpired(commitment);
    }
    
    // ============ ERC20 Tests ============
    
    function testClaimERC20WithProof() public {
        uint256 amount = 100 * 10**18;
        uint256 bobBalanceBefore = token.balanceOf(bob);
        
        vm.prank(alice);
        token.approve(address(escrow), amount);
        escrow.deposit(address(token), amount, commitment, 0);
        
        escrow.claim(commitment, nullifierHash, bob, mockA, mockB, mockC);
        
        assertEq(token.balanceOf(bob), bobBalanceBefore + amount);
    }
    
    // ============ Gas Tests ============
    
    function testGasForClaim() public {
        uint256 amount = 1 ether;
        
        vm.prank(alice);
        escrow.deposit{value: amount}(address(0), amount, commitment, 0);
        
        uint256 gasBefore = gasleft();
        escrow.claim(commitment, nullifierHash, bob, mockA, mockB, mockC);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for claim:", gasUsed);
        assertTrue(gasUsed < 150000, "Gas usage too high");
    }
    
    // ============ Legacy Compatibility Tests ============
    
    function testLegacyCreatePass() public {
        uint256 amount = 100 * 10**18;
        bytes32 hashSecret = keccak256("secret123");
        uint64 expiry = uint64(block.timestamp + 1 days);
        
        vm.prank(alice);
        token.approve(address(escrow), amount);
        uint256 passId = escrow.createPass(address(token), amount, hashSecret, expiry);
        
        assertEq(passId, 1);
        IZentEscrow.Pass memory pass = escrow.getPass(passId);
        assertEq(pass.sender, alice);
        assertEq(pass.amount, amount);
    }
    
    function testLegacyClaimPass() public {
        uint256 amount = 100 * 10**18;
        bytes memory secret = "secret123";
        bytes32 hashSecret = keccak256(secret);
        uint64 expiry = uint64(block.timestamp + 1 days);
        
        vm.prank(alice);
        token.approve(address(escrow), amount);
        uint256 passId = escrow.createPass(address(token), amount, hashSecret, expiry);
        
        uint256 bobBalanceBefore = token.balanceOf(bob);
        escrow.claimPass(passId, secret, bob);
        
        assertEq(token.balanceOf(bob), bobBalanceBefore + amount);
    }
}