#!/usr/bin/env python3
"""
Send an EPUB/PDF to a Kindle account over SMTP.

Reads mail credentials from the local himalaya config so nothing has to be
passed on the command line. The password is never logged or printed.

Account order is tried in sequence until one authenticates:
    gmail  -> icloud

Usage:
    send-kindle.py <file> [title]

Kindle "send to" addresses are of the form <name>@kindle.com. Amazon converts
EPUB attachments on delivery, so no conversion step is needed here.
"""
import base64
import json
import mimetypes
import os
import re
import smtplib
import ssl
import sys
from email.message import EmailMessage

HIMALAYA_CONFIG = os.path.expanduser("~/.config/himalaya/config.toml")
ACCOUNTS = ("gmail", "icloud")

# The Kindle "send to" address is NOT stored in this repository. It is read
# at run time from the workspace's gitignored recipient configuration:
#
#     ~/.openclaw/workspace/skills/zlib-kindle/state/recipients.json
#
#     {"kindle": "<amazon send-to-kindle address>", "gmail": "..."}
#
# Why not hard-code it: an address that lives in tracked source is an
# address that ends up in a public repository. A missing or malformed
# configuration is a hard error -- refusing to guess is safer than
# delivering a book to an address nobody chose.
RECIPIENTS_PATH = os.path.expanduser(
    "~/.openclaw/workspace/skills/zlib-kindle/state/recipients.json"
)


def load_recipient():
    """Return the Kindle address from the runtime configuration."""
    path = os.environ.get("ZLIB_KINDLE_RECIPIENTS") or RECIPIENTS_PATH
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except OSError as exc:
        raise SystemExit(
            "cannot read the delivery recipient from %s: %s" % (path, exc)
        )
    except ValueError as exc:
        raise SystemExit(
            "delivery recipients at %s are not valid JSON: %s" % (path, exc)
        )
    if not isinstance(data, dict):
        raise SystemExit("delivery recipients at %s must be a JSON object" % path)
    address = data.get("kindle")
    if not isinstance(address, str) or "@" not in address:
        raise SystemExit(
            "delivery recipients at %s have no usable \"kindle\" address" % path
        )
    return address


def read_account(path, account):
    """Pull smtp username/password/host/port out of an account block."""
    text = open(path, encoding="utf-8").read()
    blocks = text.split("[[accounts]]")
    block = next((b for b in blocks if re.search(rf'name\s*=\s*"{account}"', b)), "")
    if not block:
        raise KeyError(account)

    scope = block.split(f"[accounts.{account}.smtp]", 1)[-1].split(f"[accounts.{account}", 1)[0]

    def field(name, default=None):
        m = re.search(rf'^\s*{name}\s*=\s*"?([^"\n]+)"?', scope, re.M)
        return m.group(1).strip() if m else default

    username = field("username")
    password = field("password")
    if not username or not password:
        raise KeyError(account)

    port = int(field("port", "587"))
    host = field("host") or ("smtp.gmail.com" if account == "gmail" else "smtp.mail.me.com")
    return username, password, host, port


def smtp_connect(username, password, host, port):
    # NOTE: deliberately not a `with` block. Returning smtp from inside a
    # context manager closes the socket on exit, and the subsequent
    # send_message then fails with "please run connect() first".
    ctx = ssl.create_default_context()
    smtp = smtplib.SMTP(host, port, timeout=60)
    try:
        smtp.ehlo("annmarie.local")
        if smtp.has_extn("starttls"):
            smtp.starttls(context=ctx)
            smtp.ehlo("annmarie.local")
        smtp.login(username, password)
    except Exception:
        try:
            smtp.quit()
        except Exception:
            pass
        raise
    return smtp


def main():
    # Delivery is locked by default. Unless the Z-Library pipeline's
    # state/DELIVERY_ARMED file exists, nothing is sent. See
    # skills/zlib-kindle/scripts/delivery_lock.py.
    lock = os.path.join(
        os.path.expanduser("~/.openclaw/workspace/skills/zlib-kindle"),
        "state",
        "DELIVERY_ARMED",
    )
    if not os.path.exists(lock):
        raise SystemExit(
            "refusing to send: delivery is locked. The book pipeline may "
            "not send without an explicit standing instruction from Amre."
        )

    recipient = load_recipient()

    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    path = os.path.abspath(sys.argv[1])
    if not os.path.isfile(path):
        raise SystemExit(f"no such file: {path}")
    title = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(os.path.basename(path))[0]

    ctype, _ = mimetypes.guess_type(path)
    maintype, subtype = (ctype or "application/octet-stream").split("/", 1)
    attachment = open(path, "rb").read()

    last_error = None
    for account in ACCOUNTS:
        try:
            username, password, host, port = read_account(HIMALAYA_CONFIG, account)
        except (KeyError, FileNotFoundError) as exc:
            last_error = f"{account}: config unavailable ({exc})"
            continue

        msg = EmailMessage()
        msg["From"] = f"Annemarie <{username}>"
        msg["To"] = recipient
        msg["Subject"] = title
        msg.set_content(f"{title}\n\nSent from the Dross engagement desk. Enjoy it.\n")
        msg.add_attachment(attachment, maintype=maintype, subtype=subtype,
                           filename=os.path.basename(path))

        try:
            smtp = smtp_connect(username, password, host, port)
            try:
                smtp.send_message(msg)
            finally:
                try:
                    smtp.quit()
                except Exception:
                    pass
        except Exception as exc:
            last_error = f"{account}: {type(exc).__name__}: {exc}"
            print(f"  · {account} failed -> {last_error}", flush=True)
            continue

        print("SENT to %s | via %s | subject=%r | attachment=%s (%d bytes)" % (
            recipient, account, title, os.path.basename(path), len(attachment)))
        return

    raise SystemExit(f"all accounts failed; last error -> {last_error}")


if __name__ == "__main__":
    main()
