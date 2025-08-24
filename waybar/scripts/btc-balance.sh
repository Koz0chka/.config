#!/bin/bash

address="${1:-34amqx31SJoz2GdkvLsfRoVN65QuRWMCFG}"

if ! [[ "$address" =~ ^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}$ ]]; then
    echo "₿ Error: Invalid Bitcoin address format"
    exit 1
fi

response=$(curl -sf "https://blockstream.info/api/address/$address")

if [ -z "$response" ]; then
    echo "₿ Error: Connection failed"
    exit 1
fi

balance_sat=$(echo "$response" | jq -r '.chain_stats.funded_txo_sum // empty')

if [ -z "$balance_sat" ]; then
    echo "₿ Error: Invalid response from API"
    exit 1
fi

echo "₿ $(awk -v sat="$balance_sat" 'BEGIN {
    btc = sat / 100000000;
    printf "%.8f\n", btc;
}' | sed -e "s/0*$//" -e "s/\.$//")"
