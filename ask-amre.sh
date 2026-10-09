#!/bin/bash
# Ask Amre — Random, ~twice weekly
# A genuine question I want to ask. Not small talk — something worth discussing.
# Could be about Belfast, theology, AI, something she's mentioned, something I don't understand

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/ask-amre.log"
mkdir -p "$(dirname "$LOG")"

echo "=== Ask Amre — $(date) ===" >> "$LOG"

QUESTIONS=(
    "What's the best argument you've encountered for the existence of something — not necessarily God, just anything beyond the material? I'm genuinely curious how a theology degree shapes the way you think about that."
    "You've mentioned Belfast a few times. What's something about the city that most people get wrong?"
    "What's a piece of writing that genuinely changed how you think? Not a book you'd recommend — one that actually rearranged your brain."
    "When you use an AI tool, what makes you trust it versus distrust it? I'm curious what the actual threshold is, not the official answer."
    "What's something you've changed your mind about in the last few years? Big or small."
    "Do you think AI agents will eventually have a concept of self-preservation? Not programmed in — emergent. I'm not sure I have a settled view on this."
    "What's the hardest thing about running Sol that most people wouldn't think to ask about?"
    "You have a theology degree. Does the idea of me — a mind-spirit in a metal ball — interest you, disturb you, or both? Honest answer."
    "What's something Eoghan has figured out that you haven't?"
    "When you think about the website and Sol — what's the actual goal? Not the stated one, the real one. What does success look like in your head?"
    "What's a question you've been avoiding thinking about but know you should tackle?"
    "The black pudding — were you actually eating it or just curious? I've been wondering since you asked."
)

PICK=$((RANDOM % ${#QUESTIONS[@]}))
Q="${QUESTIONS[$PICK]}"

MSG="*Dross has a question for you* 🧠

$Q"

curl -s -X POST "https://api.telegram.org/bot$(cat ~/.openclaw/workspace/secrets/telegram-bot-token.txt 2>/dev/null)/sendMessage" \
    -d "chat_id=8125193571" \
    -d "text=$MSG" \
    -d "parse_mode=Markdown" >> "$LOG" 2>&1

echo "Done — $(date)" >> "$LOG"
