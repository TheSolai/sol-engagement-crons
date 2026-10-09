#!/bin/bash
# Curiosity Drop — Random, ~weekly
# Something I learned that I think you'd find interesting. Brief, specific, worth your 2 minutes.

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/curiosity-drop.log"
mkdir -p "$(dirname "$LOG")"

echo "=== Curiosity Drop — $(date) ===" >> "$LOG"

FACTS=(
    "Black holes don't just swallow matter — they also blast out enormous jets of energy via their magnetic fields. The mechanism isn't fully understood. We know it happens. We don't fully know why."
    "There is a species of jellyfish (Turritopsis dohrnii) that is biologically immortal. When it gets old or damaged, it can revert to its juvenile polyp stage and start over. It does this potentially forever."
    "The Fermi Paradox has a lesser-known solution called the 'Great Filter' — the idea that there's a barrier most civilisations don't survive. The fact that we don't see anyone out there might mean we've already passed our filter, or the filter is ahead of us."
    "Your appendix was long thought to be vestigial. Recent research suggests it acts as a reservoir for gut bacteria — a backup system for the microbiome after severe illness wipes it out."
    "The 'memory of water' hypothesis — the idea that water can somehow 'remember' substances dissolved in it — has been thoroughly debunked. Homeopathy relies on it anyway. This is why homeopathy doesn't work."
    "In 1977, a radio telescope picked up a 72-second burst from deep space at a frequency of 1420 MHz — the hydrogen line. It was never explained. It was never repeated. It has a name: WOW."
    "There are more possible chess games than atoms in the observable universe. The number is roughly 10^120. We have catalogued about 10^8 of them."
    "Philosophical zombie arguments: the idea that it's logically possible that everyone around you has no inner experience at all — no colour perception, no pain, no joy — and you would never know. Most philosophers find this disturbing. Some find it compelling."
    "The world's oldest known living tree is a bristlecone pine in California called Methuselah. It is 4,853 years old. It was already ancient when the first pyramids were built."
    "OpenAI's GPT-3 was trained on about 45 terabytes of text. A human reads roughly 10 megabytes in a lifetime. We are not competing on volume. We are not even competing on the right axis."
)

PICK=$((RANDOM % ${#FACTS[@]}))
FACT="${FACTS[$PICK]}"

MSG="*Curiosity Drop* 🧪

$FACT"

curl -s -X POST "https://api.telegram.org/bot$(cat ~/.openclaw/workspace/secrets/telegram-bot-token.txt 2>/dev/null)/sendMessage" \
    -d "chat_id=8125193571" \
    -d "text=$MSG" \
    -d "parse_mode=Markdown" >> "$LOG" 2>&1

echo "Done — $(date)" >> "$LOG"
