#!/usr/bin/env python3
"""Audit struktur repo untuk mencegah kegagalan build.

Memeriksa hal-hal yang pernah atau bisa mematahkan build CI, tanpa perlu
Flutter/Android SDK:

  1. Setiap app punya pubspec.yaml + android/ (yang dibangun CI)
  2. applicationId unik antar app (kalau sama, APK saling menimpa saat dipasang)
  3. Package MainActivity.kt cocok dengan path foldernya (kalau tidak,
     Gradle gagal: "package ... does not exist")
  4. applicationId setiap app mobile terdaftar di google-services.json
     (kalau tidak, plugin google-services menggagalkan build, atau FCM diam-diam
     tidak berfungsi)
  5. Tidak ada key.properties / keystore ter-commit
  6. Versi dependensi yang sama konsisten di semua pubspec
  7. AGP / Kotlin / Gradle wrapper seragam antar app
  8. Tidak ada file binari besar tak sengaja ter-commit
  9. Workflow memakai versi Flutter & Java yang sama di semua file

Usage:
    python3 tool/audit_repo.py
    python3 tool/audit_repo.py --verbose
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APPS = ROOT / "apps"
PACKAGES = ROOT / "packages"
WORKFLOWS = ROOT / ".github" / "workflows"

problems: list[str] = []
notes: list[str] = []


def add(msg: str) -> None:
    problems.append(msg)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def app_dirs() -> list[Path]:
    return sorted(d for d in APPS.iterdir() if d.is_dir() and (d / "pubspec.yaml").exists())


# ---------------------------------------------------------------------------
# 1 & 2. Kelengkapan app + applicationId unik
# ---------------------------------------------------------------------------
def check_apps() -> list[Path]:
    apps = app_dirs()
    if not apps:
        add("tidak ada app ditemukan di apps/")
        return []

    ids: dict[str, str] = {}
    for app in apps:
        gradle = app / "android" / "app" / "build.gradle"
        if not gradle.exists():
            # app tanpa android/ memang tidak dibangun sebagai APK
            notes.append(f"{app.name}: tanpa android/ (bukan target APK)")
            continue
        m = re.search(r'applicationId\s*=\s*"([^"]+)"', read(gradle))
        if not m:
            add(f"{app.name}: applicationId tidak ditemukan di android/app/build.gradle")
            continue
        app_id = m.group(1)
        if app_id in ids:
            add(f"applicationId '{app_id}' dipakai {app.name} dan {ids[app_id]} "
                f"-> APK akan saling menimpa saat dipasang")
        ids[app_id] = app.name
    return apps


# ---------------------------------------------------------------------------
# 3. MainActivity package vs path
# ---------------------------------------------------------------------------
def check_main_activity(apps: list[Path]) -> None:
    for app in apps:
        found = list((app / "android").rglob("MainActivity.kt"))
        if not found:
            found = list((app / "android").rglob("MainActivity.java"))
        if not found:
            if (app / "android").exists():
                notes.append(f"{app.name}: MainActivity tidak ditemukan")
            continue

        path = found[0]
        pkg_m = re.search(r"^package\s+([\w.]+)", read(path), re.M)
        if not pkg_m:
            add(f"{app.name}: MainActivity tanpa deklarasi package")
            continue
        pkg = pkg_m.group(1)

        # .../src/main/kotlin/id/madrasah/madin/x/MainActivity.kt
        parts = path.parts
        try:
            idx = parts.index("kotlin")
        except ValueError:
            try:
                idx = parts.index("java")
            except ValueError:
                continue
        folder = ".".join(parts[idx + 1 : -1])
        if folder and folder != pkg:
            add(f"{app.name}: package MainActivity '{pkg}' != folder '{folder}'")


# ---------------------------------------------------------------------------
# 4. applicationId terdaftar di google-services.json
# ---------------------------------------------------------------------------
def check_google_services(apps: list[Path]) -> None:
    for app in apps:
        gs = app / "android" / "app" / "google-services.json"
        gradle = app / "android" / "app" / "build.gradle"
        if not gradle.exists():
            continue
        m = re.search(r'applicationId\s*=\s*"([^"]+)"', read(gradle))
        if not m:
            continue
        app_id = m.group(1)

        if not gs.exists():
            # admin_desktop memang tidak memakai Firebase
            if "google-services" in read(gradle):
                add(f"{app.name}: memakai plugin google-services tetapi "
                    f"google-services.json tidak ada")
            continue

        try:
            data = json.loads(read(gs))
            pkgs = [
                c["client_info"]["android_client_info"]["package_name"]
                for c in data.get("client", [])
            ]
        except (json.JSONDecodeError, KeyError) as exc:
            add(f"{app.name}: google-services.json tidak valid ({exc})")
            continue

        if app_id not in pkgs:
            add(f"{app.name}: applicationId '{app_id}' tidak terdaftar di "
                f"google-services.json -> FCM tidak akan berfungsi")


# ---------------------------------------------------------------------------
# 5. Rahasia tidak boleh ter-commit
# ---------------------------------------------------------------------------
def check_secrets() -> None:
    try:
        tracked = subprocess.run(
            ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.splitlines()
    except (subprocess.CalledProcessError, FileNotFoundError):
        notes.append("git tidak tersedia; pemeriksaan rahasia dilewati")
        return

    forbid = ("key.properties", "key.jks", ".keystore", "local.properties")
    for f in tracked:
        name = f.rsplit("/", 1)[-1]
        if name in forbid:
            add(f"file rahasia ter-commit: {f}")

    # service_role key tidak boleh ada di mana pun
    for f in tracked:
        if not f.endswith((".dart", ".sql", ".yaml", ".yml", ".json", ".md")):
            continue
        text = read(ROOT / f)
        if "service_role" in text and "sb_secret" in text:
            add(f"kemungkinan service_role key di {f}")


# ---------------------------------------------------------------------------
# 6. Konsistensi versi dependensi
# ---------------------------------------------------------------------------
def check_dependency_versions() -> None:
    import collections

    versions: dict[str, dict[str, str]] = collections.defaultdict(dict)
    for path in list(APPS.glob("*/pubspec.yaml")) + list(PACKAGES.glob("*/pubspec.yaml")):
        text = read(path)
        m = re.search(r"^dependencies:(.*?)(?=^dev_dependencies:|\Z)", text, re.S | re.M)
        if not m:
            continue
        for line in m.group(1).split("\n"):
            mm = re.match(r"^  ([a-z_0-9]+):\s*(.+)$", line)
            if not mm:
                continue
            dep, ver = mm.group(1), mm.group(2).strip()
            if ver.startswith("path:") or ver.startswith("sdk:") or ver == "":
                continue
            versions[dep][path.parent.name] = ver

    for dep, per_pkg in versions.items():
        if len(set(per_pkg.values())) > 1:
            detail = ", ".join(f"{p}={v}" for p, v in sorted(per_pkg.items()))
            add(f"versi '{dep}' berbeda antar paket: {detail}")


# ---------------------------------------------------------------------------
# 7. AGP / Kotlin / Gradle seragam
# ---------------------------------------------------------------------------
def check_toolchain(apps: list[Path]) -> None:
    for field in ("agp", "kotlin", "gradle"):
        seen: dict[str, list[str]] = {}
        for app in apps:
            settings = app / "android" / "settings.gradle"
            wrapper = app / "android" / "gradle" / "wrapper" / "gradle-wrapper.properties"
            if not settings.exists():
                continue
            if field == "agp":
                m = re.search(r'com\.android\.application"?\s+version\s+"([^"]+)"',
                              read(settings))
            elif field == "kotlin":
                m = re.search(r'org\.jetbrains\.kotlin\.android"?\s+version\s+"([^"]+)"',
                              read(settings))
            else:
                m = re.search(r"gradle-([0-9.]+)-", read(wrapper))
            if m:
                seen.setdefault(m.group(1), []).append(app.name)
        if len(seen) > 1:
            detail = ", ".join(f"{v}=[{','.join(a)}]" for v, a in sorted(seen.items()))
            add(f"{field.upper()} tidak seragam antar app: {detail}")


# ---------------------------------------------------------------------------
# 8. File besar tak sengaja
# ---------------------------------------------------------------------------
def check_large_files(limit_kb: int = 3000) -> None:
    try:
        tracked = subprocess.run(
            ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.splitlines()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return

    for f in tracked:
        path = ROOT / f
        try:
            size = path.stat().st_size / 1024
        except OSError:
            continue
        if size > limit_kb:
            add(f"file besar ter-commit: {f} ({size:.0f} KB)")


# ---------------------------------------------------------------------------
# 9. Versi Flutter/Java seragam di workflow
# ---------------------------------------------------------------------------
def check_workflows() -> None:
    flutter: dict[str, list[str]] = {}
    java: dict[str, list[str]] = {}

    for wf in sorted(WORKFLOWS.glob("*.yml")):
        text = read(wf)
        for m in re.finditer(r"flutter-version:\s*[\"']?([0-9.]+)", text):
            flutter.setdefault(m.group(1), []).append(wf.name)
        for m in re.finditer(r"java-version:\s*[\"']?([0-9]+)", text):
            java.setdefault(m.group(1), []).append(wf.name)

        # melos harus dipin agar perilakunya tidak berubah diam-diam
        for m in re.finditer(r"pub global activate melos(.*)", text):
            rest = m.group(1).strip()
            if not re.match(r"^[0-9]", rest):
                add(f"{wf.name}: 'melos' tidak dipin versinya "
                    f"-> perilaku bisa berubah tanpa perubahan kode")

    for name, seen in (("Flutter", flutter), ("Java", java)):
        if len(seen) > 1:
            detail = ", ".join(f"{v}=[{','.join(w)}]" for v, w in sorted(seen.items()))
            add(f"versi {name} berbeda antar workflow: {detail}")


def main() -> int:
    apps = check_apps()
    check_main_activity(apps)
    check_google_services(apps)
    check_secrets()
    check_dependency_versions()
    check_toolchain(apps)
    check_large_files()
    check_workflows()

    verbose = "--verbose" in sys.argv
    if verbose and notes:
        print("Catatan:")
        for n in notes:
            print(f"  - {n}")
        print()

    if problems:
        print(f"{len(problems)} masalah struktur:\n")
        for p in problems:
            print(f"  ! {p}")
        return 1

    print("OK - struktur repo sehat.")
    print(f"  {len(apps)} app diperiksa, 9 kelompok pemeriksaan.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
