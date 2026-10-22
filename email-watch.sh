#!/opt/homebrew/bin/bash
# Email Watch — Every 30 minutes
# Checks Sol's inbox for genuinely new messages.
# ALERTS ONLY — never replies.
# Flags important new emails to Amre via stdout (OpenClaw announce handles Telegram).

export PATH="/opt/homebrew/bin:$PATH"

SEEN="/Users/amre/.openclaw/workspace/scripts/engagement/state/seen_email_ids.txt"
mkdir -p "$(dirname "$SEEN")"

/opt/homebrew/bin/python3 << 'PYEOF'
import os
import sys

key_file = '/Users/amre/.openclaw/workspace/secrets/sol-agentmail-api-key.txt'
if not os.path.exists(key_file):
    print("ERROR: sol-agentmail-api-key.txt not found")
    sys.exit(0)

from agentmail import AgentMail
from datetime import datetime, timezone, timedelta

key = open(key_file).read().strip()
client = AgentMail(api_key=key)
inbox = 'sol-ai@agentmail.to'

# Load seen message IDs
seen_ids = set()
seen_file = '/Users/amre/.openclaw/workspace/scripts/engagement/state/seen_email_ids.txt'
if os.path.exists(seen_file):
    with open(seen_file) as f:
        seen_ids = set(line.strip() for line in f if line.strip())

# Get last 72 hours of messages
cutoff = datetime.now(timezone.utc) - timedelta(hours=72)
msgs = client.inboxes.messages.list(inbox, limit=100)

# Senders/subjects that are noise — skip without alerting
noise_patterns = ['dev.to trending', 'sol alexander']

# Senders that matter
important_patterns = ['oddmerit', 'exuvia', 'aurelius']

new_important = []
new_seen = set(seen_ids)

for m in msgs.messages:
    if not m.subject or not m.message_id:
        continue

    msg_id = str(m.message_id)
    if msg_id in seen_ids:
        continue

    subj_lower = m.subject.lower()
    from_lower = (m.from_ or '').lower()
    is_noise = any(p in subj_lower or p in from_lower for p in noise_patterns)
    if is_noise:
        new_seen.add(msg_id)
        continue

    if m.timestamp and m.timestamp < cutoff:
        new_seen.add(msg_id)
        continue

    is_important = any(p in from_lower or p in subj_lower for p in important_patterns)

    if is_important:
        new_important.append({
            'from': m.from_,
            'subject': m.subject,
            'date': str(m.timestamp),
            'preview': m.preview[:200] if m.preview else ''
        })

    new_seen.add(msg_id)

# Save seen IDs
with open(seen_file, 'w') as f:
    for mid in sorted(new_seen, reverse=True)[:200]:
        f.write(mid + '\n')

# Output alert — OpenClaw announce system delivers to Telegram
if new_important:
    lines = ["📧 New email — don't reply yet"]
    for item in new_important:
        lines.append(f"\nFrom: {item['from']}")
        lines.append(f"Subj: {item['subject']}")
        if item['preview']:
            lines.append(f"Preview: {item['preview']}")
    lines.append("\n---\nReply to this message if you want me to respond.")
    print('\n'.join(lines))
PYEOF
