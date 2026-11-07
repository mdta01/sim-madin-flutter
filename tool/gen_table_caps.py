#!/usr/bin/env python3
"""
Generate `packages/api_client/lib/table_columns.dart` from the baseline schema.

Why
---
Prisma filled `id`, `createdAt`, and `updatedAt` in the application layer, but
NOT every table has all three columns. For example:

  * `Notifikasi`, `ChatMessage`, `UjianSoal`, `AuditLog`, `QRScan`,
    `Permission`, `UserRole`, `RolePermission`, `SantriWali` → no `updatedAt`
  * `SystemSetting`, `PhoneChangeLog`                           → no `createdAt`

Writing a blanket INSERT payload that always includes all three columns makes
PostgREST reject the request with `column "updatedAt" does not exist`, which is
exactly the class of silent bug this registry is meant to prevent.

Generating the map from the real DDL keeps it honest: if a column is added or
removed, re-run this script and the write helpers adapt automatically.

Usage
-----
    python3 tool/gen_table_caps.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = ROOT / "supabase/migrations/20231231000000_baseline_schema.sql"
OUT = ROOT / "packages/api_client/lib/table_columns.dart"


def parse_columns(sql: str) -> dict[str, dict[str, str]]:
    tables: dict[str, dict[str, str]] = {}
    for m in re.finditer(
        r'CREATE TABLE IF NOT EXISTS "(\w+)" \((.*?)\n\);', sql, re.S
    ):
        table, body = m.group(1), m.group(2)
        cols: dict[str, str] = {}
        for line in body.splitlines():
            mm = re.match(r'\s+"(\w+)" ([^,]+)', line)
            if mm:
                cols[mm.group(1)] = mm.group(2).strip()
        tables[table] = cols
    return tables


def main() -> int:
    if not SCHEMA.exists():
        print(f"error: {SCHEMA} tidak ditemukan", file=sys.stderr)
        return 1

    tables = parse_columns(SCHEMA.read_text(encoding="utf-8"))

    # Tabel yang dibuat oleh migrasi SETELAH baseline (mis. WaliPinReset)
    # juga harus terdaftar, kalau tidak helper rowFor() akan menolaknya.
    for mig in sorted((ROOT / "supabase/migrations").glob("*.sql")):
        if mig.name == SCHEMA.name:
            continue
        sql = mig.read_text(encoding="utf-8")
        for name, cols in parse_columns(sql).items():
            if name not in tables:
                tables[name] = cols
                print(f"  + tabel dari {mig.name}: {name}")

    if not tables:
        print("error: tidak ada tabel yang ter-parse", file=sys.stderr)
        return 1

    lines: list[str] = []
    lines.append("// ============================================================================")
    lines.append("// SIM MADIN — Kapabilitas kolom per tabel (GENERATED)")
    lines.append("// ============================================================================")
    lines.append("// AUTO-GENERATED oleh tool/gen_table_caps.py dari")
    lines.append("// supabase/migrations/20231231000000_baseline_schema.sql")
    lines.append("//")
    lines.append("// JANGAN edit manual. Regenerate dengan:")
    lines.append("//   python3 tool/gen_table_caps.py")
    lines.append("//")
    lines.append("// Dipakai oleh supabase_write.dart supaya payload INSERT/UPDATE hanya")
    lines.append("// menyertakan kolom yang benar-benar ada. Ini mencegah error")
    lines.append('// `column "X" does not exist` pada tabel yang tidak punya createdAt /')
    lines.append("// updatedAt (mis. Notifikasi, ChatMessage, UjianSoal, SantriWali).")
    lines.append("// ============================================================================")
    lines.append("")
    lines.append("/// Kapabilitas kolom standar untuk sebuah tabel.")
    lines.append("class TableColumnCaps {")
    lines.append("  const TableColumnCaps({")
    lines.append("    required this.hasId,")
    lines.append("    required this.hasCreatedAt,")
    lines.append("    required this.hasUpdatedAt,")
    lines.append("    required this.hasDeletedAt,")
    lines.append("  });")
    lines.append("")
    lines.append("  final bool hasId;")
    lines.append("  final bool hasCreatedAt;")
    lines.append("  final bool hasUpdatedAt;")
    lines.append("  final bool hasDeletedAt;")
    lines.append("}")
    lines.append("")
    lines.append("/// Peta nama tabel -> kapabilitas kolomnya (53 tabel).")
    lines.append("const Map<String, TableColumnCaps> kTableCaps = <String, TableColumnCaps>{")
    for table in sorted(tables):
        cols = tables[table]

        def flag(col: str) -> str:
            return "true" if col in cols else "false"

        lines.append(
            f"  '{table}': TableColumnCaps("
            f"hasId: {flag('id')}, "
            f"hasCreatedAt: {flag('createdAt')}, "
            f"hasUpdatedAt: {flag('updatedAt')}, "
            f"hasDeletedAt: {flag('deletedAt')}),"
        )
    lines.append("};")
    lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} ({len(tables)} tabel)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
