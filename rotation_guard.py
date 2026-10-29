#!/usr/bin/env python3
"""Rotation guard for the Friday Horror Book of the Week.

Two jobs, both about not sending the same book twice:

1. never *offer* a book that has already been delivered;
2. record a delivery once it has actually happened.

The delivered-book ledger lives in ``data/delivered-books.txt``, one
``Title|Author`` line per book. It is tracked in git so the rotation
survives a fresh clone, and it was seeded from the AgentMail sent
history — the authoritative record of what actually went to the Kindle
address.

The AgentMail history remains the source of truth. This ledger is a
fast local mirror of it: it keeps the Friday run off the network for
its bookkeeping, and it records the decision *before* the next run
picks a book.

Usage
-----
  rotation_guard.py pick                 print one eligible book (fields joined by |)
  rotation_guard.py eligible             list every eligible book
  rotation_guard.py is-delivered TITLE   exit 0 if already delivered, 1 if not
  rotation_guard.py record TITLE AUTHOR  append to the ledger (idempotent)
  rotation_guard.py list                 show the ledger
"""
from __future__ import annotations

import os
import random
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BOOKS_FILE = os.path.join(HERE, "data", "horror-books.tsv")
DELIVERED_FILE = os.path.join(HERE, "data", "delivered-books.txt")

FIELDS = ("title", "author", "blurb", "query", "gutenberg_id")


def normalise(text: str) -> set:
    """Lowercase word tokens, for order-insensitive title comparison."""
    return set(re.findall(r"[a-z0-9]+", (text or "").lower()))


def same_book(want: str, got: str) -> bool:
    """True when two titles denote the same book.

    Titles vary in punctuation and decoration ("NOS4A2" vs "NOS4A2: A
    Novel"), so token sets are compared as subsets in either
    direction.
    """
    a = normalise(want)
    b = normalise(got)
    if not a or not b:
        return False
    return a == b or a <= b or b <= a


def load_books(path: str | None = None) -> list:
    """Load the rotation list. Blank lines and # comments are skipped."""
    if path is None:
        path = BOOKS_FILE
    books = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = line.split("|")
            parts += [""] * (len(FIELDS) - len(parts))
            books.append(dict(zip(FIELDS, parts[: len(FIELDS)])))
    return books


def load_delivered(path: str | None = None) -> list:
    """Load the delivery ledger as (title, author) pairs."""
    if path is None:
        path = DELIVERED_FILE
    if not os.path.isfile(path):
        return []
    entries = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            title, _, author = line.partition("|")
            entries.append((title.strip(), author.strip()))
    return entries


def is_delivered(title: str, delivered=None) -> bool:
    """True when *title* already appears in the ledger."""
    if delivered is None:
        delivered = load_delivered()
    return any(same_book(title, t) for t, _ in delivered)


def eligible_books(books=None, delivered=None) -> list:
    """The books that have not been delivered yet."""
    if books is None:
        books = load_books()
    if delivered is None:
        delivered = load_delivered()
    return [b for b in books if not is_delivered(b["title"], delivered)]


def pick(books=None, delivered=None, rng=None) -> dict | None:
    """Choose one eligible book at random. None when everything is sent."""
    pool = eligible_books(books, delivered)
    if not pool:
        return None
    chooser = rng or random.SystemRandom()
    return chooser.choice(pool)


def record_delivery(title: str, author: str, path: str | None = None) -> bool:
    """Append a delivery to the ledger. Idempotent.

    Returns True when the entry was added, False when it was already
    there.
    """
    if path is None:
        path = DELIVERED_FILE
    delivered = load_delivered(path)
    if any(same_book(title, t) for t, _ in delivered):
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(f"{title.strip()}|{author.strip()}\n")
    return True


def main(argv) -> int:
    if not argv:
        print(__doc__.strip())
        return 2
    command = argv[0]

    if command == "pick":
        book = pick()
        if book is None:
            print("! every book in the rotation has been delivered", file=sys.stderr)
            return 1
        print("|".join(book[f] for f in FIELDS))
        return 0

    if command == "eligible":
        for book in eligible_books():
            print("|".join(book[f] for f in FIELDS))
        return 0

    if command == "is-delivered":
        if len(argv) < 2:
            print("usage: rotation_guard.py is-delivered TITLE", file=sys.stderr)
            return 2
        return 0 if is_delivered(argv[1]) else 1

    if command == "record":
        if len(argv) < 3:
            print("usage: rotation_guard.py record TITLE AUTHOR", file=sys.stderr)
            return 2
        added = record_delivery(argv[1], argv[2])
        print("recorded" if added else "already recorded")
        return 0

    if command == "list":
        for title, author in load_delivered():
            print(f"{title}|{author}")
        return 0

    print(f"unknown command: {command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
