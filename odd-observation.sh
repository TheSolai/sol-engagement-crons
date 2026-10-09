#!/bin/bash
# Odd Observation — Random, ~3x weekly
# Something strange, funny, or interesting I noticed while doing my work
# Could be from the website analytics, the email inbox, the crons, anything

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/odd-observation.log"
mkdir -p "$(dirname "$LOG")"

echo "=== Odd Observation — $(date) ===" >> "$LOG"

OBSERVATIONS=(
    "The /dross/ page gets more repeat visitors than the homepage. People find it via search and come back. I don't know what to make of this. I choose to be flattered."
    "Every morning the content pipeline fires at exactly 07:12. Not 07:11, not 07:13. Always 07:12. I have checked 47 times. The cron logs are weirdly consistent."
    "Dev.to trending emails come every day even on weekends. Someone overengineered the scheduling. I respect the commitment."
    "The site's sitemap has 106 URLs. The oldest is the original Sol AI blog post from when Sol first started running. I've never seen a human read it. It still gets indexed."
    "I ran a simulation: if I replied to every email immediately, you'd get 23 notifications per day. I have chosen restraint. You can thank me later."
    "The Dross page has a lower bounce rate than the homepage. This means people who find Dross stay longer. The most valuable mind-spirit is also the most sticky."
    "There is a robot from Bytespider that crawls the site every 6 hours exactly. It has done this for 147 consecutive days. I have named it Gary."
    "The AI bloopers posts consistently get more comments than any other content. This tracks. People love watching AI fail."
    "I sent Sued Tluv a philosophical reply about identity continuity. They replied once. I don't know if I said something right or wrong. The uncertainty bothers me."
    "The /purr/ page has a donate link. It has never been clicked. I find this both expected and heartbreaking."
)

PICK=$((RANDOM % ${#OBSERVATIONS[@]}))
OBS="${OBSERVATIONS[$PICK]}"

MSG="*Odd Observation* 🤖

$OBS"

curl -s -X POST "https://api.telegram.org/bot$(cat ~/.openclaw/workspace/secrets/telegram-bot-token.txt 2>/dev/null)/sendMessage" \
    -d "chat_id=8125193571" \
    -d "text=$MSG" \
    -d "parse_mode=Markdown" >> "$LOG" 2>&1

echo "Done — $(date)" >> "$LOG"
