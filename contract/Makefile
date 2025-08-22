.PHONY: build test fmt snapshot deploy-kairos

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
