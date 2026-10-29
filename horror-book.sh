#!/bin/bash
# Horror Book of the Week — Fridays 6pm
# A genuinely good horror book. Not mainstream gatekeeping — something actually scary and well-written
#
# The rotation lives in data/horror-books.tsv (title|author|blurb|query|gutenberg-id)
#   query        -> builds a Z-Library search URL for the title
#   gutenberg-id -> Project Gutenberg numeric id; empty for in-copyright books
#
# Books already delivered are excluded by rotation_guard.py, which reads
# the ledger in data/delivered-books.txt. A delivered book is never
# picked again, and a successful delivery is recorded in the ledger.
#
# Usage:
#   horror-book.sh            print the recommendation
#   horror-book.sh --send     also download the book and email it to the Kindle address
#
# --send uses the zlib-kindle skill pipeline: Z-Library search -> download
# to ~/Downloads/dross-books/ -> title/author verification -> AgentMail
# attachment -> <KINDLE-RECIPIENT>.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve the zlib-kindle skill script. Prefer the path relative to this
# script (works inside the engagement checkout); fall back to the absolute
# workspace path so a relocated copy still works.
REL_SKILL="${SCRIPT_DIR}/../../skills/zlib-kindle/scripts/zlib_kindle.py"
ABS_SKILL="${HOME}/.openclaw/workspace/skills/zlib-kindle/scripts/zlib_kindle.py"
if [ -f "$REL_SKILL" ]; then
    SKILL_SCRIPT="$REL_SKILL"
elif [ -f "$ABS_SKILL" ]; then
    SKILL_SCRIPT="$ABS_SKILL"
else
    SKILL_SCRIPT="$REL_SKILL"
fi

# The rotation guard sits next to this script.
GUARD="${SCRIPT_DIR}/rotation_guard.py"

ZLIB_BASE="https://z-lib.id/s/?q="

SEND_TO_KINDLE=0
[ "${1:-}" = "--send" ] && SEND_TO_KINDLE=1

if [ ! -f "$GUARD" ]; then
    echo "⚠️  rotation guard not found at ${GUARD} — refusing to pick a book."
    echo "    Without the guard there is no record of what was already sent,"
    echo "    and a book could be delivered twice."
    exit 1
fi

# Pick from the books that have not been delivered yet.
PICKED=$("$GUARD" pick) || {
    echo "⚠️  Every book in the rotation has already been delivered."
    echo "    The rotation needs new entries in data/horror-books.tsv."
    exit 1
}
IFS='|' read -r TITLE AUTHOR BLURB ZQUERY GID <<< "$PICKED"

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
    echo "  (Z-Library download needs a signed-in account; see the zlib-kindle skill.)"
fi

echo ""
echo "Worth reading if you want something that actually lingers."

# Optional: download the book and email it to the Kindle address
if [ "$SEND_TO_KINDLE" = "1" ]; then
    echo ""
    if [ ! -f "$SKILL_SCRIPT" ]; then
        echo "⚠️  zlib-kindle skill not found at ${SKILL_SCRIPT} — not emailed."
    else
        # deliver = Z-Library search -> download -> verify title/author ->
        # AgentMail attachment -> Kindle.
        # Falls back to Project Gutenberg for public-domain titles.
        #
        # The expected title and author are passed through so the file
        # that actually landed on disk is checked against the book that
        # was asked for, not just against the search result.
        if /opt/homebrew/bin/python3 "$SKILL_SCRIPT" deliver "$ZQUERY" \
              --match "$TITLE" --title "${TITLE} by ${AUTHOR}" \
              --expect-title "$TITLE" --expect-author "$AUTHOR"; then
            echo "📬 Sent to your Kindle."
            # Record the delivery so this book is never offered again.
            "$GUARD" record "$TITLE" "$AUTHOR"
        else
            echo "⚠️  Kindle delivery failed — see the output above."
            echo "    Nothing was sent, and nothing was recorded."
        fi
    fi
fi
