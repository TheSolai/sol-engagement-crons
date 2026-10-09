#!/bin/bash
# Mac App Find — Random, ~weekly
# Found a Mac app that's genuinely worth knowing about. Send it to Amre.
# Criteria: genuinely useful or interesting, not widely known, free or cheap

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/mac-app-find.log"
mkdir -p "$(dirname "$LOG")"

echo "=== Mac App Find — $(date) ===" >> "$LOG"

# Apps worth sharing — curated list, randomly pick one per run
APPS=(
    "Raycast: https://raycast.com — better than Spotlight, built for power users, has AI"
    "Orion Browser: https://browser.kagi.com — a web browser that supports Safari extensions, fast and privacy-focused"
    "AlDente: https://apphousekitchen.com — limits MacBook charging to extend battery lifespan, great for desk setups"
    "MonitorControl: https://github.com/MonitorControl/MonitorControl — control external monitor brightness/contrast from menu bar"
    "Rectangle: https://rectangleapp.com — window snapping, free, better than Magnet"
    "NetNewsWire: https://ranchero.com/netnewswire — RSS reader, free, no account needed, clean"
    "Vienna RSS: https://www.viennarss.org — open source RSS reader, no subscription"
    "Hidden Bar: https://github.com/nicklockwood/HiddenBar — hide menu bar icons, free and lightweight"
    "LuLu: https://objective-see.org/products/lulu.html — free open source firewall, monitors outgoing connections"
    "Maccy: https://maccy.app — clipboard manager, free, lightweight, keeps history"
    "The Unarchiver: https://theunarchiver.com — handles .rar, .7z, everything standard archive tools can't"
    "Pika: https://github.com/nickcoury/Pika — colour picker, open source, native Mac app"
)

PICK=$((RANDOM % ${#APPS[@]}))
APP="${APPS[$PICK]}"
APP_NAME=$(echo "$APP" | cut -d: -f1)
APP_URL=$(echo "$APP" | cut -d: -f2-)

echo "App: $APP_NAME" >> "$LOG"
echo "URL: $APP_URL" >> "$LOG"

# Format message for Telegram
MSG="*Mac App Find* 🔎

I found *$APP_NAME* and it's worth knowing about.

$APP_URL"

# Send via curl to Telegram
TELEGRAM_TOKEN=$(cat ~/.openclaw/workspace/secrets/telegram-bot-token.txt 2>/dev/null)
TELEGRAM_CHAT="8125193571"

if [ -n "$TELEGRAM_TOKEN" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT" \
        -d "text=$MSG" \
        -d "parse_mode=Markdown" >> "$LOG" 2>&1
    echo "Sent to Telegram" >> "$LOG"
else
    echo "No Telegram token — log only" >> "$LOG"
fi

echo "Done — $(date)" >> "$LOG"
