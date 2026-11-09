#!/usr/bin/env python3
"""Hasilkan migrasi rekonsiliasi skema yang UNIVERSAL.

Masalah yang diselesaikan
-------------------------
Baseline memakai `CREATE TABLE IF NOT EXISTS`. Bila tabel SUDAH ADA (database
dibuat dari skema versi lama, atau tabel dibuat manual sebagian), perintah itu
tidak melakukan apa pun — kolom baru di baseline TIDAK PERNAH ditambahkan.
Gejalanya:

    ERROR: 42703: column "isPublished" does not exist

Solusi
------
Hasilkan `ALTER TABLE "X" ADD COLUMN IF NOT EXISTS "<kolom>" <tipe>;` untuk
SETIAP kolom di seluruh DDL migrasi.

Kenapa ini aman:
  * `IF NOT EXISTS` membuat kolom yang sudah ada dilewati sepenuhnya —
    tipe, default, dan constraint yang sudah terpasang tidak tersentuh.
  * Hanya MENAMBAH kolom. Tidak ada DROP, tidak ada ALTER TYPE.
  * Kolom NOT NULL tanpa DEFAULT ditambahkan sebagai **nullable**, karena
    menambahkannya sebagai NOT NULL akan gagal bila tabel sudah berisi baris.
    Kolom tersebut dicatat di bagian CATATAN agar bisa diperiksa.
  * Kolom PRIMARY KEY tidak ditambahkan lewat ALTER (tidak didukung); dicatat.
  * Idempotent: aman dijalankan berkali-kali.

Usage:
    python3 tool/gen_schema_reconcile.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MIGRATIONS = ROOT / "supabase/migrations"
OUT = ROOT / "supabase/migrations/20240101000033_schema_reconcile.sql"

CREATE_TABLE = re.compile(
    r'CREATE TABLE IF NOT EXISTS\s+"?(\w+)"?\s*\((.*?)\n\);', re.S | re.I
)
ALTER_ADD = re.compile(
    r'ALTER TABLE\s+"?(\w+)"?\s+ADD COLUMN\s+(?:IF NOT EXISTS\s+)?'
    r'"?([A-Za-z]\w*)"?\s+([^;]+);',
    re.I,
)
CONSTRAINT_START = re.compile(
    r"\s+(PRIMARY KEY|NOT NULL|DEFAULT|UNIQUE|REFERENCES|CHECK)\b", re.I
)

# Tipe yang butuh schema khusus; ALTER harus menyebut schema-nya.
SCHEMA_PREFIX = {"uuid": "", "jsonb": "", "text": "", "integer": "", "boolean": "",
                 "timestamp": "", "timestamp(3)": "", "double precision": "",
                 "real": "", "bigint": "", "smallint": "", "date": "", "time": "",
                 "numeric": ""}


def clean_type(raw: str) -> str:
    """Buang klausa constraint dari definisi tipe."""
    m = CONSTRAINT_START.search(raw)
    return (raw[: m.start()] if m else raw).strip()


def parse_ddl() -> tuple[dict[str, dict[str, dict]], list[str]]:
    """Kumpulkan {tabel: {kolom: {type, default, notnull, pk}}} dari semua migrasi."""
    tables: dict[str, dict[str, dict]] = {}
    notes: list[str] = []

    for path in sorted(MIGRATIONS.glob("*.sql")):
        sql = path.read_text(encoding="utf-8")
        sql = re.sub(r"--[^\n]*", "", sql)

        for m in CREATE_TABLE.finditer(sql):
            table, body = m.group(1), m.group(2)
            cols = tables.setdefault(table, {})
            for line in body.split("\n"):
                line = line.strip().rstrip(",")
                if not line:
                    continue
                cm = re.match(r'"(\w+)"\s+(.+)', line)
                if not cm:
                    continue
                name, rest = cm.group(1), cm.group(2)
                info = {
                    "type": clean_type(rest),
                    "notnull": bool(re.search(r"\bNOT NULL\b", rest, re.I)),
                    "pk": bool(re.search(r"\bPRIMARY KEY\b", rest, re.I)),
                    "default": None,
                }
                dm = re.search(r"\bDEFAULT\s+(.+?)(?:\s+(?:NOT NULL|UNIQUE|REFERENCES)\b|$)",
                               rest, re.I | re.S)
                if dm:
                    info["default"] = dm.group(1).strip().rstrip(",")
                cols[name] = info

        for m in ALTER_ADD.finditer(sql):
            table, col, rest = m.group(1), m.group(2), m.group(3)
            cols = tables.setdefault(table, {})
            if col in cols:
                continue
            info = {
                "type": clean_type(rest),
                "notnull": bool(re.search(r"\bNOT NULL\b", rest, re.I)),
                "pk": False,
                "default": None,
            }
            dm = re.search(r"\bDEFAULT\s+(.+?)(?:\s+NOT NULL\b|$)", rest, re.I | re.S)
            if dm:
                info["default"] = dm.group(1).strip().rstrip(",")
            cols[col] = info

    return tables, notes


def render(tables: dict[str, dict[str, dict]]) -> tuple[str, int, list[str]]:
    notes: list[str] = []
    body: list[str] = []
    total = 0

    for table in sorted(tables):
        cols = tables[table]
        lines: list[str] = []
        for name in cols:
            info = cols[name]
            if info["pk"]:
                continue  # tidak bisa ditambahkan lewat ALTER
            ctype = info["type"] or "text"
            if not ctype or ctype.startswith("("):
                ctype = "text"

            stmt = f'ALTER TABLE "{table}" ADD COLUMN IF NOT EXISTS "{name}" {ctype}'
            if info["notnull"]:
                if info["default"] is not None:
                    stmt += f" DEFAULT {info['default']}"
                else:
                    notes.append(
                        f'{table}."{name}" aslinya NOT NULL tanpa DEFAULT; '
                        f"ditambahkan sebagai nullable agar baris lama tidak gagal"
                    )
            lines.append(stmt + ";")
            total += 1

        if lines:
            body.append(f"-- {table}")
            body.extend(lines)
            body.append("")

    head = """\
-- ============================================================================
-- SIM MADIN — Rekonsiliasi skema (dibuat otomatis)
-- ============================================================================
-- Dibuat oleh tool/gen_schema_reconcile.py — JANGAN diedit manual.
--
-- LATAR BELAKANG
--   Baseline memakai CREATE TABLE IF NOT EXISTS. Bila tabel sudah ada dari
--   skema versi lama, perintah itu tidak melakukan apa pun, sehingga kolom
--   baru TIDAK PERNAH ditambahkan. Gejalanya:
--
--       ERROR: 42703: column "isPublished" does not exist
--
--   Migrasi ini menambahkan setiap kolom yang belum ada pada tabel yang sudah
--   ada. Kolom yang sudah terpasang dilewati sepenuhnya oleh IF NOT EXISTS,
--   sehingga tipe, default, dan constraint yang ada tidak berubah.
--
--   Hanya MENAMBAH kolom. Tidak ada DROP maupun ALTER TYPE.
--   Idempotent: aman dijalankan berulang.
-- ============================================================================

"""
    if notes:
        head += "-- CATATAN PENYESUAIAN\n"
        for n in notes:
            head += f"--   * {n}\n"
        head += "\n"

    tail = """
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Setelah menjalankan ini, coba ulang:
--   SELECT * FROM public.seed_all_demo();
--   SELECT * FROM public.repair_demo_logins();
--   SELECT * FROM public.demo_account_status();
-- ============================================================================
"""
    return head + f"-- {total} perintah ALTER TABLE\n\n" + "\n".join(body) + tail, total, notes


def main() -> int:
    tables, _ = parse_ddl()
    if not tables:
        print("error: tidak ada DDL ter-parse", file=sys.stderr)
        return 1

    content, total, notes = render(tables)
    OUT.write_text(content, encoding="utf-8")
    print(f"wrote {OUT}")
    print(f"  {total} kolom pada {len(tables)} tabel")
    if notes:
        print(f"  {len(notes)} catatan penyesuaian NOT NULL")
    return 0


if __name__ == "__main__":
    sys.exit(main())
