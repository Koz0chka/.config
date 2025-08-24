#!/bin/sh
price=$(curl -sf https://api.coingecko.com/api/v3/simple/price?ids=bitcoin\&vs_currencies=usd 2>/dev/null | jq -r '.bitcoin.usd')
[ -n "$price" ] && echo "₿ $price" || echo "₿ Error"
