#!/bin/bash
# Horror Book of the Week — Fridays 6pm
# A genuinely good horror book. Not mainstream gatekeeping — something actually scary and well-written
#
# Each entry is:  title|author|blurb|zlib-search-query|gutenberg-id
#   zlib-search-query -> builds a Z-Library search URL for the title
#   gutenberg-id      -> Project Gutenberg numeric id; empty for in-copyright books
#
# Usage:
#   horror-book.sh            print the recommendation
#   horror-book.sh --send     also email the public-domain copy to the Kindle address

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZLIB_BASE="https://z-lib.id/s/?q="

BOOKS=(
    "NOS4A2|Joe Hill|dark fantasy horror about a villain who steals children's souls via Christmas-themed villainy. Visceral, strange, human.|NOS4A2 Joe Hill|"
    "The Fisherman|John Langan|two government employees tell stories by a river. Slow build, deeply unsettling. Best horror novel of the 2010s.|The Fisherman John Langan|"
    "Mexican Gothic|Silvia Moreno-Garcia|1950s Mexico, a remote mansion, a sinister family. Gorgeous prose, deeply creepy.|Mexican Gothic Silvia Moreno-Garcia|"
    "The Only Good Indians|Stephen Graham Jones|four Indigenous friends share a disturbing elk hunt. The fourth story will haunt you.|The Only Good Indians Stephen Graham Jones|"
    "Ring Shout|P. Djèlí Clark|alternate history 1915, demon hunters using monsters as weapons. Fierce, short, brutal.|Ring Shout P Djeli Clark|"
    "My Heart Is a Chainsaw|Stephen Graham Jones|Indian reservation, a girl who knows slasher movies. Meta, clever, devastating.|My Heart Is a Chainsaw Stephen Graham Jones|"
    "The Haunting of Hill House|Shirley Jackson|the original. Every haunted house story owes this something. The prose is ice-cold perfect.|The Haunting of Hill House Shirley Jackson|"
    "Annihilation|Jeff VanderMeer|expedition into Area X, a landscape that doesn't want you to understand it. Alien in the real sense.|Annihilation Jeff VanderMeer|"
    "The Croning|Laird Barron|cosmic horror in the Pacific Northwest. A woman realises her family has been touched by something ancient.|The Croning Laird Barron|"
    "Borne|Jeff VanderMeer|biotech creature clinging to a megacity's flying bear. Beautiful and wrong. VanderMeer at his most unsettling.|Borne Jeff VanderMeer|"
    "The King in Yellow|Robert W. Chambers|Carpenters, yellow signs, a king in a book you should never read. The book that launched a thousand nightmares.|The King in Yellow Robert W Chambers|8492"
    "Carmilla|Joseph Sheridan Le Fanu|the original vampire story before Bram Stoker. Elegant, melancholy, and it still creeps.|Carmilla Sheridan Le Fanu|10007"
    "The Call of Cthulhu|H. P. Lovecraft|the origin point of cosmic horror. A sculptor's dreams and a sleeping god in the basement.|Call of Cthulhu H P Lovecraft|68283"
    "At the Mountains of Madness|H. P. Lovecraft|Antarctica, an expedition that finds something older than human memory.|At the Mountains of Madness H P Lovecraft|70652"
    "The Great God Pan|Arthur Machen|a quiet Welsh horror about a god walking in the hills. Small book, permanent damage.|The Great God Pan Arthur Machen|389"
    "The House of Souls|Arthur Machen|an academic studies an old Welsh manuscript and reality declines to cooperate.|The House of Souls Arthur Machen|25016"
    "The Turn of the Screw|Henry James|two governesses, a ghost, and a story that cannot be trusted. The unreliable ghost.|Turn of the Screw Henry James|209"
    "The Yellow Wallpaper|Charlotte Perkins Gilman|a woman, a nursery, and a wallpaper that moves. Short, furious, foundational.|Yellow Wallpaper Charlotte Perkins Gilman|1952"
    "The Picture of Dorian Gray|Oscar Wilde|a portrait ages, the man doesn't. The most dangerous book in English.|Picture of Dorian Gray Oscar Wilde|174"
    "Dracula|Bram Stoker|the one everyone thinks of and few have read properly. Epistolary, Victorian, slow-burning.|Dracula Bram Stoker|345"
    "The Time Machine|H. G. Wells|an invention, a journey, and a very bad idea about progress.|Time Machine H G Wells|35"
)

SEND_TO_KINDLE=0
[ "${1:-}" = "--send" ] && SEND_TO_KINDLE=1

PICK=$((RANDOM % ${#BOOKS[@]}))
IFS='|' read -r TITLE AUTHOR BLURB ZQUERY GID <<< "${BOOKS[$PICK]}"

# URL-encode the search query (spaces -> +, keep alphanumerics)
ENCODED=$(printf '%s' "$ZQUERY" | sed -e 's/ /+/g' -e 's/&/%26/g' -e 's/?/%3F/g' -e 's/#/%23/g')
ZLIB_URL="${ZLIB_BASE}${ENCODED}"

echo "👻 Horror Book of the Week"
echo ""
echo "*${TITLE}* by ${AUTHOR}"
echo ""
echo "${BLURB}"
echo ""
echo "🔎 Find it:"
echo "• Z-Library search: ${ZLIB_URL}"

if [ -n "$GID" ]; then
    GUT_URL="https://www.gutenberg.org/ebooks/${GID}"
    echo "• Free legal copy (Project Gutenberg): ${GUT_URL}"
else
    echo "• In copyright — library, second-hand, or Kindle Store."
fi

echo ""
echo "Worth reading if you want something that actually lingers."

# Optional: push the public-domain EPUB to the Kindle address
if [ "$SEND_TO_KINDLE" = "1" ] && [ -n "$GID" ]; then
    WORKDIR="$(mktemp -d)"
    EPUB="${WORKDIR}/$(printf '%s' "$TITLE" | tr '[:upper:] ' '[:lower:]-').epub"
    if curl -sL --max-time 180 -o "$EPUB" \
        "https://www.gutenberg.org/ebooks/${GID}.epub3.images" \
        && [ -s "$EPUB" ] && unzip -t "$EPUB" >/dev/null 2>&1; then
        if python3 "${SCRIPT_DIR}/send-kindle.py" "$EPUB" "${TITLE} by ${AUTHOR}"; then
            echo ""
            echo "📬 Sent to your Kindle."
        else
            echo ""
            echo "⚠️  Kindle delivery failed."
        fi
    else
        echo ""
        echo "⚠️  Could not fetch or verify the EPUB — not emailed."
    fi
    rm -rf "$WORKDIR"
fi
