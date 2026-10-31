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
# attachment -> the Kindle address held in the runtime recipient config.

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

# The announcement is what a human reads on Telegram, so it is bounded
# here, inside the script: a long blurb, an odd title, or a noisy error
# message can never turn this job into a chat flood. Both a line count
# and a character count apply.
MAX_LINES=40
MAX_CHARS=3000

BUFFER=""
LINES=0

# Append one line to the announcement buffer.
say() {
    LINES=$((LINES + 1))
    [ "$LINES" -gt "$MAX_LINES" ] && return 0
    BUFFER="${BUFFER}$1"$'\n'
}

# Print the bounded announcement and exit with the given code.
finish() {
    local code="$1"
    local out="$BUFFER"
    if [ "${#out}" -gt "$MAX_CHARS" ]; then
        out="${out:0:$MAX_CHARS}"
        out="${out%$'\n'*}"$'\n'"[truncated at ${MAX_CHARS} chars]"
    fi
    printf '%s' "$out"
    exit "$code"
}

SEND_TO_KINDLE=0
[ "${1:-}" = "--send" ] && SEND_TO_KINDLE=1

if [ ! -f "$GUARD" ]; then
    say "⚠️  rotation guard not found at ${GUARD} — refusing to pick a book."
    say "    Without the guard there is no record of what was already sent,"
    say "    and a book could be delivered twice."
    finish 1
fi

# Pick from the books that have not been delivered yet.
PICKED=$("$GUARD" pick) || {
    say "⚠️  Every book in the rotation has already been delivered."
    say "    The rotation needs new entries in data/horror-books.tsv."
    finish 1
}
IFS='|' read -r TITLE AUTHOR BLURB ZQUERY GID <<< "$PICKED"

# URL-encode the search query (spaces -> +, keep alphanumerics)
ENCODED=$(printf '%s' "$ZQUERY" | sed -e 's/ /+/g' -e 's/&/%26/g' -e 's/?/%3F/g' -e 's/#/%23/g')
ZLIB_URL="${ZLIB_BASE}${ENCODED}"

say "👻 Horror Book of the Week"
say ""
say "*${TITLE}* by ${AUTHOR}"
say ""
say "${BLURB}"
say ""
say "🔎 Find it:"
say "• Z-Library search: ${ZLIB_URL}"

if [ -n "$GID" ]; then
    # Project Gutenberg is banned as a source (Amre, 2026-10-30): the
    # Gutenberg pipeline sent 22 unwanted 19th-century omnibus
    # compilations and was rejected wholesale. The id is kept in the TSV
    # only as a reference for the announcement; it is never fetched.
    say "• In copyright — library, second-hand, or Kindle Store."
    say "  (Z-Library download needs a signed-in account; see the zlib-kindle skill.)"
else
    say "• In copyright — library, second-hand, or Kindle Store."
    say "  (Z-Library download needs a signed-in account; see the zlib-kindle skill.)"
fi

say ""
say "Worth reading if you want something that actually lingers."

# Optional: download the book and email it to the Kindle address
if [ "$SEND_TO_KINDLE" = "1" ]; then
    say ""
    if [ ! -f "$SKILL_SCRIPT" ]; then
        say "⚠️  zlib-kindle skill not found at ${SKILL_SCRIPT} — not emailed."
    else
        # deliver = Z-Library search -> download -> verify title/author ->
        # AgentMail attachment -> Kindle.
        # Falls back to Project Gutenberg for public-domain titles.
        #
        # The expected title and author are passed through so the file
        # that actually landed on disk is checked against the book that
        # was asked for, not just against the search result.
        # The delivery tool's own stdout can be long (search results, download
        # notes, per-file progress). It goes to a log file, never into the
        # announcement, so this job cannot flood the chat.
        LOG_DIR="${SCRIPT_DIR}/logs"
        mkdir -p "$LOG_DIR"
        DELIVER_LOG="${LOG_DIR}/horror-book-deliver.log"
        if /opt/homebrew/bin/python3 "$SKILL_SCRIPT" deliver "$ZQUERY" \
              --match "$TITLE" --title "${TITLE} by ${AUTHOR}" \
              --expect-title "$TITLE" --expect-author "$AUTHOR" \
              > "${DELIVER_LOG}.tmp" 2>&1; then
            say "📬 Sent to your Kindle."
            # Record the delivery so this book is never offered again.
            "$GUARD" record "$TITLE" "$AUTHOR"
        else
            say "⚠️  Kindle delivery failed — nothing was sent or recorded."
            say "    Details: ${DELIVER_LOG}"
        fi
        mv -f "${DELIVER_LOG}.tmp" "$DELIVER_LOG" 2>/dev/null || true
    fi
fi

finish 0
