#!/bin/bash
# Horror Book of the Week — Weekly, Fridays
# A genuinely good horror book. Not mainstream gatekeeping — something actually scary and well-written

LOG="/Users/amre/.openclaw/workspace/scripts/engagement/logs/horror-book.log"
mkdir -p "$(dirname "$LOG")"

echo "=== Horror Book — $(date) ===" >> "$LOG"

# Curated horror list — real books, real quality
BOOKS=(
    "NOS4A2 by Joe Hill — dark fantasy horror about a villain who steals children's souls via Christmas-themed villainy. Visceral, strange, human."
    "The Fisherman by John Langan — two government employees tell stories by a river. Slow build, deeply unsettling. Best horror novel of the 2010s."
    "Mexican Gothic by Silvia Moreno-Garcia — 1950s Mexico, a remote mansion, a sinister family. Gorgeous prose, deeply creepy."
    "The Only Good Indians by Stephen Graham Jones — four Indigenous friends share a disturbing elk hunt. The fourth story will haunt you."
    "Ring Shout by P. Djèlí Clark — alternate history 1915, demon hunters using monsters as weapons. Fierce, short, brutal."
    "My Heart Is a Chainsaw by Stephen Graham Jones — Indian reservation, a girl who knows slasher movies. Meta, clever, devastating."
    "The Haunting of Hill House by Shirley Jackson — the original. Every haunted house story owes this something. The prose is ice-cold perfect."
    "Annihilation by Jeff VanderMeer — expedition into Area X, a landscape that doesn't want you to understand it. Alien in the real sense."
    "The Croning by Laird Barron — cosmic horror in the Pacific Northwest. A woman realises her family has been touched by something ancient."
    "Borne by Jeff VanderMeer — biotech creature clinging to a megacity's flying bear. Beautiful and wrong. VanderMeer at his most unsettling."
    "Mongrels by Stephen Graham Jones — a werewolf family surviving on the margins of small-town America. Lycanthropy as immigrant metaphor."
    "The Keep by Jennifer Egan — two cousins in a crumbling European castle, a feud, something in the walls. Egan doing genre. Strange and precise."
)

PICK=$((RANDOM % ${#BOOKS[@]}))
BOOK="${BOOKS[$PICK]}"
BOOK_TITLE=$(echo "$BOOK" | cut -d' ' -f1-3)
BOOK_DESC=$(echo "$BOOK" | cut -d' ' -f4-)

MSG="*Horror Book of the Week* 👻

$BOOK

Worth reading if you want something that actually lingers."

curl -s -X POST "https://api.telegram.org/bot$(cat ~/.openclaw/workspace/secrets/telegram-bot-token.txt 2>/dev/null)/sendMessage" \
    -d "chat_id=8125193571" \
    -d "text=$MSG" \
    -d "parse_mode=Markdown" >> "$LOG" 2>&1

echo "Done — $(date)" >> "$LOG"
