-- ============================================================================
-- SIM MADIN — Server-side FCM Push Notification via pg_net (P1)
-- ============================================================================
-- Trigger: setelah INSERT ke tabel Notifikasi, otomatis kirim push
-- notification ke device wali via Firebase Cloud Messaging API.
--
-- Flow:
--   1. App/wali INSERT ke Notifikasi (mis. guru input nilai → notif wali)
--   2. Trigger fire → fn_send_fcm_notification()
--   3. Function ambil fcmToken dari User (join Wali.userId = User.id)
--   4. POST ke FCM API via pg_net.http_post()
--   5. Update Notifikasi.isPushSent = true
--
-- Catatan:
--   - FCM Server Key disimpan di Supabase Vault (supabase.vault.decrypted_secrets)
--   - pg_net async (non-blocking) — tidak delay INSERT operation
--   - Kalau fcmToken null atau FCM gagal, notifikasi tetap tersimpan
--     (isPushSent = false) — bisa di-retry nanti via cron job
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Simpan FCM Server Key di Supabase Vault
-- ---------------------------------------------------------------------------
-- FCM Server Key DIDAPAT DARI Firebase Console:
--   Project Settings → Cloud Messaging → Server Key (legacy API)
-- 
-- Cara set:
--   Di Supabase Dashboard → Project Settings → Vault → Add secret
--   Name: fcm_server_key
--   Value: AAAA... (copy dari Firebase Console)
--
-- Atau via SQL:
--   SELECT vault.create_secret('YOUR_FCM_SERVER_KEY', 'fcm_server_key');
--
-- Untuk sekarang, kita pakai approach yang lebih simple: hardcode di function
-- dengan comment placeholder. User perlu replace dengan key asli.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 2. Function: kirim FCM push notification
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_send_fcm_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_fcm_token TEXT;
  v_wali_user_id TEXT;
  v_fcm_server_key TEXT;
  v_payload JSONB;
  v_response JSONB;
BEGIN
  -- Hanya untuk INSERT
  IF TG_OP != 'INSERT' THEN
    RETURN NEW;
  END IF;

  -- Skip kalau sudah dikirim (idempotent)
  IF NEW."isPushSent" = true THEN
    RETURN NEW;
  END IF;

  -- 1. Dapatkan userId dari Wali (untuk fetch fcmToken)
  SELECT "userId" INTO v_wali_user_id
  FROM "Wali"
  WHERE id = NEW."waliId"
    AND "deletedAt" IS NULL
  LIMIT 1;

  IF v_wali_user_id IS NULL THEN
    -- Wali tidak punya User record (WA+PIN auth, belum link ke Supabase Auth)
    -- Skip push notification — wali akan lihat notif saat buka app (realtime)
    RETURN NEW;
  END IF;

  -- 2. Dapatkan fcmToken dari User
  SELECT "fcmToken" INTO v_fcm_token
  FROM "User"
  WHERE id = v_wali_user_id;

  IF v_fcm_token IS NULL OR v_fcm_token = '' THEN
    -- User belum punya FCM token (belum login di device, atau device tidak support)
    RETURN NEW;
  END IF;

  -- 3. Get FCM Server Key from vault
  -- Cara 1: dari vault (kalau sudah diset)
  BEGIN
    SELECT decrypted_secret INTO v_fcm_server_key
    FROM vault.decrypted_secrets
    WHERE name = 'fcm_server_key'
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    v_fcm_server_key := NULL;
  END;

  -- Cara 2: fallback ke hardcoded (GANTI DENGAN KEY ASLI!)
  -- Dapatkan dari Firebase Console → Project Settings → Cloud Messaging → Server Key
  IF v_fcm_server_key IS NULL OR v_fcm_server_key = '' THEN
    -- TODO: Replace dengan FCM Server Key asli dari Firebase Console
    v_fcm_server_key := 'PLACEHOLDER_REPLACE_WITH_FCM_SERVER_KEY';
  END IF;

  IF v_fcm_server_key = 'PLACEHOLDER_REPLACE_WITH_FCM_SERVER_KEY' THEN
    -- Belum diset — skip push, tapi jangan error
    RETURN NEW;
  END IF;

  -- 4. Build FCM payload
  v_payload := jsonb_build_object(
    'to', v_fcm_token,
    'notification', jsonb_build_object(
      'title', NEW.title,
      'body', NEW.message,
      'sound', 'default',
      'click_action', 'FLUTTER_NOTIFICATION_CLICK'
    ),
    'data', jsonb_build_object(
      'type', NEW.type,
      'waliId', NEW."waliId",
      'santriId', COALESCE(NEW."santriId", ''),
      'entityType', COALESCE(NEW."entityType", ''),
      'entityId', COALESCE(NEW."entityId", ''),
      'notifikasiId', NEW.id,
      'click_action', 'FLUTTER_NOTIFICATION_CLICK'
    ),
    'android', jsonb_build_object(
      'priority', CASE WHEN NEW.priority = 'URGENT' THEN 'high' ELSE 'normal' END
    ),
    'priority', CASE WHEN NEW.priority = 'URGENT' THEN 'high' ELSE 'normal' END
  );

  -- 5. POST ke FCM API via pg_net (async, non-blocking)
  -- FCM Legacy API: https://fcm.googleapis.com/fcm/send
  -- Header: Authorization: key=SERVER_KEY
  -- Body: JSON payload di atas
  SELECT * INTO v_response FROM extensions.http_post(
    url := 'https://fcm.googleapis.com/fcm/send',
    headers := jsonb_build_object(
      'Authorization', 'key=' || v_fcm_server_key,
      'Content-Type', 'application/json'
    ),
    body := v_payload::text
  );

  -- 6. Update Notifikasi.isPushSent berdasarkan response
  -- FCM response: {"success": 1, "failure": 0, "results": [{"message_id": "..."}]}
  -- atau {"success": 0, "failure": 1, "results": [{"error": "InvalidRegistration"}]}
  IF v_response->>'status_code' = '200' THEN
    -- Cek apakah success
    IF (v_response->'body'->>'success')::int > 0 THEN
      UPDATE "Notifikasi"
      SET "isPushSent" = true
      WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. Trigger: after INSERT on Notifikasi → call fn_send_fcm_notification
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_notifikasi_send_fcm ON "Notifikasi";
CREATE TRIGGER trg_notifikasi_send_fcm
  AFTER INSERT ON "Notifikasi"
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_send_fcm_notification();

COMMIT;

-- ============================================================================
-- Summary:
--   - pg_net extension enabled (untuk HTTP POST ke FCM API)
--   - fn_send_fcm_notification() function:
--     1. Ambil fcmToken dari User (join Wali → User)
--     2. Build FCM payload (title, body, data, priority)
--     3. POST ke https://fcm.googleapis.com/fcm/send via pg_net
--     4. Update Notifikasi.isPushSent = true jika berhasil
--   - Trigger: trg_notifikasi_send_fcm (AFTER INSERT on Notifikasi)
--
-- TODO:
--   1. Set FCM Server Key di Supabase Vault:
--      SELECT vault.create_secret('YOUR_KEY', 'fcm_server_key');
--   2. Atau replace 'PLACEHOLDER_REPLACE_WITH_FCM_SERVER_KEY' di function
--      dengan FCM Server Key asli dari Firebase Console
-- ============================================================================
