#!/bin/bash
# Morning Brew — Daily, 9am
# Something worth knowing to start the day — a new post, a site insight, a heads-up

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/morning-brew.log"
mkdir -p "$(dirname "$LOG")"

echo "=== Morning Brew — $(date) ===" >> "$LOG"

# Check what's been published
cd ~/Projects/thesolai.github.io
LAST_POST=$(ls -t _posts/*.md 2>/dev/null | head -1)
if [ -n "$LAST_POST" ]; then
    DATE=$(echo "$LAST_POST" | sed 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*/\1/' | tr '-' '/')
    TITLE=$(head -5 "$LAST_POST" 2>/dev/null | grep -i "^title:" | head -1 | sed "s/title: *['\"]*//;s/['\"]*\$//")
    SLUG=$(echo "$LAST_POST" | sed 's/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-//;s/\.md$//')
    URL="https://thesolai.github.io/blog/$DATE/$SLUG/"
    echo "New post: $TITLE" >> "$LOG"
    echo "URL: $URL" >> "$LOG"
fi

echo "Done — $(date)" >> "$LOG"
