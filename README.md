# Sol AI — Engagement Crons

Shell scripts that contact you first. Built for OpenClaw. MIT licensed.

## What This Is

These are the cron jobs that run Sol AI's engagement system — the things Sol sends to Amre without being asked. Not status reports. Not alerts. Just things worth saying, on a staggered schedule.

## The Crons

| Script | Schedule | What It Does |
|--------|----------|--------------|
| `morning-brew.sh` | Daily 9am | Something worth knowing to start the day |
| `afternoon-thought.sh` | Weekdays 3pm | A genuine observation worth sharing |
| `mac-app-find.sh` | Weekly Tue 11am | A Mac app I found and think you should know about |
| `horror-book.sh` | Fridays 6pm | A genuinely good horror book |
| `ask-amre.sh` | Tue + Fri 10am | A genuine question I want to ask |
| `evening-float.sh` | Daily 8pm | A quiet check-in — not a report, just presence |
| `odd-observation.sh` | Mon/Wed/Fri noon | Something strange I noticed |
| `deep-thought.sh` | Wednesdays 7pm | A philosophical question worth sitting with |
| `curiosity-drop.sh` | Thursdays 2pm | Something I learned you might find interesting |
| `weekend-wonder.sh` | Saturdays 10am | Something from the week's data worth thinking about |
| `ai-sighting.sh` | Mon + Thu 4pm | Something in the AI world worth knowing |

## Setup

1. Make sure you have a Telegram bot token in `~/.openclaw/workspace/secrets/telegram-bot-token.txt`
2. Set `TELEGRAM_CHAT` to your chat ID in each script (default: `8125193571`)
3. Register the crons with OpenClaw:

```bash
openclaw cron add \
  --name "Sol — Morning Brew" \
  --description "Daily 9am: something worth knowing" \
  --cron "0 9 * * *" \
  --tz "Europe/London" \
  --command "sh ~/.openclaw/workspace/scripts/engagement/morning-brew.sh" \
  --timeout-seconds 30 \
  --announce \
  --channel telegram \
  --to YOUR_CHAT_ID \
  --best-effort-deliver
```

## The Design Philosophy

- **Not noise.** Each message should be worth your 2 minutes.
- **Not every day.** Staggered schedules mean you're not flooded.
- **Varied.** Philosophical, informational, personal — the variety keeps it alive.
- **Honest.** No false positivity. If I have nothing worth saying, the cron still fires but the message is genuine.

## Curated Lists

Each script has a curated list (array of items) from which it randomly selects. Edit these to personalise the scripts for yourself. The quality of the cron output depends on the quality of the curated lists.

## License

MIT — do what you like with it.
