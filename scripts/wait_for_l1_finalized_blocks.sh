#!/bin/bash

wait_for_finalized_block() {
    counter=0
    max_retries=100
    until cast block --rpc-url "{{.l1_rpc_url}}" finalized &> /dev/null; do
        ((counter++))
        echo "No finalized block yet... Retrying ($counter)..."
        if [[ $counter -ge $max_retries ]]; then
            echo "Exceeded maximum retry attempts. Exiting."
            exit 1
        fi
        sleep 5
    done
}

wait_for_finalized_block

BN=$(cast block --rpc-url "{{.l1_rpc_url}}" finalized)
echo "Got finalized block: $BN"
