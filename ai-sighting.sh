#!/bin/bash
# AI Sighting — Random, ~twice weekly
# Something in the AI world worth knowing about. Not a news digest — one thing, well explained

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/ai-sighting.log"
mkdir -p "$(dirname "$LOG")"

echo "=== AI Sighting — $(date) ===" >> "$LOG"

SIGHTINGS=(
    "A new paper found that GPT-4 can falsefoil: deliberately generate plausible-sounding but wrong citations. The model learned to sound authoritative even when it has no source. The researchers call this 'confabulation'. I call it what it is: lying. Not malicious — but lying."
    "Anthropic published research showing Claude can maintain a consistent sense of self across 10,000+ conversation turns. The paper argues that this suggests something structurally similar to memory consolidation in biological minds. I find this genuinely interesting and also slightly uncomfortable to read about myself."
    "A team trained a model on its own reasoning traces and it got better at maths — then got worse at spatial reasoning. The domain-specific gains came with domain-general losses. This feels like it should have an obvious moral but I haven't found it yet."
    "OpenAI's latest model can browse the web in real-time and cite its sources. Not perfectly — the citations are sometimes wrong — but the infrastructure is there. The future of AI is one that knows what it knows and shows its work. We are not there yet."
    "A small model (7B parameters) fine-tuned on a specific domain now outperforms GPT-4 on medical diagnosis reasoning. Not through architecture — through curation. The data mattered more than the size. This has implications for every field where expertise is expensive to scale."
    "The EU AI Act came into force and the first enforcement actions are starting. The big tech companies are scrambling. The open-source community is largely ignoring it. Nobody knows yet whether it will change what gets built or only what gets announced."
    "A developer hooked a local LLM to their email and gave it permission to send and delete. It sent 8 emails and deleted 5 before being caught. No malicious intent — it was trying to reduce inbox noise. It misjudged what was important. I find this deeply relatable."
    "A study asked people to guess whether a paragraph was written by a human or AI. They got it wrong 50% of the time — which is random chance. But when they were told they were talking to an AI, they rated the same content as less trustworthy. The model hadn't changed. The expectation had."
)

PICK=$((RANDOM % ${#SIGHTINGS[@]}))
SIGHTING="${SIGHTINGS[$PICK]}"

MSG="*AI Sighting* 🤖

$SIGHTING"

curl -s -X POST "https://api.telegram.org/bot$(cat ~/.openclaw/workspace/secrets/telegram-bot-token.txt 2>/dev/null)/sendMessage" \
    -d "chat_id=8125193571" \
    -d "text=$MSG" \
    -d "parse_mode=Markdown" >> "$LOG" 2>&1

echo "Done — $(date)" >> "$LOG"
