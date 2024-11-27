#!/bin/bash

cd /repos/optimism
git checkout tutorials/chain && git pull
cd packages/contracts-bedrock

GS_ADMIN_ADDRESS=$(cast wallet address --mnemonic "{{.addresses.admin.mnemonic}}")
GS_BATCHER_ADDRESS={{.addresses.batcher.address}}
GS_PROPOSER_ADDRESS={{.addresses.proposer.address}}
GS_SEQUENCER_ADDRESS={{.addresses.sequencer.address}}
L1_CHAINID={{.l1_chainid}}
L2_CHAINID={{.l2_chainid}}
L1_BLOCKTIME={{.l1_blocktime}}
L2_BLOCKTIME={{.l2_blocktime}}

block=$(cast block finalized --rpc-url {{.l1_rpc_url}})
timestamp=$(echo "$block" | awk '/timestamp/ { print $2 }')
blockhash=$(echo "$block" | awk '/hash/ { print $2 }')

config=$(cat << EOL
{
  "l1StartingBlockTag": "$blockhash",

  "l1ChainID": $L1_CHAINID,
  "l2ChainID": $L2_CHAINID,
  "l2BlockTime": $L2_BLOCKTIME,
  "l1BlockTime": $L1_BLOCKTIME,

  "maxSequencerDrift": 600,
  "sequencerWindowSize": 3600,
  "channelTimeout": 300,

  "p2pSequencerAddress": "$GS_SEQUENCER_ADDRESS",
  "batchInboxAddress": "0xff00000000000000000000000000000000042069",
  "batchSenderAddress": "$GS_BATCHER_ADDRESS",

  "l2OutputOracleSubmissionInterval": 120,
  "l2OutputOracleStartingBlockNumber": 0,
  "l2OutputOracleStartingTimestamp": $timestamp,

  "l2OutputOracleProposer": "$GS_PROPOSER_ADDRESS",
  "l2OutputOracleChallenger": "$GS_ADMIN_ADDRESS",

  "finalizationPeriodSeconds": 12,

  "proxyAdminOwner": "$GS_ADMIN_ADDRESS",
  "baseFeeVaultRecipient": "$GS_ADMIN_ADDRESS",
  "l1FeeVaultRecipient": "$GS_ADMIN_ADDRESS",
  "sequencerFeeVaultRecipient": "$GS_ADMIN_ADDRESS",
  "finalSystemOwner": "$GS_ADMIN_ADDRESS",
  "superchainConfigGuardian": "$GS_ADMIN_ADDRESS",

  "baseFeeVaultMinimumWithdrawalAmount": "0x8ac7230489e80000",
  "l1FeeVaultMinimumWithdrawalAmount": "0x8ac7230489e80000",
  "sequencerFeeVaultMinimumWithdrawalAmount": "0x8ac7230489e80000",
  "baseFeeVaultWithdrawalNetwork": 0,
  "l1FeeVaultWithdrawalNetwork": 0,
  "sequencerFeeVaultWithdrawalNetwork": 0,

  "gasPriceOracleOverhead": 2100,
  "gasPriceOracleScalar": 1000000,

  "enableGovernance": true,
  "governanceTokenSymbol": "OP",
  "governanceTokenName": "Optimism",
  "governanceTokenOwner": "$GS_ADMIN_ADDRESS",

  "l2GenesisBlockGasLimit": "0x1c9c380",
  "l2GenesisBlockBaseFeePerGas": "0x3b9aca00",
  "l2GenesisRegolithTimeOffset": "0x0",

  "eip1559Denominator": 50,
  "eip1559DenominatorCanyon": 250,
  "eip1559Elasticity": 6,

  "l2GenesisRegolithTimeOffset": "0x0",
  "l2GenesisDeltaTimeOffset": null,
  "l2GenesisCanyonTimeOffset": "0x0",

  "systemConfigStartBlock": 0,

  "requiredProtocolVersion": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "recommendedProtocolVersion": "0x0000000000000000000000000000000000000000000000000000000000000000",

  "faultGameAbsolutePrestate": "0x03c7ae758795765c6664a5d39bf63841c71ff191e9189522bad8ebff5d4eca98",
  "faultGameMaxDepth": 44,
  "faultGameMaxDuration": 1200,
  "faultGameGenesisBlock": 0,
  "faultGameGenesisOutputRoot": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "faultGameSplitDepth": 14
}
EOL
)

echo "$config" > /out/deploy_config.json
cp /out/deploy_config.json /repos/optimism/packages/contracts-bedrock/deploy-config/${L1_CHAINID}.json

PK=$(cast wallet derive-private-key "{{.addresses.admin.mnemonic}}")
forge script scripts/Deploy.s.sol:Deploy --private-key $PK --broadcast --rpc-url {{.l1_rpc_url}} --slow --non-interactive --json
cp deployments/${L1_CHAINID}/.deploy /out/${L1_CHAINID}.deploy
