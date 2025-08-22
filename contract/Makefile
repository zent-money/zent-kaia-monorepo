.PHONY: build test fmt snapshot deploy-kairos deploy-krws deploy-zent fund-krws

build:
	forge build

test:
	forge test -vvv

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
