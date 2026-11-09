#!/usr/bin/env python3
"""Gabungkan seluruh migrasi menjadi SATU file SQL siap paste.

Mengapa
-------
Setup database sebelumnya mengharuskan menjalankan 30+ file migrasi satu per
satu di Supabase SQL Editor. Itu tidak praktis, khususnya kalau satu-satunya
perangkat adalah HP.

Skrip ini menghasilkan `supabase/SETUP_ALL.sql` yang berisi semua migrasi
secara berurutan, ditambah pemanggilan seed di bagian akhir (dikomentari).
Satu tempel, selesai.

Usage:
    python3 tool/build_setup_sql.py
"""

from __future__ import annotations

import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRATIONS = os.path.join(ROOT, "supabase", "migrations")
OUT = os.path.join(ROOT, "supabase", "SETUP_ALL.sql")


def strip_comments(sql: str) -> str:
    """Buang baris komentar agar ukuran file paste jauh lebih kecil.

    Aman karena di seluruh migrasi tidak ada string literal yang mengandung
    '--'. Baris kosong yang tersisa dirapikan supaya tidak boros.
    """
    out: list[str] = []
    blank = 0
    for line in sql.split("\n"):
        if line.lstrip().startswith("--"):
            continue
        if not line.strip():
            blank += 1
            if blank > 1:
                continue
        else:
            blank = 0
        out.append(line.rstrip())
    return "\n".join(out)

HEADER = """\
-- ============================================================================
-- SIM MADIN — SETUP DATABASE LENGKAP (SATU FILE)
-- ============================================================================
-- Dibuat otomatis oleh tool/build_setup_sql.py — JANGAN diedit manual.
--
-- CARA PAKAI
-- ----------------------------------------------------------------------------
--   1. Buka Supabase Dashboard -> SQL Editor -> New query
--   2. Buka file ini, salin SELURUH isinya, tempel, lalu klik Run
--   3. Setelah selesai, jalankan bagian DATA DEMO di paling bawah
--      (hapus tanda komentar '--' pada baris SELECT)
--
-- CATATAN
-- ----------------------------------------------------------------------------
--   * Seluruh perintah bersifat idempotent (aman dijalankan berulang).
--   * Bagian yang menyentuh schema `auth` hanya berhasil bila dijalankan
--     sebagai pemilik database — SQL Editor Supabase memenuhi syarat itu.
--   * Setelah selesai, verifikasi dengan file terpisah:
--         docs/sql/cek_login.sql  (kecil, untuk troubleshooting)
--
-- ISI: {count} file migrasi
-- ============================================================================

"""

FOOTER = """

-- ============================================================================
-- BAGIAN AKHIR — DATA DEMO
-- ============================================================================
-- Hapus tanda komentar pada baris di bawah, lalu Run sekali lagi.
-- Baris pertama mengisi data akademik & keuangan + akun demo.
-- Baris kedua memastikan akun login (auth.users) benar-benar terbentuk.
--
-- SELECT * FROM public.seed_all_demo();
--
-- Setelah seed: perbaiki/pastikan akun login bisa dipakai
-- SELECT * FROM public.repair_demo_logins();
--
-- Verifikasi (kolom siap_login harus true untuk semua baris)
-- SELECT * FROM public.demo_account_status();
--
-- Kredensial demo:
--   Admin      mdta@madrasah.com        / admin@mdta01
--   Kepala     kepala@madrasah.com      / kepala123
--   Bendahara  bendahara@madrasah.com   / bendahara123
--   Guru       guru@madrasah.com        / guru123
--   Wali       081234567801             / PIN 123456
-- ============================================================================
"""


def main() -> int:
    files = sorted(glob.glob(os.path.join(MIGRATIONS, "*.sql")))
    if not files:
        print("error: tidak ada file migrasi", file=sys.stderr)
        return 1

    parts = [HEADER.format(count=len(files))]

    for path in files:
        name = os.path.basename(path)
        body = strip_comments(open(path, encoding="utf-8").read()).rstrip()

        parts.append(
            f"\n-- {'=' * 74}\n"
            f"-- FILE: {name}\n"
            f"-- {'=' * 74}\n\n"
            f"{body}\n"
        )

    parts.append(FOOTER)

    content = "".join(parts)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(content)

    size_kb = len(content.encode("utf-8")) / 1024
    print(f"wrote {OUT}")
    print(f"  {len(files)} file migrasi, {size_kb:.0f} KB, "
          f"{content.count(chr(10))} baris")
    return 0


if __name__ == "__main__":
    sys.exit(main())
