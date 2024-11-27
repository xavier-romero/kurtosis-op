#!/bin/bash
PS1=foo source ~/.bashrc

cd /repos/optimism/op-node

go run cmd/main.go genesis l2 \
  --deploy-config /out/deploy_config.json \
  --l1-deployments ../packages/contracts-bedrock/deployments/{{.l1_chainid}}/.deploy \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc {{.l1_rpc_url}}

openssl rand -hex 32 > jwt.txt

cp genesis.json /out/genesis.json
cp rollup.json /out/rollup.json
cp jwt.txt /out/jwt.txt
