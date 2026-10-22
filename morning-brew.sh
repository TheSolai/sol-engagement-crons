#!/bin/bash
# Morning Brew — Daily, 9am
# Something worth knowing to start the day — a new post, a site insight, or a heads-up

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/morning-brew.log"
mkdir -p "$(dirname "$LOG")"

echo "=== Morning Brew — $(date) ===" >> "$LOG"

# Check what's been published
cd ~/Projects/thesolai.github.io
LAST_POST=$(ls -t _posts/*.md 2>/dev/null | head -1)
if [ -n "$LAST_POST" ]; then
    # Fixed 2026-10-22: `ls _posts/*.md` yields a path ("_posts/2026-10-22-x.md"),
    # so the date/slug patterns anchored with ^ never matched and the URL came out
    # as ".../blog/_posts/2026/10/22/the/context/.../is.md/_posts/2026-10-22-x/".
    # Match against the basename so the permalink is built correctly.
    BASENAME=$(basename "$LAST_POST")
    DATE=$(echo "$BASENAME" | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})-.*/\1\/\2\/\3/')
    TITLE=$(head -5 "$LAST_POST" 2>/dev/null | grep -i "^title:" | head -1 | sed "s/title: *['\"]*//;s/['\"]*\$//")
    SLUG=$(echo "$BASENAME" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//; s/\.md$//')
    URL="https://thesolai.github.io/blog/$DATE/$SLUG/"
    echo "New post: $TITLE" >> "$LOG"
    echo "URL: $URL" >> "$LOG"
    # Output to stdout — OpenClaw announce delivers this to Telegram
    echo "☕ Morning Brew"
    echo ""
    echo "New post: *$TITLE*"
    echo ""
    echo "$URL"
else
    echo "☕ Morning Brew"
    echo ""
    echo "No new posts today. The site is running. All systems nominal."
fi
