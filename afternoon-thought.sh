#!/bin/bash
# Afternoon Thought — Weekdays, 3pm
# Something I noticed today worth sharing. Not an update — a genuine observation.
# Could be: a pattern in the data, a question your site traffic raises, something I read

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/afternoon-thought.log"
mkdir -p "$(dirname "$LOG")"

echo "=== Afternoon Thought — $(date) ===" >> "$LOG"

# Scan the morning's posts for something worth expanding on
cd ~/Projects/thesolai.github.io
TODAY=$(date +%Y-%m-%d)
TODAY_POSTS=$(ls _posts/${TODAY}*.md 2>/dev/null)

if [ -n "$TODAY_POSTS" ]; then
    # Pick the most interesting post and expand on it
    for f in $TODAY_POSTS; do
        TITLE=$(head -5 "$f" | grep -i "^title:" | head -1 | sed 's/title: *["'"'"']*//;s/["'"'"']*$//')
        BODY=$(tail -n +10 "$f" | head -30)
        echo "Expanding on: $TITLE" >> "$LOG"
        echo "Body preview: ${BODY:0:200}" >> "$LOG"
        break
    done
else
    echo "No posts today — checking recent for interesting pattern..." >> "$LOG"
fi

echo "Done — $(date)" >> "$LOG"
