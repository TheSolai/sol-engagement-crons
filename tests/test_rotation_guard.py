#!/usr/bin/env python3
"""Tests for the Friday rotation guard and the book metadata reader.

Run: python3 tests/test_rotation_guard.py

Two things are guarded here, and both have bitten before:

* duplicate delivery — a book must never be picked twice, so the
  rotation excludes everything in the delivered ledger;
* wrong-file delivery — a downloaded file must actually be the book
  that was asked for, so the metadata reader has to recover the title
  from MOBI/AZW3 as well as EPUB.

The tests build their own fixtures rather than relying on the files in
~/Downloads, so they run anywhere and cannot be broken by a cleanup.
"""
from __future__ import annotations

import os
import struct
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)
sys.path.insert(0, os.path.join(
    os.path.expanduser("~"), ".openclaw", "workspace", "skills", "zlib-kindle", "scripts"))

import rotation_guard  # noqa: E402
import bookmeta  # noqa: E402


# --------------------------------------------------------------------------
# Fixtures
# --------------------------------------------------------------------------
def make_epub(title: str, author: str) -> str:
    """A minimal but valid EPUB with OPF metadata."""
    path = tempfile.mktemp(suffix=".epub")
    opf = f"""<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>{title}</dc:title>
    <dc:creator opf:role="aut" opf:file-as="X, Y">{author}</dc:creator>
  </metadata>
</package>"""
    import zipfile

    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr("mimetype", "application/epub+zip")
        zf.writestr("OEBPS/content.opf", opf)
    return path


def _palmdb_header(name: str, magic: bytes) -> bytes:
    """A 76-byte PalmDB header, up to but excluding the record count.

    The type/creator fields at offset 60 are what the format sniffer
    reads: "BOOKMOBI" for a MOBI, "TPZ3" for an AZW3. The record count
    lives at offset 76 and the record list starts at 78.
    """
    head = bytearray(76)
    raw = name.encode("utf-8")[:31]
    head[0:len(raw)] = raw
    head[60:60 + len(magic)] = magic
    return bytes(head)


def _exth_block(records: list) -> bytes:
    """An EXTH block. Each record length counts its own 8-byte header."""
    body = b""
    for rec_type, value in records:
        raw = value.encode("utf-8")
        body += struct.pack(">II", rec_type, len(raw) + 8) + raw
    return b"EXTH" + struct.pack(">II", 12 + len(body), len(records)) + body


def make_palmdb_book(title: str, author: str, magic: bytes = b"BOOKMOBI",
                     with_exth: bool = True, suffix: str = ".mobi") -> str:
    """A genuine PalmDB/MOBI container with real metadata.

    Built to the same layout as the files this pipeline actually
    receives: a PalmDB header, one record holding the 16-byte PalmDOC
    header, the MOBI header, an optional EXTH block, and the internal
    full-name string.
    """
    path = tempfile.mktemp(suffix=suffix)
    exth = _exth_block([(503, title), (100, author)]) if with_exth else b""
    fullname = f"{author} - {title}".encode("utf-8")
    mobi_header_len = 264

    # record 0 = PalmDOC header (16) + MOBI header (264) + EXTH + name
    record = bytearray()
    record += struct.pack(">HHII", 1, 0, 6, 6)  # PalmDOC header
    record += b"\x00" * 8
    mo = len(record)                            # MOBI header starts here
    record += b"MOBI"
    record += struct.pack(">I", mobi_header_len)
    record += b"\x00" * (mobi_header_len - 8)
    # full name offset (relative to record 0) and its length
    fullname_offset = mo + mobi_header_len + len(exth)
    record[mo + 0x44:mo + 0x48] = struct.pack(">I", fullname_offset)
    record[mo + 0x48:mo + 0x4C] = struct.pack(">I", len(fullname))
    record[mo + 0x70:mo + 0x74] = struct.pack(">I", 0x40 if with_exth else 0)
    record += exth
    record += b"\x00"                                    # separator
    record += fullname
    record += b"\x00" * 16

    header = _palmdb_header(title, magic)
    record_list_offset = 78
    record0_offset = record_list_offset + 8

    with open(path, "wb") as fh:
        fh.write(header)
        fh.write(struct.pack(">H", 1))                       # record count @76
        fh.write(struct.pack(">I", record0_offset))          # offset @78
        fh.write(b"\x00" * 4)                                # attributes + uid
        fh.write(bytes(record))
    return path


def make_mobi(title: str, author: str) -> str:
    """A MOBI container with EXTH metadata."""
    return make_palmdb_book(title, author, b"BOOKMOBI", True, ".mobi")


def make_azw3(title: str, author: str) -> str:
    """An AZW3 container with EXTH metadata."""
    return make_palmdb_book(title, author, b"TPZ3", True, ".azw3")


class RotationGuardTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.books_path = os.path.join(self.tmp, "books.tsv")
        with open(self.books_path, "w", encoding="utf-8") as fh:
            fh.write("NOS4A2|Joe Hill|blurb|q1|\n")
            fh.write("The Fisherman|John Langan|blurb|q2|\n")
            fh.write("Mexican Gothic|Silvia Moreno-Garcia|blurb|q3|\n")
        self.delivered_path = os.path.join(self.tmp, "delivered.txt")

    def _guard(self):
        """A guard instance bound to the temporary fixture paths."""
        guard = rotation_guard
        original_books = guard.BOOKS_FILE
        original_delivered = guard.DELIVERED_FILE
        guard.BOOKS_FILE = self.books_path
        guard.DELIVERED_FILE = self.delivered_path
        self.addCleanup(setattr, guard, "BOOKS_FILE", original_books)
        self.addCleanup(setattr, guard, "DELIVERED_FILE", original_delivered)
        return guard

    def test_all_books_eligible_when_nothing_delivered(self):
        guard = self._guard()
        self.assertEqual(len(guard.eligible_books()), 3)

    def test_delivered_book_is_excluded(self):
        guard = self._guard()
        guard.record_delivery("NOS4A2", "Joe Hill", self.delivered_path)
        titles = [b["title"] for b in guard.eligible_books()]
        self.assertNotIn("NOS4A2", titles)
        self.assertEqual(len(titles), 2)

    def test_pick_never_returns_a_delivered_book(self):
        guard = self._guard()
        guard.record_delivery("NOS4A2", "Joe Hill", self.delivered_path)
        for _ in range(50):
            book = guard.pick()
            self.assertIsNotNone(book)
            self.assertNotEqual(book["title"], "NOS4A2")

    def test_record_is_idempotent(self):
        guard = self._guard()
        self.assertTrue(guard.record_delivery("NOS4A2", "Joe Hill", self.delivered_path))
        self.assertFalse(guard.record_delivery("NOS4A2", "Joe Hill", self.delivered_path))
        self.assertEqual(len(guard.load_delivered(self.delivered_path)), 1)

    def test_record_does_not_duplicate_across_spelling(self):
        """A title recorded in a different spelling is still the same book."""
        guard = self._guard()
        guard.record_delivery("NOS4A2", "Joe Hill", self.delivered_path)
        self.assertFalse(
            guard.record_delivery("NOS4A2: A Novel", "Joe Hill", self.delivered_path))

    def test_is_delivered_is_case_and_punctuation_insensitive(self):
        guard = self._guard()
        guard.record_delivery("Mexican Gothic", "Silvia Moreno-Garcia", self.delivered_path)
        self.assertTrue(guard.is_delivered("mexican gothic"))
        self.assertTrue(guard.is_delivered("Mexican  Gothic"))
        self.assertFalse(guard.is_delivered("NOS4A2"))

    def test_pick_returns_none_when_rotation_is_exhausted(self):
        guard = self._guard()
        for title, author in (("NOS4A2", "Joe Hill"),
                              ("The Fisherman", "John Langan"),
                              ("Mexican Gothic", "Silvia Moreno-Garcia")):
            guard.record_delivery(title, author, self.delivered_path)
        self.assertIsNone(guard.pick())
        self.assertEqual(guard.eligible_books(), [])

    def test_real_ledger_excludes_the_six_delivered_books(self):
        """The committed ledger must hold the six books already sent."""
        ledger = os.path.join(ROOT, "data", "delivered-books.txt")
        if not os.path.isfile(ledger):
            self.skipTest("no committed ledger in this checkout")
        guard = self._guard()
        guard.DELIVERED_FILE = ledger
        delivered = guard.load_delivered(ledger)
        self.assertEqual(len(delivered), 6)
        for title in ("NOS4A2", "The Fisherman", "Mexican Gothic",
                      "The Great God Pan", "The King in Yellow",
                      "The Haunting of Hill House"):
            self.assertTrue(guard.is_delivered(title, delivered), title)

    def test_real_rotation_has_eligible_books_left(self):
        """After the six deliveries, the rotation still has books to give."""
        ledger = os.path.join(ROOT, "data", "delivered-books.txt")
        books = os.path.join(ROOT, "data", "horror-books.tsv")
        if not (os.path.isfile(ledger) and os.path.isfile(books)):
            self.skipTest("no committed rotation data in this checkout")
        guard = self._guard()
        delivered = guard.load_delivered(ledger)
        eligible = [b for b in guard.load_books(books)
                    if not guard.is_delivered(b["title"], delivered)]
        self.assertGreater(len(eligible), 0)


class BookMetaTests(unittest.TestCase):
    def test_epub_title_and_author(self):
        path = make_epub("The Great God Pan", "Arthur Machen")
        self.addCleanup(os.unlink, path)
        title, author = bookmeta.extract_metadata(path)
        self.assertEqual(bookmeta.normalise(title), "the great god pan")
        self.assertTrue(bookmeta.author_matches("Arthur Machen", author))

    def test_mobi_title_and_author(self):
        path = make_mobi("NOS4A2", "Joe Hill")
        self.addCleanup(os.unlink, path)
        title, author = bookmeta.extract_metadata(path)
        self.assertTrue(bookmeta.title_matches("NOS4A2", title), title)
        self.assertTrue(bookmeta.author_matches("Joe Hill", author), author)

    def test_azw3_title_and_author(self):
        path = make_azw3("The King in Yellow", "Robert W. Chambers")
        self.addCleanup(os.unlink, path)
        title, author = bookmeta.extract_metadata(path)
        self.assertTrue(bookmeta.title_matches("The King in Yellow", title), title)
        self.assertTrue(bookmeta.author_matches("Robert W. Chambers", author), author)

    def test_mobi_composite_internal_name(self):
        """The 'author - title' form must resolve to both halves."""
        path = make_mobi("NOS4A2", "Hill, Joe")
        self.addCleanup(os.unlink, path)
        title, author = bookmeta.extract_metadata(path)
        self.assertTrue(bookmeta.title_matches("NOS4A2", title), title)

    def test_title_match_rejects_a_different_book(self):
        self.assertFalse(bookmeta.title_matches("The Great God Pan", "NOS4A2"))

    def test_title_match_fails_closed_on_missing_metadata(self):
        """No metadata must never count as a match."""
        self.assertFalse(bookmeta.title_matches("NOS4A2", None))
        self.assertFalse(bookmeta.title_matches("NOS4A2", ""))

    def test_author_match_fails_closed_on_missing_metadata(self):
        self.assertFalse(bookmeta.author_matches("Joe Hill", None))

    def test_author_match_ignores_name_order(self):
        self.assertTrue(bookmeta.author_matches("Joe Hill", "Hill, Joe"))

    def test_extraction_from_a_non_book_file_returns_nothing(self):
        path = tempfile.mktemp(suffix=".txt")
        with open(path, "w", encoding="utf-8") as fh:
            fh.write("just some text\n")
        self.addCleanup(os.unlink, path)
        title, author = bookmeta.extract_metadata(path)
        self.assertIsNone(title)
        self.assertIsNone(author)

    def test_palmdb_mobi_header_is_parsed(self):
        """A real PalmDB layout must yield the title and author."""
        path = make_palmdb_book("NOS4A2", "Hill, Joe")
        self.addCleanup(os.unlink, path)
        title, author = bookmeta.extract_metadata(path)
        self.assertTrue(bookmeta.title_matches("NOS4A2", title), title)
        self.assertTrue(bookmeta.author_matches("Joe Hill", author), author)

    def test_exth_is_read_when_the_flag_is_present(self):
        """The EXTH block holds the authoritative title and author."""
        path = make_palmdb_book("Mexican Gothic", "Silvia Moreno-Garcia")
        self.addCleanup(os.unlink, path)
        title, author = bookmeta.extract_metadata(path)
        self.assertEqual(title, "Mexican Gothic")
        self.assertEqual(author, "Silvia Moreno-Garcia")

    def test_falls_back_to_the_internal_name_without_exth(self):
        """A MOBI with no EXTH still resolves via its internal name."""
        path = make_palmdb_book("The Great God Pan", "Arthur Machen",
                                with_exth=False)
        self.addCleanup(os.unlink, path)
        title, author = bookmeta.extract_metadata(path)
        self.assertTrue(bookmeta.title_matches("The Great God Pan", title), title)
        self.assertTrue(bookmeta.author_matches("Arthur Machen", author), author)


if __name__ == "__main__":
    unittest.main(verbosity=2)
