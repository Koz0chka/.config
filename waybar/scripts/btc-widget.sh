PRICE_SCRIPT="$HOME/.config/waybar/scripts/btc-price.sh"
BALANCE_SCRIPT="$HOME/.config/waybar/scripts/btc-balance.sh"

STATE_FILE="$HOME/.config/waybar/btc-widget-state"

if [ ! -f "$STATE_FILE" ]; then
    echo "price" > "$STATE_FILE"
fi

current_state=$(cat "$STATE_FILE")

if [ "$1" = "toggle" ]; then
    if [ "$current_state" = "price" ]; then
        echo "balance" > "$STATE_FILE"
        current_state="balance"
    else
        echo "price" > "$STATE_FILE"
        current_state="price"
    fi
fi

if [ "$current_state" = "price" ]; then
    exec "$PRICE_SCRIPT"
else
    exec "$BALANCE_SCRIPT"
fi
