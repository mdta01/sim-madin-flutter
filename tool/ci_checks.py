#!/usr/bin/env python3
"""Pemeriksaan statis untuk CI: konsistensi skema vs. kode Flutter.

Tidak memerlukan Flutter, Dart, maupun PostgreSQL — hanya Python 3.
Dijalankan di CI dan bisa dijalankan lokal:

    python3 tool/ci_checks.py

Yang diperiksa
--------------
1. Migrasi SQL seimbang (dollar-quote, tanda kurung, BEGIN/END).
2. Setiap nama tabel yang dipakai kode (rowFor/patchFor/from(...)) ada
   di skema hasil migrasi.
3. Setiap payload `rowFor('Tabel', {...})` hanya memakai kolom yang ada,
   dan mengisi semua kolom NOT NULL tanpa DEFAULT.
4. Realtime: setiap tabel yang di-subscribe aplikasi ada di publication.
5. RLS: setiap tabel punya ROW LEVEL SECURITY aktif.
6. Kode Dart seimbang kurung kurawal/kurung (deteksi cepat file terpotong).

Keluaran: daftar masalah + exit code 1 bila ada masalah.
"""

from __future__ import annotations

import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRATIONS = os.path.join(ROOT, "supabase", "migrations")
BASELINE = os.path.join(MIGRATIONS, "20231231000000_baseline_schema.sql")
API_LIB = os.path.join(ROOT, "packages", "api_client", "lib")

problems: list[str] = []


def add(msg: str) -> None:
    problems.append(msg)


# ---------------------------------------------------------------------------
# Skema
# ---------------------------------------------------------------------------

def load_schema() -> dict[str, dict[str, tuple[str, bool, bool]]]:
    """Kembalikan {tabel: {kolom: (tipe, not_null, punya_default)}}."""
    base = open(BASELINE, encoding="utf-8").read()
    tables: dict[str, dict[str, tuple[str, bool, bool]]] = {}

    for m in re.finditer(
        r'CREATE TABLE IF NOT EXISTS "([^"]+)" \((.*?)\n\);', base, re.S
    ):
        name, body = m.group(1), m.group(2)
        cols: dict[str, tuple[str, bool, bool]] = {}
        for line in body.split("\n"):
            line = line.strip().rstrip(",")
            cm = re.match(r'"([^"]+)"\s+([\w \(\),]+?)(\s+NOT NULL)?(\s+DEFAULT|\s*$)', line)
            if not cm:
                continue
            cols[cm.group(1)] = (cm.group(2).strip(), bool(cm.group(3)), "DEFAULT" in line)
        tables[name] = cols

    # Kolom yang ditambahkan / diubah oleh migrasi setelah baseline.
    added: dict[str, set[str]] = {}
    for path in sorted(glob.glob(os.path.join(MIGRATIONS, "*.sql"))):
        if os.path.basename(path) == os.path.basename(BASELINE):
            continue
        sql = open(path, encoding="utf-8").read()
        for m in re.finditer(
            r'ALTER TABLE\s+"?([A-Za-z]\w*)"?\s+ADD COLUMN\s+(?:IF NOT EXISTS\s+)?"?(\w+)"?',
            sql,
            re.I,
        ):
            added.setdefault(m.group(1), set()).add(m.group(2))

    for table, cols in added.items():
        for col in cols:
            tables.setdefault(table, {})[col] = ("text", False, True)

    # Kolom yang ditambahkan lewat ALTER TABLE ... ADD COLUMN di migrasi
    # setelah baseline (mis. Wali.authPassword, User.fcmToken).
    for path in sorted(glob.glob(os.path.join(MIGRATIONS, "*.sql"))):
        sql = open(path, encoding="utf-8").read()
        for m in re.finditer(
            r'ALTER TABLE\s+"?(\w+)"?\s+ADD COLUMN\s+(?:IF NOT EXISTS\s+)?'
            r'"?([A-Za-z]\w*)"?\s+([\w \(\),]+)',
            sql,
            re.I,
        ):
            table, col, ctype = m.group(1), m.group(2), m.group(3).strip()
            if table in tables and col not in tables[table]:
                tables[table][col] = (ctype, False, True)

    # Tabel BARU yang dibuat oleh migrasi setelah baseline (mis. WaliPinReset).
    for path in sorted(glob.glob(os.path.join(MIGRATIONS, "*.sql"))):
        if os.path.basename(path) == os.path.basename(BASELINE):
            continue
        sql = open(path, encoding="utf-8").read()
        for m in re.finditer(
            r'CREATE TABLE IF NOT EXISTS\s+"?(\w+)"?\s*\((.*?)\n\);', sql, re.S | re.I
        ):
            name = m.group(1)
            if name in tables:
                continue
            cols: dict[str, tuple[str, bool, bool]] = {}
            for line in m.group(2).split("\n"):
                line = line.strip().rstrip(",")
                cm = re.match(
                    r'"?([A-Za-z]\w*)"?\s+([\w \(\),]+?)(\s+NOT NULL)?(\s+DEFAULT|\s*$)',
                    line,
                )
                if cm:
                    cols[cm.group(1)] = (cm.group(2).strip(), bool(cm.group(3)), "DEFAULT" in line)
            tables[name] = cols

    # Migration 19 menghapus NOT NULL pada User.passwordHash.
    if "User" in tables and "passwordHash" in tables["User"]:
        t, nn, d = tables["User"]["passwordHash"]
        tables["User"]["passwordHash"] = (t, False, True)

    return tables


def check_migrations() -> None:
    for path in sorted(glob.glob(os.path.join(MIGRATIONS, "*.sql"))):
        raw = open(path, encoding="utf-8").read()
        name = os.path.basename(path)

        # Abaikan komentar sebelum menghitung.
        code = re.sub(r"--[^\n]*", "", raw)
        code = re.sub(r"/\*.*?\*/", "", code, flags=re.S)

        # Hitung $$ pada kode saja; komentar sering menyebut 'DO $$ ...'.
        if len(re.findall(r"\$\$", code)) % 2 != 0:
            add(f"SQL {name}: jumlah $$ ganjil — blok fungsi tidak tertutup")

        if code.count("(") != code.count(")"):
            add(
                f"SQL {name}: tanda kurung tidak seimbang "
                f"({code.count('(')} buka vs {code.count(')')} tutup)"
            )



# ---------------------------------------------------------------------------
# Kode vs skema
# ---------------------------------------------------------------------------

def strip_dart_comments(src: str) -> str:
    """Buang komentar agar contoh di dokumentasi tidak ikut diperiksa.

    Literal string TIDAK disentuh karena justru itu yang diperiksa, tetapi
    komentar baris dan blok dibuang.
    """
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    src = re.sub(r"^\s*///?[^\n]*$", "", src, flags=re.M)
    return src


def dart_files() -> list[str]:
    files = glob.glob(os.path.join(ROOT, "packages", "**", "*.dart"), recursive=True)
    files += glob.glob(os.path.join(ROOT, "apps", "**", "*.dart"), recursive=True)
    return files


def check_sql_insert_columns(tables: dict) -> None:
    """Setiap INSERT di migrasi hanya boleh memakai kolom yang benar-benar ada.

    Kesalahan seperti INSERT INTO "Jadwal"(day, ...) padahal kolomnya
    "dayOfWeek" (integer) baru ketahuan saat migrasi dijalankan di Postgres.
    Pemeriksaan statis ini menangkapnya lebih awal.
    """
    files = glob.glob(os.path.join(MIGRATIONS, "*.sql"))
    for path in files:
        sql = open(path, encoding="utf-8").read()
        sql = re.sub(r"--[^\n]*", "", sql)
        name = os.path.basename(path)

        for m in re.finditer(r'INSERT INTO\s+"(\w+)"\s*\(([^)]*)\)', sql):
            table = m.group(1)
            if table not in tables:
                # Tabel di schema auth / extension memang di luar baseline.
                if table.lower() in ("users", "identities", "sessions"):
                    continue
                add(f"SQL {name}: INSERT INTO \"{table}\" — tabel tidak ada di skema")
                continue
            cols = tables[table]
            used = [c.strip().strip('"') for c in m.group(2).split(",") if c.strip()]
            for col in used:
                if col not in cols:
                    add(
                        f"SQL {name}: INSERT INTO \"{table}\" memakai kolom "
                        f"\"{col}\" yang tidak ada di skema"
                    )

        # ALTER TABLE "X" ... juga harus menunjuk tabel nyata
        for m in re.finditer(r'ALTER TABLE\s+"?(\w+)"?\s', sql):
            t = m.group(1)
            if t not in tables and t.lower() not in ("users", "identities", "sessions"):
                # migration 19-26 bisa menyentuh tabel auth
                if t not in ("User",):
                    add(f"SQL {name}: ALTER TABLE \"{t}\" — tabel tidak ada di skema")


def check_local_imports() -> None:
    """Simbol dari file lokal harus diimpor eksplisit.

    Paket api_client terdiri dari banyak file 'part-like' (bukan library
    tunggal), jadi memakai rowFor()/patchFor() tanpa `import
    'supabase_write.dart';` akan gagal compile. Ini jenis kesalahan yang
    dulu lolos karena CI memakai `|| true`.
    """
    lib = os.path.join(ROOT, "packages", "api_client", "lib")
    symbols = {
        "supabase_write.dart": [
            "rowFor", "patchFor", "softDeleteFor", "insertRow",
            "updateRow", "softDeleteRow", "nowIso",
        ],
        "table_columns.dart": ["kTableCaps", "TableColumnCaps"],
        "realtime_coordinator.dart": [
            "realtimeCoordinatorProvider", "realtimeChannelsState",
            "realtimeSubscribedTables", "realtimeEventCount",
        ],
    }

    for path in glob.glob(os.path.join(lib, "*.dart")):
        name = os.path.basename(path)
        src = strip_dart_comments(open(path, encoding="utf-8").read())

        for owner, syms in symbols.items():
            if name == owner:
                continue
            used = [s for s in syms if re.search(r"\b" + s + r"\b", src)]
            if not used:
                continue
            # Definisi lokal di file ini? (mis. fungsi helper dengan nama sama)
            defined = [
                s
                for s in used
                if re.search(r"^(?:final|const|void|String|Map|List|Future)[^\n]*\b" + s + r"\b", src, re.M)
            ]
            if len(defined) == len(used):
                continue
            if f"import '{owner}';" not in src:
                add(
                    f"packages/api_client/lib/{name}: memakai {sorted(set(used) - set(defined))} "
                    f"tanpa import '{owner}';"
                )


def check_write_payloads(tables: dict) -> None:
    for path in dart_files():
        s = strip_dart_comments(open(path, encoding="utf-8").read())
        rel = os.path.relpath(path, ROOT)

        for m in re.finditer(r"rowFor\(\s*'([^']+)'\s*,\s*\{", s):
            table = m.group(1)
            if table not in tables:
                add(f"{rel}: rowFor('{table}') — tabel tidak ada di skema")
                continue

            # Ambil isi map terlampir.
            i = m.end() - 1
            depth = 0
            body = ""
            for j in range(i, len(s)):
                if s[j] == "{":
                    depth += 1
                elif s[j] == "}":
                    depth -= 1
                    if depth == 0:
                        body = s[i : j + 1]
                        break

            keys = set(re.findall(r"'([A-Za-z][A-Za-z0-9]*)'\s*:", body))
            cols = tables[table]

            unknown = keys - set(cols)
            if unknown:
                add(f"{rel}: rowFor('{table}') memakai kolom tak dikenal {sorted(unknown)}")

            # id/createdAt/updatedAt kini punya DEFAULT (migration 24).
            auto = {"id", "createdAt", "updatedAt"}
            missing = [
                c
                for c, (_t, not_null, has_default) in cols.items()
                if not_null and not has_default and c not in keys and c not in auto
            ]
            if missing:
                add(
                    f"{rel}: rowFor('{table}') tidak mengisi kolom NOT NULL "
                    f"tanpa DEFAULT {sorted(missing)}"
                )


def check_table_references(tables: dict) -> None:
    pattern = re.compile(r"\.from\(\s*'([^']+)'\s*\)")
    for path in dart_files():
        s = strip_dart_comments(open(path, encoding="utf-8").read())
        rel = os.path.relpath(path, ROOT)
        for m in pattern.finditer(s):
            t = m.group(1)
            if t not in tables:
                add(f"{rel}: .from('{t}') — tabel tidak ada di skema")


def check_realtime_publication(tables: dict) -> None:
    coordinator = os.path.join(API_LIB, "realtime_coordinator.dart")
    if not os.path.exists(coordinator):
        add("realtime_coordinator.dart tidak ditemukan")
        return

    src = open(coordinator, encoding="utf-8").read()
    subscribed = set(re.findall(r"'([A-Za-z][A-Za-z0-9]*)'", src))
    subscribed &= set(tables)  # abaikan string yang bukan nama tabel

    published: set[str] = set()
    for path in glob.glob(os.path.join(MIGRATIONS, "*.sql")):
        sql = open(path, encoding="utf-8").read()
        for m in re.finditer(
            r'ALTER PUBLICATION\s+\w+\s+ADD TABLE\s+"?([A-Za-z]\w*)"?', sql, re.I
        ):
            published.add(m.group(1))

    # Migration 22 menambahkan tabel lewat EXECUTE + FOREACH atas sebuah array,
    # jadi nama tabelnya tidak muncul di klausa ADD TABLE literal.
    for path in glob.glob(os.path.join(MIGRATIONS, "*.sql")):
        sql = open(path, encoding="utf-8").read()
        for m in re.finditer(r"tables\s+\w*\[\]\s*:=\s*ARRAY\s*\[(.*?)\];", sql, re.S | re.I):
            published |= set(re.findall(r"'([A-Za-z][A-Za-z0-9]*)'", m.group(1)))

    missing = sorted(subscribed - published)
    if missing:
        add(
            "Realtime: tabel di-subscribe tapi TIDAK ada di publication "
            f"(perubahan tidak akan sampai ke aplikasi): {missing}"
        )


def check_launcher_icons() -> None:
    """Setiap app mobile harus punya launcher icon yang valid & lengkap.

    Tanpa adaptive icon (mipmap-anydpi-v26), launcher Android 8+ mem-mask
    ic_launcher.png lama menjadi lingkaran/rounded-square. Ikon dengan latar
    putih penuh akan tampak seperti lingkaran putih kosong — inilah kenapa
    ikon app terlihat "tidak tercantum".
    """
    dens = ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"]
    for app in ("mobile_wali", "mobile_guru", "mobile_kepala", "mobile_bendahara"):
        base = os.path.join(
            ROOT, "apps", app, "android", "app", "src", "main"
        )
        res = os.path.join(base, "res")

        # 1. adaptive icon XML
        for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
            f = os.path.join(res, "mipmap-anydpi-v26", name)
            if not os.path.exists(f):
                add(f"{app}: adaptive icon mipmap-anydpi-v26/{name} tidak ada")

        # 2. foreground per kerapatan
        for d in dens:
            f = os.path.join(res, f"mipmap-{d}", "ic_launcher_foreground.png")
            if not os.path.exists(f):
                add(f"{app}: mipmap-{d}/ic_launcher_foreground.png tidak ada")

        # 3. warna latar adaptive
        colors = os.path.join(res, "values", "colors.xml")
        if not os.path.exists(colors) or "ic_launcher_background" not in open(
            colors, encoding="utf-8"
        ).read():
            add(f"{app}: values/colors.xml belum mendefinisikan ic_launcher_background")

        # 4. manifest merujuk icon + roundIcon
        manifest = os.path.join(base, "AndroidManifest.xml")
        if os.path.exists(manifest):
            m = open(manifest, encoding="utf-8").read()
            if 'android:icon="@mipmap/ic_launcher"' not in m:
                add(f"{app}: AndroidManifest tidak merujuk @mipmap/ic_launcher")
            if "android:roundIcon" not in m:
                add(f"{app}: AndroidManifest tidak punya android:roundIcon")

        # 5. PNG legacy tidak boleh hilang
        for d in dens:
            f = os.path.join(res, f"mipmap-{d}", "ic_launcher.png")
            if not os.path.exists(f):
                add(f"{app}: mipmap-{d}/ic_launcher.png tidak ada")


def check_rls(tables: dict) -> None:
    enabled: set[str] = set()
    for path in glob.glob(os.path.join(MIGRATIONS, "*.sql")):
        sql = open(path, encoding="utf-8").read()
        for m in re.finditer(
            r'ALTER TABLE\s+"?([A-Za-z]\w*)"?\s+ENABLE ROW LEVEL SECURITY', sql, re.I
        ):
            enabled.add(m.group(1))

    missing = sorted(set(tables) - enabled)
    if missing:
        add(f"RLS tidak aktif pada tabel: {missing}")


def check_generated_table_columns(tables: dict) -> None:
    """table_columns.dart harus sinkron dengan skema."""
    gen = os.path.join(API_LIB, "table_columns.dart")
    if not os.path.exists(gen):
        add("table_columns.dart belum di-generate (jalankan tool/gen_table_caps.py)")
        return
    src = open(gen, encoding="utf-8").read()
    entries = set(re.findall(r"'([A-Za-z][A-Za-z0-9]*)':\s*TableColumnCaps\(", src))
    missing = sorted(set(tables) - entries)
    extra = sorted(entries - set(tables))
    if missing:
        add(f"table_columns.dart kurang tabel: {missing}")
    if extra:
        add(f"table_columns.dart punya tabel yang tidak ada di skema: {extra}")


# ---------------------------------------------------------------------------

def main() -> int:
    tables = load_schema()
    if not tables:
        print("GAGAL: skema baseline tidak terbaca")
        return 1

    check_migrations()
    check_sql_insert_columns(tables)
    check_local_imports()
    check_write_payloads(tables)
    check_table_references(tables)
    check_realtime_publication(tables)
    check_launcher_icons()
    check_rls(tables)
    check_generated_table_columns(tables)

    print(f"Skema: {len(tables)} tabel")
    if problems:
        print(f"\n{len(problems)} masalah ditemukan:\n")
        for p in problems:
            print(f"  - {p}")
        return 1

    print("OK — tidak ada masalah konsistensi skema/kode.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
