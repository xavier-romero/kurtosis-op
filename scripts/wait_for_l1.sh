#!/bin/bash

is_rpc_ready() {
    response=$(cast send --json --legacy --rpc-url {{.l1_rpc_url}} --mnemonic "{{.l1_preallocated_mnemonic}}" --value 0 0x0000000000000000000000000000000000000000)
    status=$(echo $response | jq -r '.status')

    if [[ $status == "0x1" ]]; then
        true
    else
        false
    fi
}

wait_for_rpc_to_be_available() {
    counter=0
    max_retries=30

    until is_rpc_ready; do
        ((counter++))
        echo "Waiting for the L1 RPC to be available"
        if [[ $counter -ge $max_retries ]]; then
            echo "Exceeded maximum retry attempts. Exiting."
            exit 1
        fi
        sleep 5
    done
    echo "L1 RPC is now available"
}

wait_for_rpc_to_be_available
