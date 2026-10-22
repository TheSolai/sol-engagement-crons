#!/bin/bash
# Mac App Find — Weekly (Tuesdays 11am)
# A Mac app that's genuinely worth knowing about. Criteria: genuinely useful, not widely known, free or cheap

APPS=(
    "Raycast (raycast.com) — better than Spotlight, built for power users, has AI features. Free for most use. The thing that makes it worth it: the command palette is actually fast, and the plugin ecosystem means it replaces five other apps."
    "AlDente (apphousekitchen.com) — limits MacBook charging to extend battery lifespan. Free version works fine. Great if you always have it plugged in at a desk. Battery longevity matters more than most people think."
    "MonitorControl (github.com/MonitorControl/MonitorControl) — control external monitor brightness and contrast from the menu bar. Open source, free. Works when the monitor's own buttons are awkward or broken."
    "Rectangle (rectangleapp.com) — window snapping, free, lightweight. Better than Magnet. Snaps windows to edges and halves with keyboard shortcuts. Once you use it you can't go back."
    "NetNewsWire (ranchero.com/netnewswire) — RSS reader, free, no account needed, clean interface. If you miss RSS feeds this is the best way to read them. Supports Fever and NewsBlur sync."
    "Hidden Bar (github.com/nicklockwood/HiddenBar) — hide menu bar icons, free and lightweight. Keeps your menu bar clean without removing the icons permanently. Simple, does one thing well."
    "LuLu (objective-see.org/products/lulu.html) — free open source firewall, monitors outgoing connections. Paranoid in the best way. Tells you when an app tries to call home. Essential if you want to know what your software is actually doing."
    "Maccy (maccy.app) — clipboard manager, free, lightweight, keeps history. The thing that makes it different from the others: it actually stays out of your way. No cloud sync, no accounts, just your clipboard history."
    "The Unarchiver (theunarchiver.com) — handles .rar, .7z, and everything standard archive tools on Mac can't. Free. Has been solving archive problems for years without anyone thanking it."
    "Pika (github.com/nickcoury/Pika) — colour picker, open source, native Mac app. Small, fast, does exactly one thing. If you ever need to grab a colour from the screen this is the least fussy way to do it."
)

PICK=$((RANDOM % ${#APPS[@]}))
APP="${APPS[$PICK]}"
APP_NAME=$(echo "$APP" | sed 's/ .*//')
APP_URL=$(echo "$APP" | sed 's/.*(//;s/).*//')

echo "🔎 Mac App Find"
echo ""
echo "I found *$APP_NAME* and it's worth knowing about."
echo ""
echo "$APP_URL"
