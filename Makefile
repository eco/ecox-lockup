# private key of deploying wallet
PRIV?=
# constructor args when deploying factory (implementation address)
ARGS?=
# RPC url to deploy to
RPC?=https://goerli.infura.io/v3/b2eb74fe7b1847f29a35c8bdb93c0e84

# deploy the lockup vault initial implementation
implementation:
	forge create ECOxLockupVault --private-key $(PRIV) --rpc-url $(RPC)
implementation-local:
	forge create ECOxLockupVault --private-key $(PRIV) --rpc-url http://localhost:8545 --legacy

# deploy the lockup vault factory using the deployed implementation
factory:
	forge create ECOxLockupVaultFactory --private-key $(PRIV)  --rpc-url $(RPC) --constructor-args $(ARGS)
factory-local:
	forge create ECOxLockupVaultFactory --private-key $(PRIV) --rpc-url http://localhost:8545 --legacy --constructor-args $(ARGS)

# clean compilation folders
clean:
	rm -rf out/ cache/