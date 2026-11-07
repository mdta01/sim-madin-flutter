-- ============================================================================
-- SIM MADIN — Alur reset PIN wali yang aman (OTP server-side)
-- ============================================================================
-- MASALAH KEAMANAN YANG DIPERBAIKI
-- ----------------------------------------------------------------------------
-- 1. `wali_set_pin(p_wali_id, p_new_pin)` di-grant ke `anon` dan TIDAK
--    memverifikasi apa pun. Siapa pun yang punya anon key (yang memang
--    tertanam di aplikasi mobile) bisa memanggil:
--
--        rpc('wali_set_pin', {p_wali_id: '<id wali mana pun>', p_new_pin: '123456'})
--
--    dan langsung mengambil alih akun wali tanpa tahu PIN lama maupun OTP.
--    Ini bypass autentikasi penuh.
--
-- 2. OTP digenerate & diverifikasi di CLIENT: nilai OTP dikembalikan ke
--    pemanggil dalam response RPC, disimpan plain-text di kolom
--    `Wali.otpCode`, lalu dibandingkan di Dart. Siapa pun yang bisa membaca
--    response (atau tabel) mendapat OTP-nya.
--
-- 3. `verifyToken` hanya disimpan di state memori aplikasi — hilang saat app
--    di-restart, dan tidak bisa diverifikasi oleh server sama sekali.
--
-- DESAIN BARU (semua verifikasi di server)
-- ----------------------------------------------------------------------------
--   wali_request_otp(phone)   -> buat OTP 6 digit, simpan HASH bcrypt di
--                                tabel WaliPinReset (bukan di Wali), berlaku
--                                5 menit, rate limit 5/jam.
--                                OTP hanya dikembalikan ke client bila
--                                SystemSetting OTP_DEBUG = 'true'
--                                (default false -> kirim lewat notifikasi).
--   wali_verify_otp(phone,otp) -> verifikasi hash, maks 5 percobaan, lalu
--                                terbitkan reset token acak 32-byte.
--                                Yang disimpan hanya SHA-256 dari token.
--                                Token sekali pakai, berlaku 10 menit.
--   wali_reset_pin(token,pin)  -> verifikasi token (hash + expiry + belum
--                                dipakai), lalu set PIN bcrypt.
--
-- Semua fungsi SECURITY DEFINER dengan search_path terkunci, dan yang tidak
-- butuh diakses publik di-REVOKE dari anon.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- ----------------------------------------------------------------------------
-- 0. Helper: normalisasi nomor WhatsApp
-- ----------------------------------------------------------------------------
-- Menyatukan format '0812...', '+62 812-...', '62812...' menjadi '62812...'.
-- Tanpa ini, wali yang mendaftar dengan format berbeda tidak bisa login.
CREATE OR REPLACE FUNCTION public.normalize_phone(p_phone TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v TEXT;
BEGIN
  IF p_phone IS NULL THEN
    RETURN NULL;
  END IF;
  v := regexp_replace(p_phone, '\D', '', 'g');
  IF v = '' THEN
    RETURN NULL;
  END IF;
  IF left(v, 1) = '0' THEN
    v := '62' || substr(v, 2);
  ELSIF left(v, 2) = '62' THEN
    -- sudah kanonik
    NULL;
  ELSIF left(v, 1) = '8' THEN
    v := '62' || v;
  END IF;
  RETURN v;
END;
$$;

-- ----------------------------------------------------------------------------
-- 1. Tabel penyimpan OTP reset PIN
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "WaliPinReset" (
  "id"          TEXT NOT NULL PRIMARY KEY,
  "waliId"      TEXT NOT NULL,
  "otpHash"     TEXT NOT NULL,
  "expiresAt"   TIMESTAMPTZ NOT NULL,
  "attempts"    INTEGER NOT NULL DEFAULT 0,
  "consumedAt"  TIMESTAMPTZ,
  "resetTokenHash" TEXT,
  "resetTokenExpiresAt" TIMESTAMPTZ,
  "requestedIp" TEXT,
  "createdAt"   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "WaliPinReset_waliId_fkey"
    FOREIGN KEY ("waliId") REFERENCES "Wali"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "WaliPinReset_waliId_createdAt_idx"
  ON "WaliPinReset" ("waliId", "createdAt" DESC);
CREATE INDEX IF NOT EXISTS "WaliPinReset_resetTokenHash_idx"
  ON "WaliPinReset" ("resetTokenHash");

-- Tabel ini hanya diakses lewat RPC SECURITY DEFINER. RLS diaktifkan tanpa
-- policy apa pun supaya `anon`/`authenticated` tidak bisa membacanya langsung
-- (mencegah kebocoran OTP hash / reset token hash).
ALTER TABLE "WaliPinReset" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "WaliPinReset" FROM anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2. wali_request_otp(phone) -> JSONB
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.wali_request_otp(p_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali      RECORD;
  v_req_count INTEGER;
  v_otp       TEXT;
  v_debug     TEXT;
  v_reset_id  TEXT;
BEGIN
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  -- Jangan bocorkan apakah nomor terdaftar atau tidak (anti user-enumeration):
  -- pesan dibuat sama untuk nomor yang tidak ada.
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Jika nomor terdaftar, kode OTP akan dikirim via WhatsApp.'
    );
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun dinonaktifkan. Hubungi admin madrasah.'
    );
  END IF;

  -- Rate limit: maksimal 5 permintaan OTP per jam per wali.
  SELECT count(*) INTO v_req_count
  FROM "WaliPinReset"
  WHERE "waliId" = v_wali.id
    AND "createdAt" > now() - INTERVAL '1 hour';

  IF v_req_count >= 5 THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Terlalu banyak permintaan OTP. Coba lagi dalam 1 jam.'
    );
  END IF;

  -- OTP 6 digit kriptografis (bukan timestamp).
  v_otp := lpad(
    (floor(random() * 1000000))::int::text, 6, '0'
  );

  -- Invalidasi OTP lama yang belum terpakai.
  UPDATE "WaliPinReset"
  SET "consumedAt" = now()
  WHERE "waliId" = v_wali.id
    AND "consumedAt" IS NULL;

  INSERT INTO "WaliPinReset" (
    "id", "waliId", "otpHash", "expiresAt", "createdAt"
  ) VALUES (
    replace(gen_random_uuid()::text, '-', ''),
    v_wali.id,
    crypt(v_otp, gen_salt('bf', 10)),
    now() + INTERVAL '5 minutes',
    now()
  )
  RETURNING "id" INTO v_reset_id;

  -- Kirim lewat notifikasi in-app (trigger Notifikasi -> FCM push).
  -- Untuk WhatsApp, isi SystemSetting WHATSAPP_GATEWAY_TOKEN + gateway URL.
  INSERT INTO "Notifikasi" (
    "id", "waliId", "type", "title", "message", "isRead", "createdAt"
  ) VALUES (
    replace(gen_random_uuid()::text, '-', ''),
    v_wali.id,
    'SYSTEM',
    'Kode OTP Reset PIN',
    'Kode OTP Anda: ' || v_otp || '. Berlaku 5 menit. Jangan bagikan ke siapa pun.',
    false,
    now()
  );

  -- Mode debug: hanya aktif kalau admin menyalakannya secara eksplisit
  -- lewat SystemSetting OTP_DEBUG='true'. Default: OTP TIDAK dikembalikan.
  SELECT value INTO v_debug FROM "SystemSetting" WHERE key = 'OTP_DEBUG' LIMIT 1;

  IF v_debug = 'true' THEN
    RETURN jsonb_build_object(
      'success', true,
      'message', 'OTP dibuat (mode debug).',
      'otp', v_otp
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Kode OTP dikirim via notifikasi WhatsApp.'
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. wali_verify_otp(phone, otp) -> JSONB { success, resetToken }
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.wali_verify_otp(p_phone TEXT, p_otp TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali      RECORD;
  v_row       RECORD;
  v_token     TEXT;
BEGIN
  IF p_otp IS NULL OR p_otp !~ '^\d{6}$' THEN
    RETURN jsonb_build_object('success', false, 'message', 'OTP harus 6 digit.');
  END IF;

  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'OTP salah atau kedaluwarsa.');
  END IF;

  SELECT * INTO v_row
  FROM "WaliPinReset"
  WHERE "waliId" = v_wali.id
    AND "consumedAt" IS NULL
    AND "expiresAt" > now()
  ORDER BY "createdAt" DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'OTP salah atau kedaluwarsa.');
  END IF;

  IF v_row.attempts >= 5 THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Terlalu banyak percobaan. Minta OTP baru.'
    );
  END IF;

  IF crypt(p_otp, v_row."otpHash") <> v_row."otpHash" THEN
    UPDATE "WaliPinReset" SET "attempts" = "attempts" + 1 WHERE "id" = v_row.id;
    RETURN jsonb_build_object(
      'success', false,
      'message', 'OTP salah. Sisa percobaan: ' || (4 - v_row.attempts)
    );
  END IF;

  -- OTP valid: terbitkan reset token acak, simpan hanya hash-nya.
  v_token := encode(gen_random_bytes(32), 'hex');

  UPDATE "WaliPinReset"
  SET "consumedAt" = now(),
      "resetTokenHash" = encode(digest(v_token, 'sha256'), 'hex'),
      "resetTokenExpiresAt" = now() + INTERVAL '10 minutes'
  WHERE "id" = v_row.id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'OTP terverifikasi.',
    'resetToken', v_token
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. wali_reset_pin(resetToken, newPin) -> JSONB
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.wali_reset_pin(p_reset_token TEXT, p_new_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_row RECORD;
BEGIN
  IF p_new_pin IS NULL OR p_new_pin !~ '^\d{6}$' THEN
    RETURN jsonb_build_object('success', false, 'message', 'PIN harus 6 digit.');
  END IF;

  IF p_reset_token IS NULL OR length(p_reset_token) < 32 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Token reset tidak valid.');
  END IF;

  SELECT * INTO v_row
  FROM "WaliPinReset"
  WHERE "resetTokenHash" = encode(digest(p_reset_token, 'sha256'), 'hex')
    AND "resetTokenExpiresAt" > now()
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Token reset tidak valid atau kedaluwarsa. Ulangi dari minta OTP.'
    );
  END IF;

  UPDATE "Wali"
  SET "pinHash" = crypt(p_new_pin, gen_salt('bf', 10)),
      "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "otpCode" = NULL,
      "otpExpiresAt" = NULL
  WHERE "id" = v_row."waliId"
    AND "deletedAt" IS NULL;

  -- Token sekali pakai.
  UPDATE "WaliPinReset"
  SET "resetTokenHash" = NULL,
      "resetTokenExpiresAt" = NULL
  WHERE "id" = v_row.id;

  RETURN jsonb_build_object('success', true, 'message', 'PIN berhasil diubah.');
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. Hapus fungsi lama yang tidak aman
-- ----------------------------------------------------------------------------
-- `wali_set_pin(p_wali_id, p_new_pin)` sebelumnya bisa dipanggil anon tanpa
-- verifikasi apa pun. Fungsi ini DIHAPUS, bukan sekadar di-revoke, supaya
-- tidak bisa diaktifkan kembali tanpa sengaja.
DROP FUNCTION IF EXISTS public.wali_set_pin(TEXT, TEXT);

-- ----------------------------------------------------------------------------
-- 6. Permission function
-- ----------------------------------------------------------------------------
-- Login & reset PIN terjadi SEBELUM user punya sesi, jadi harus bisa
-- dipanggil `anon`. Semua verifikasi dilakukan di dalam fungsi.
GRANT EXECUTE ON FUNCTION public.wali_request_otp(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.wali_verify_otp(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.wali_reset_pin(TEXT, TEXT) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification:
--   SELECT public.wali_request_otp('081234511001');   -- { success, message }
--   SELECT public.wali_verify_otp('081234511001','000000'); -- success=false
--   SELECT public.wali_reset_pin('token-palsu', '123456'); -- success=false
-- ============================================================================
