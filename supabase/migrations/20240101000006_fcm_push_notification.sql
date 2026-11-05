-- ============================================================================
-- SIM MADIN — FCM Push Notification via Edge Function (P1)
-- ============================================================================
-- Trigger: setelah INSERT ke tabel Notifikasi, otomatis kirim push
-- notification ke device wali via Supabase Edge Function + FCM v1 API.
--
-- Flow:
--   1. INSERT ke Notifikasi → trigger fire
--   2. fn_send_fcm_notification() ambil fcmToken dari User
--   3. pg_net POST ke Edge Function (https://{ref}.supabase.co/functions/v1/send-fcm-notification)
--   4. Edge Function kirim ke FCM v1 API via firebase-admin
--   5. Update Notifikasi.isPushSent = true jika berhasil
--
-- Catatan:
--   - FCM Legacy API (Server Key) sudah deprecated sejak June 2024
--   - FCM v1 API pakai OAuth2 access token (bukan Server Key statis)
--   - Edge Function pakai firebase-admin SDK untuk handle OAuth2 otomatis
--   - FIREBASE_SERVICE_ACCOUNT JSON disimpan di Supabase secrets
-- ============================================================================

BEGIN;

-- pg_net extension (sudah enabled)
CREATE EXTENSION IF NOT EXISTS pg_net SCHEMA extensions;

-- ---------------------------------------------------------------------------
-- Function: kirim FCM via Edge Function
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
  v_edge_function_url TEXT;
  v_payload JSONB;
  v_response JSONB;
BEGIN
  IF TG_OP != 'INSERT' THEN
    RETURN NEW;
  END IF;

  IF NEW."isPushSent" = true THEN
    RETURN NEW;
  END IF;

  -- 1. Dapatkan userId dari Wali
  SELECT "userId" INTO v_wali_user_id
  FROM "Wali"
  WHERE id = NEW."waliId"
    AND "deletedAt" IS NULL
  LIMIT 1;

  IF v_wali_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- 2. Dapatkan fcmToken dari User
  SELECT "fcmToken" INTO v_fcm_token
  FROM "User"
  WHERE id = v_wali_user_id;

  IF v_fcm_token IS NULL OR v_fcm_token = '' THEN
    RETURN NEW;
  END IF;

  -- 3. Build payload untuk Edge Function
  v_payload := jsonb_build_object(
    'fcm_token', v_fcm_token,
    'title', NEW.title,
    'body', NEW.message,
    'priority', COALESCE(NEW.priority, 'NORMAL'),
    'data', jsonb_build_object(
      'type', NEW.type,
      'waliId', NEW."waliId",
      'santriId', COALESCE(NEW."santriId", ''),
      'entityType', COALESCE(NEW."entityType", ''),
      'entityId', COALESCE(NEW."entityId", ''),
      'notifikasiId', NEW.id,
      'click_action', 'FLUTTER_NOTIFICATION_CLICK'
    )
  );

  -- 4. Call Supabase Edge Function via pg_net
  v_edge_function_url := 'https://bhogtbhzeoxsowcbspjr.supabase.co/functions/v1/send-fcm-notification';

  SELECT * INTO v_response FROM extensions.http_post(
    url := v_edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJob2d0YmhoemVveHNvd2Nic3BqciIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzI5OTU5MjE3LCJleHAiOjIwNDUzMzUyMTd9.q0nTj2cVD6Vk1YBm4PjK6K5v4vLqP1Ph8cYKQ3qWJ8c'
    ),
    body := v_payload::text
  );

  -- 5. Update isPushSent berdasarkan response
  IF v_response->>'status_code' = '200' THEN
    IF (v_response->'body'->>'success')::boolean = true THEN
      UPDATE "Notifikasi"
      SET "isPushSent" = true
      WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger (sudah ada, recreate untuk pastikan latest version)
DROP TRIGGER IF EXISTS trg_notifikasi_send_fcm ON "Notifikasi";
CREATE TRIGGER trg_notifikasi_send_fcm
  AFTER INSERT ON "Notifikasi"
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_send_fcm_notification();

COMMIT;
