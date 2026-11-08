#!/usr/bin/env python3
"""Generate adaptive launcher icons (Android 8+) untuk semua app mobile.

MASALAH YANG DIPERBAIKI
-----------------------
Keempat app hanya punya `mipmap-*/ic_launcher.png` lama (legacy) dengan
latar PUTIH PENUH sampai ke tepi. Di Android 8+ launcher mengambil ikon
legacy itu lalu mem-mask-nya menjadi lingkaran/rounded-square. Karena
gambarnya putih dan latarnya juga putih, hasilnya tampak seperti lingkaran
putih kosong — ikon aplikasi "tidak muncul".

Solusi: adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`) berisi:
  * background : warna solid (putih, sesuai desain asli)
  * foreground : artwork dengan latar putih dibuat transparan, dan
                 diperkecil ke dalam safe zone (66/108 dp) supaya tidak
                 terpotong oleh mask launcher apa pun.

Skrip ini murni Python (tanpa Pillow) supaya bisa jalan di CI.

Pemakaian:
    python3 tool/gen_adaptive_icons.py
"""

from __future__ import annotations

import os
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

APPS = ["mobile_wali", "mobile_guru", "mobile_kepala", "mobile_bendahara",
        "admin_desktop"]

# Kerapatan -> ukuran canvas adaptive icon (108dp)
DENSITIES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}

# Artwork menempati 60% canvas; safe zone Android 66/108 = 61.1%
ARTWORK_RATIO = 0.60

# Ambang "putih" yang dijadikan transparan
WHITE_MIN = 244
# Batas transisi supaya tepi artwork tidak bergerigi
WHITE_FEATHER = (236, 248)


# ---------------------------------------------------------------------------
# PNG decode / encode (pure Python)
# ---------------------------------------------------------------------------

def read_png(path: str):
    """Kembalikan (width, height, RGBA bytes)."""
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} bukan PNG")

    pos = 8
    idat = b""
    width = height = bit_depth = color_type = None
    palette = None
    trns = None

    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        ctype = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 12 + length

        if ctype == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk[:10])
            interlace = chunk[12]
            if interlace:
                raise ValueError("PNG interlace tidak didukung")
        elif ctype == b"PLTE":
            palette = chunk
        elif ctype == b"tRNS":
            trns = chunk
        elif ctype == b"IDAT":
            idat += chunk
        elif ctype == b"IEND":
            break

    if bit_depth != 8:
        raise ValueError(f"{path}: bit depth {bit_depth} tidak didukung")

    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[color_type]
    raw = zlib.decompress(idat)
    stride = width * channels
    bpp = channels

    rows: list[bytearray] = []
    prev = bytearray(stride)
    i = 0
    for _ in range(height):
        filt = raw[i]
        i += 1
        line = bytearray(raw[i : i + stride])
        i += stride
        if filt == 1:
            for x in range(bpp, stride):
                line[x] = (line[x] + line[x - bpp]) & 0xFF
        elif filt == 2:
            for x in range(stride):
                line[x] = (line[x] + prev[x]) & 0xFF
        elif filt == 3:
            for x in range(stride):
                a = line[x - bpp] if x >= bpp else 0
                line[x] = (line[x] + ((a + prev[x]) >> 1)) & 0xFF
        elif filt == 4:
            for x in range(stride):
                a = line[x - bpp] if x >= bpp else 0
                b = prev[x]
                c = prev[x - bpp] if x >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[x] = (line[x] + pr) & 0xFF
        rows.append(line)
        prev = line

    # Normalisasi ke RGBA
    out = bytearray(width * height * 4)
    for y in range(height):
        line = rows[y]
        for x in range(width):
            o = (y * width + x) * 4
            if color_type == 6:
                out[o : o + 4] = line[x * 4 : x * 4 + 4]
            elif color_type == 2:
                out[o : o + 3] = line[x * 3 : x * 3 + 3]
                out[o + 3] = 255
            elif color_type == 0:
                v = line[x]
                out[o] = out[o + 1] = out[o + 2] = v
                out[o + 3] = 255
            elif color_type == 4:
                out[o : o + 3] = bytes([line[x * 2]] * 3)
                out[o + 3] = line[x * 2 + 1]
            elif color_type == 3:
                idx = line[x]
                out[o : o + 3] = palette[idx * 3 : idx * 3 + 3]
                out[o + 3] = trns[idx] if trns and idx < len(trns) else 255

    return width, height, bytes(out)


def write_png(path: str, width: int, height: int, rgba: bytes) -> None:
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)  # filter None
        raw += rgba[y * stride : (y + 1) * stride]

    def chunk(tag: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + tag
            + payload
            + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
        )

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")

    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "wb").write(png)


# ---------------------------------------------------------------------------
# Image ops
# ---------------------------------------------------------------------------

def whiten_to_alpha(w: int, h: int, rgba: bytes) -> bytes:
    """Ubah latar putih menjadi transparan (dengan feather di tepi)."""
    lo, hi = WHITE_FEATHER
    out = bytearray(rgba)
    for i in range(0, len(out), 4):
        r, g, b = out[i], out[i + 1], out[i + 2]
        lum = min(r, g, b)
        if lum >= hi:
            out[i + 3] = 0
        elif lum <= lo:
            out[i + 3] = 255
        else:
            # transisi linear
            t = (hi - lum) / (hi - lo)
            out[i + 3] = int(255 * t)
    return bytes(out)


def resize_bilinear(w: int, h: int, rgba: bytes, nw: int, nh: int) -> bytes:
    out = bytearray(nw * nh * 4)
    x_ratio = (w - 1) / max(1, nw - 1)
    y_ratio = (h - 1) / max(1, nh - 1)

    for y in range(nh):
        sy = y * y_ratio
        y0 = int(sy)
        y1 = min(y0 + 1, h - 1)
        fy = sy - y0
        for x in range(nw):
            sx = x * x_ratio
            x0 = int(sx)
            x1 = min(x0 + 1, w - 1)
            fx = sx - x0

            o00 = (y0 * w + x0) * 4
            o01 = (y0 * w + x1) * 4
            o10 = (y1 * w + x0) * 4
            o11 = (y1 * w + x1) * 4
            d = (y * nw + x) * 4

            for c in range(4):
                top = rgba[o00 + c] * (1 - fx) + rgba[o01 + c] * fx
                bot = rgba[o10 + c] * (1 - fx) + rgba[o11 + c] * fx
                out[d + c] = int(top * (1 - fy) + bot * fy + 0.5)
    return bytes(out)


def build_foreground(src: str, canvas: int) -> bytes:
    """Artwork transparan, diskalakan ke tengah canvas."""
    w, h, rgba = read_png(src)
    rgba = whiten_to_alpha(w, h, rgba)

    target = max(1, int(canvas * ARTWORK_RATIO))
    scaled = resize_bilinear(w, h, rgba, target, target)

    out = bytearray(canvas * canvas * 4)  # transparan
    off = (canvas - target) // 2
    for y in range(target):
        src_row = y * target * 4
        dst_row = ((y + off) * canvas + off) * 4
        out[dst_row : dst_row + target * 4] = scaled[src_row : src_row + target * 4]

    return bytes(out)


def build_legacy(src: str, size: int) -> bytes:
    """Ikon legacy: artwork di atas latar putih, aman untuk launcher lama."""
    w, h, rgba = read_png(src)
    fg_alpha = whiten_to_alpha(w, h, rgba)

    target = max(1, int(size * 0.92))
    scaled = resize_bilinear(w, h, fg_alpha, target, target)
    off = (size - target) // 2

    out = bytearray()
    for y in range(size):
        for x in range(size):
            # latar putih
            r = g = b = 255
            a = 255
            sx, sy = x - off, y - off
            if 0 <= sx < target and 0 <= sy < target:
                o = (sy * target + sx) * 4
                sa = scaled[o + 3] / 255
                if sa > 0:
                    r = int(scaled[o] * sa + r * (1 - sa))
                    g = int(scaled[o + 1] * sa + g * (1 - sa))
                    b = int(scaled[o + 2] * sa + b * (1 - sa))
            out += bytes([r, g, b, a])
    return bytes(out)


ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<!-- Adaptive icon (Android 8+ / API 26).

     Tanpa file ini launcher akan mem-mask ic_launcher.png lama (latar putih
     penuh) menjadi lingkaran putih sehingga ikon tampak kosong. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""

COLORS_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Latar adaptive launcher icon. Putih mengikuti desain artwork asli. -->
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
"""


def process_app(app: str) -> None:
    res = os.path.join(ROOT, "apps", app, "android", "app", "src", "main", "res")
    src = os.path.join(ROOT, "apps", app, "assets", "logo-madrasah.png")

    if not os.path.exists(src):
        print(f"  ! {app}: {src} tidak ada, dilewati")
        return

    # 1. foreground adaptive + ic_launcher legacy per kerapatan
    for density, canvas in DENSITIES.items():
        d = os.path.join(res, f"mipmap-{density}")

        fg = build_foreground(src, canvas)
        write_png(os.path.join(d, "ic_launcher_foreground.png"), canvas, canvas, fg)

        legacy_size = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}[density]
        legacy = build_legacy(src, legacy_size)
        write_png(os.path.join(d, "ic_launcher.png"), legacy_size, legacy_size, legacy)

        round_size = legacy_size
        write_png(os.path.join(d, "ic_launcher_round.png"), round_size, round_size, legacy)

    # 2. adaptive icon XML
    anydpi = os.path.join(res, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        open(os.path.join(anydpi, name), "w", encoding="utf-8").write(ADAPTIVE_XML)

    # 3. warna latar
    values = os.path.join(res, "values")
    os.makedirs(values, exist_ok=True)
    open(os.path.join(values, "colors.xml"), "w", encoding="utf-8").write(COLORS_XML)

    print(f"  ok {app}: adaptive + legacy icons (5 kerapatan)")


def ensure_round_icon(app: str) -> None:
    """Tambahkan android:roundIcon bila belum ada."""
    manifest = os.path.join(
        ROOT, "apps", app, "android", "app", "src", "main", "AndroidManifest.xml"
    )
    src = open(manifest, encoding="utf-8").read()
    if "android:roundIcon" in src:
        return
    marker = 'android:icon="@mipmap/ic_launcher"'
    if marker not in src:
        print(f"  ! {app}: pola android:icon tidak ditemukan")
        return
    src = src.replace(
        marker,
        marker + '\n        android:roundIcon="@mipmap/ic_launcher_round"',
        1,
    )
    open(manifest, "w", encoding="utf-8").write(src)
    print(f"  ok {app}: android:roundIcon ditambahkan")


def main() -> int:
    print("Generate adaptive launcher icons")
    for app in APPS:
        process_app(app)
        ensure_round_icon(app)
    print("Selesai.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
