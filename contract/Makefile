.PHONY: build test fmt snapshot deploy-kairos deploy-krws deploy-zent fund-krws sample-invoice sample-pass pay-invoice claim-pass refund-pass close-invoice install circuits test-zk deploy-zk gas-report dev zk-setup help

# Install dependencies
install:
	npm install
	forge install

# Build circuits and generate verifier
circuits:
	@echo "Building ZK circuits..."
	cd circuits && ./build.sh

# Build Solidity contracts (with circuits)
build: circuits
	forge build

test:
	forge test -vvv

# Run only ZK tests
test-zk:
	forge test --match-contract "ZK_" -vvv

fmt:
	forge fmt

snapshot:
	forge snapshot

deploy-kairos:
	@echo "Deploying to Kairos..."
	FOUNDRY_PROFILE=default \
	forge script script/DeployZent.s.sol:DeployZent \
	  --rpc-url $$KAIA_KAIROS_RPC_URL \
	  --broadcast --verify --chain-id $$KAIA_KAIROS_CHAIN_ID

deploy-krws:
	@echo "Deploying KRWS to Kairos..."
	forge script script/DeployKRWS.s.sol:DeployKRWS \
	  --rpc-url $$KAIA_KAIROS_RPC_URL \
	  --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID

# Usage:
# make fund-krws TOKEN=0x... TO=0x... AMOUNT=100000000 (== 100 KRWS if 6 decimals)
fund-krws:
	@if [ -z "$$TOKEN" ] || [ -z "$$TO" ] || [ -z "$$AMOUNT" ]; then \
		echo "Usage: make fund-krws TOKEN=0x... TO=0x... AMOUNT=<units>"; exit 1; fi
	forge script script/FundKRWS.s.sol:FundKRWS \
	  --sig "run(address,address,uint256)" $$TOKEN $$TO $$AMOUNT \
	  --rpc-url $$KAIA_KAIROS_RPC_URL \
	  --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID

deploy-zent:
	@echo "Deploying Zent (KRWS + Escrow + PayLink) to Kairos..."
	forge script script/DeployZent.s.sol:DeployZent \
	  --rpc-url $$KAIA_KAIROS_RPC_URL \
	  --broadcast --verify --chain-id $$KAIA_KAIROS_CHAIN_ID

sample-invoice:
	@if [ -z "$$PAYLINK" ] || [ -z "$$KRWS" ]; then echo "Usage: make sample-invoice PAYLINK=0x... KRWS=0x..."; exit 1; fi
	forge script script/CreateSampleInvoice.s.sol:CreateSampleInvoice \
	  --sig "run(address,address)" $$PAYLINK $$KRWS \
	  --rpc-url $$KAIA_KAIROS_RPC_URL --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID

sample-pass:
	@if [ -z "$$ESCROW" ] || [ -z "$$KRWS" ]; then echo "Usage: make sample-pass ESCROW=0x... KRWS=0x..."; exit 1; fi
	forge script script/CreateSamplePass.s.sol:CreateSamplePass \
	  --sig "run(address,address)" $$ESCROW $$KRWS \
	  --rpc-url $$KAIA_KAIROS_RPC_URL --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID

# 가변 인보이스 예시:
# make pay-invoice PAYLINK=0x... KRWS=0x... ID=1 AMOUNT=123450000 PAYER=0x0000000000000000000000000000000000000000
# 고정 인보이스 예시(AMOUNT=0):
# make pay-invoice PAYLINK=0x... KRWS=0x... ID=2 AMOUNT=0 PAYER=0x0000000000000000000000000000000000000000
pay-invoice:
	@if [ -z "$$PAYLINK" ] || [ -z "$$KRWS" ] || [ -z "$$ID" ] || [ -z "$$AMOUNT" ] || [ -z "$$PAYER" ]; then \
		echo "Usage: make pay-invoice PAYLINK=0x... KRWS=0x... ID=<invoiceId> AMOUNT=<units or 0> PAYER=0x0useMsgSender"; exit 1; fi
	forge script script/PayInvoice.s.sol:PayInvoice \
	  --sig "run(address,address,uint256,uint256,address)" $$PAYLINK $$KRWS $$ID $$AMOUNT $$PAYER \
	  --rpc-url $$KAIA_KAIROS_RPC_URL --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID

# secret은 hex나 문자열을 bytes로 인코딩하여 전달
# 예: SECRET_HEX=0x73616d706c652d736563726574 ("sample-secret")
claim-pass:
	@if [ -z "$$ESCROW" ] || [ -z "$$ID" ] || [ -z "$$SECRET_HEX" ] || [ -z "$$RECEIVER" ]; then \
		echo "Usage: make claim-pass ESCROW=0x... ID=<passId> SECRET_HEX=0x... RECEIVER=0x0useMsgSender"; exit 1; fi
	forge script script/ClaimPass.s.sol:ClaimPass \
	  --sig "run(address,uint256,bytes,address)" $$ESCROW $$ID $$SECRET_HEX $$RECEIVER \
	  --rpc-url $$KAIA_KAIROS_RPC_URL --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID

refund-pass:
	@if [ -z "$$ESCROW" ] || [ -z "$$ID" ]; then \
		echo "Usage: make refund-pass ESCROW=0x... ID=<passId>"; exit 1; fi
	forge script script/RefundPass.s.sol:RefundPass \
	  --sig "run(address,uint256)" $$ESCROW $$ID \
	  --rpc-url $$KAIA_KAIROS_RPC_URL --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID

close-invoice:
	@if [ -z "$$PAYLINK" ] || [ -z "$$ID" ]; then \
		echo "Usage: make close-invoice PAYLINK=0x... ID=<invoiceId>"; exit 1; fi
	forge script script/CloseInvoice.s.sol:CloseInvoice \
	  --sig "run(address,uint256)" $$PAYLINK $$ID \
	  --rpc-url $$KAIA_KAIROS_RPC_URL --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID

# Deploy ZK contracts
deploy-zk:
	@test -n "$$PRIVATE_KEY" || (echo "PRIVATE_KEY not set" && exit 1)
	@test -n "$$KAIA_KAIROS_RPC_URL" || (echo "KAIA_KAIROS_RPC_URL not set" && exit 1)
	@test -n "$$FEE_RECIPIENT" || (echo "FEE_RECIPIENT not set" && exit 1)
	forge script script/DeployZK.s.sol:DeployZK \
	  --rpc-url $$KAIA_KAIROS_RPC_URL \
	  --broadcast --chain-id $$KAIA_KAIROS_CHAIN_ID -vvvv

# Generate gas report
gas-report:
	forge test --gas-report

# Clean build artifacts
clean:
	forge clean
	rm -rf circuits/artifacts/*.r1cs circuits/artifacts/*.sym circuits/artifacts/*_js

# Development shortcuts
dev: install build test

# Full ZK setup
zk-setup: install circuits build test-zk

# Help
help:
	@echo "Available commands:"
	@echo "  make install      - Install all dependencies"
	@echo "  make circuits     - Build ZK circuits and generate verifier"
	@echo "  make build        - Build circuits and contracts"
	@echo "  make test         - Run all tests"
	@echo "  make test-zk      - Run only ZK tests"
	@echo "  make deploy-zk    - Deploy ZK contracts (requires env vars)"
	@echo "  make gas-report   - Generate gas usage report"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make dev          - Full development setup"
	@echo "  make zk-setup     - Complete ZK setup and test"
