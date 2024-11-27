#!/bin/bash

OP_BRIDGE_ADDR=$(cat /out/{{.l1_chainid}}.deploy | jq -r .L1StandardBridgeProxy)

{{if .l1_rpc_url}}
    {{range .addresses}}
        {{if .address}}
            ADDRESS={{.address}}
        {{else if .mnemonic}}
            ADDRESS=$(cast wallet address --mnemonic "{{.mnemonic}}")
        {{else}}
            ADDRESS=0
        {{end}}

        {{if .private_key}}
            PK={{.private_key}}
        {{else if .mnemonic}}
            PK=$(cast wallet derive-private-key "{{.mnemonic}}")
        {{else}}
            PK=0
        {{end}}


        {{if and .l2_eth_amount .l1_eth_amount}}
            if [ "$PK" == "0" ]; then
                echo "Skipping funding of L2 account: No private key or mnemonic provided"
                continue
            else
                echo "Funding $ADDRESS with {{.l2_eth_amount}} ETH"
                cast send --rpc-url "{{$.l1_rpc_url}}" \
                    --private-key $PK \
                    --value {{.l2_eth_amount}}ether \
                    $OP_BRIDGE_ADDR
            fi
        {{else}}
            echo "Skipping funding of L2 account $ADDRESS: No amount provided for both L1/L2"
        {{end}}
    {{end}}
{{else}}
    echo "Skipping funding of L2 accounts: No L1 RPC URL provided"
{{end}}
