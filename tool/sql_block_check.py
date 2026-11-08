#!/usr/bin/env python3
"""Pemeriksa keseimbangan blok BEGIN/IF/LOOP/CASE pada migrasi SQL.

Fungsi PL/pgSQL yang bloknya tidak seimbang gagal dibuat dengan pesan
sintaks yang membingungkan ("syntax error at or near ..."), dan baru
ketahuan saat migrasi benar-benar dijalankan. Pemeriksaan statis ini
menangkapnya saat CI, tanpa perlu server PostgreSQL.

Cakupan pemeriksaan:
  * setiap blok $$ ... $$ dipindai terpisah
  * komentar (-- ...) dan string literal dibuang sebelum dihitung
  * pembuka : BEGIN, IF, LOOP, CASE
  * penutup : END;, END IF;, END LOOP;, END CASE;, serta END polos
              (yang menutup ekspresi CASE)
  * dikecualikan: 'CREATE/ALTER/DROP ... IF NOT EXISTS' dan 'ELSIF'

Usage:
    python3 tool/sql_block_check.py [file.sql ...]
    # tanpa argumen -> semua supabase/migrations/*.sql
"""

from __future__ import annotations

import glob
import os
import re
import sys

# Delimiter fungsi: $$ atau $tag$. Sengaja tidak menangani $1 (parameter).
DOLLAR = re.compile(r"\$[A-Za-z_]*\$")


def strip_noise(line: str) -> str:
    """Buang komentar baris dan isi string literal."""
    code = re.sub(r"--.*$", "", line)
    code = re.sub(r"'([^']|'')*'", "''", code)
    return code


def scan_line(line: str) -> tuple[int, int]:
    """Kembalikan (jumlah pembuka, jumlah penutup) untuk satu baris."""
    up = strip_noise(line).upper()

    # Penutup bertipe lebih dulu, lalu hilangkan dari teks agar 'END IF;'
    # tidak ikut terhitung sebagai 'END;'.
    typed_closes = len(re.findall(r"\bEND\s+(IF|LOOP|CASE)\b", up))
    up = re.sub(r"\bEND\s+(IF|LOOP|CASE)\b", "", up)

    stmt_closes = len(re.findall(r"\bEND\s*;", up))
    up = re.sub(r"\bEND\s*;", "", up)

    # 'ELSIF' bukan pembuka blok baru.
    up = re.sub(r"\bELSIF\b", "", up)
    # 'CREATE/ALTER/DROP ... IF NOT EXISTS' bukan blok IF.
    up = re.sub(r"(CREATE|ALTER|DROP)[^;]*?IF\s+NOT\s+EXISTS", "", up)

    opens = (
        len(re.findall(r"\bBEGIN\b", up))
        + len(re.findall(r"\bCASE\b", up))
        + len(re.findall(r"\bIF\b", up))
        + len(re.findall(r"\bLOOP\b", up))
    )
    # END polos menutup ekspresi CASE (mis. "END," di dalam SELECT).
    bare_closes = len(re.findall(r"\bEND\b", up))

    return opens, typed_closes + stmt_closes + bare_closes


def split_blocks(sql: str) -> list[tuple[int, str]]:
    """Pisahkan isi setiap pasangan delimiter, abaikan komentar & string.

    Mengembalikan daftar (nomor_baris_awal, isi_blok).
    """
    # Buang komentar baris penuh supaya '$$' di dalam komentar tidak
    # dianggap delimiter.
    lines = sql.split("\n")
    cleaned = [
        "" if ln.lstrip().startswith("--") else ln
        for ln in lines
    ]
    text = "\n".join(cleaned)

    marks = [(m.start(), m.end()) for m in DOLLAR.finditer(text)]
    blocks: list[tuple[int, str]] = []
    for i in range(0, len(marks) - 1, 2):
        start = marks[i][1]
        end = marks[i + 1][0]
        line_no = text.count("\n", 0, start) + 1
        blocks.append((line_no, text[start:end]))
    return blocks


def check_file(path: str) -> int:
    """Periksa satu file. Mengembalikan jumlah blok yang tidak seimbang."""
    sql = open(path, encoding="utf-8").read()
    problems = 0

    for line_no, body in split_blocks(sql):
        depth = 0
        first_negative = None
        for offset, line in enumerate(body.split("\n")):
            opens, closes = scan_line(line)
            depth += opens - closes
            if depth < 0 and first_negative is None:
                first_negative = (line_no + offset, line.strip()[:60])

        if depth == 0:
            continue

        problems += 1
        print(f"  !! blok mulai baris {line_no}: tidak seimbang ({depth:+d})")
        if first_negative:
            print(f"     kedalaman negatif di baris {first_negative[0]}: "
                  f"{first_negative[1]}")

    return problems


def main() -> int:
    paths = sys.argv[1:] or sorted(glob.glob("supabase/migrations/*.sql"))
    if not paths:
        print("tidak ada file migrasi ditemukan", file=sys.stderr)
        return 1

    total = 0
    for path in paths:
        found = check_file(path)
        status = "OK" if found == 0 else f"{found} blok bermasalah"
        print(f"{os.path.basename(path):60s} {status}")
        total += found

    if total:
        print(f"\n{total} blok tidak seimbang. Perbaiki sebelum migrasi dijalankan.")
        return 1

    print("\nOK - semua blok BEGIN/IF/LOOP/CASE seimbang.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
