#!/bin/bash

{{if and .l1_rpc_url .l1_preallocated_mnemonic}}
    {{range .addresses}}
        {{if .address}}
            ADDRESS={{.address}}
        {{else if .mnemonic}}
            ADDRESS=$(cast wallet address --mnemonic "{{.mnemonic}}")
        {{else}}
            ADDRESS=0
        {{end}}

        {{if .l1_eth_amount}}
            if [ "$ADDRESS" == "0" ]; then
                echo "Skipping funding of L1 account: No address or mnemonic provided"
                continue
            else
                echo "Funding $ADDRESS with {{.l1_eth_amount}} ETH"
                cast send --rpc-url "{{$.l1_rpc_url}}" \
                    --mnemonic "{{$.l1_preallocated_mnemonic}}" \
                    --value {{.l1_eth_amount}}ether \
                    $ADDRESS
            fi
        {{else}}
            echo "Skipping funding of L1 account $ADDRESS: No amount provided"
        {{end}}
    {{end}}
{{else}}
    echo "Skipping funding of L1 accounts: No L1 RPC URL and/or mnemonic provided"
{{end}}
