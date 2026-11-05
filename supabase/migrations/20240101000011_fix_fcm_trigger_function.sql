-- ============================================================================
-- SIM MADIN — Fix FCM trigger function (pg_net http_post body type bug)
-- ============================================================================
-- Bug 1: fn_send_fcm_notification() calls extensions.http_post() — WRONG.
--        pg_net installs in `net` schema, not `extensions`.
--        Fix: call net.http_post() instead.
--
-- Bug 2: body := v_payload::text — WRONG.
--        http_post expects body := jsonb, not text.
--        Fix: pass v_payload directly (already JSONB).
--
-- Bug 3: v_response JSONB — WRONG.
--        http_post returns bigint (request ID), not JSONB.
--        Fix: use v_request_id BIGINT.
--
-- Bug 4: Notifikasi table doesn't have "updatedAt" column.
--        The trg_upd BEFORE UPDATE trigger fires set_updated_at() which
--        does NEW."updatedAt" = now() → error "record new has no field updatedAt".
--        Fix: Add "updatedAt" column to Notifikasi (consistency with other tables).
--
-- Akibat bug ini: setiap INSERT ke Notifikasi GAGAL, sehingga:
--   - Realtime event untuk Notifikasi tidak pernah fire
--   - FCM push notification tidak pernah terkirim
--   - Admin desktop "Kirim Notifikasi" button error
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Add "updatedAt" column to Notifikasi (was missing — trg_upd trigger needs it)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'Notifikasi' AND column_name = 'updatedAt'
  ) THEN
    ALTER TABLE "Notifikasi" ADD COLUMN "updatedAt" TIMESTAMPTZ DEFAULT now();
    UPDATE "Notifikasi" SET "updatedAt" = "createdAt" WHERE "updatedAt" IS NULL;
    RAISE NOTICE 'Added updatedAt column to Notifikasi';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. Fix fn_send_fcm_notification() function:
--    - Use net.http_post (not extensions.http_post)
--    - Pass body as jsonb (not ::text cast)
--    - Use BIGINT for request ID (not JSONB for response)
--    - Fire-and-forget (don't block on response check)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_send_fcm_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, net
AS $$
DECLARE
  v_fcm_token TEXT;
  v_wali_user_id TEXT;
  v_edge_function_url TEXT;
  v_payload JSONB;
  v_request_id BIGINT;
BEGIN
  IF TG_OP != 'INSERT' THEN
    RETURN NEW;
  END IF;

  -- Skip kalau push sudah dikirim (re-trigger protection)
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

  -- 3. Build payload untuk Edge Function (FCM v1 REST API)
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

  -- 4. Call Supabase Edge Function via pg_net (fire-and-forget)
  -- pg_net http_post signature (in `net` schema, NOT `extensions`):
  --   net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout int)
  --   RETURNS bigint (request ID — async, response fetched separately)
  v_edge_function_url := 'https://bhogtbhzeoxsowcbspjr.supabase.co/functions/v1/send-fcm-notification';

  SELECT * INTO v_request_id FROM net.http_post(
    url := v_edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJob2d0YmhoemVveHNvd2Nic3BqciIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzI5OTU5MjE3LCJleHAiOjIwNDUzMzUyMTd9.q0nTj2cVD6Vk1YBm4PjK6K5v4vLqP1Ph8cYKQ3qWJ8c'
    ),
    body := v_payload  -- FIX: pass jsonb directly (v_payload already JSONB)
  );

  -- 5. Mark isPushSent = true (optimistic — request was queued successfully)
  IF v_request_id IS NOT NULL AND v_request_id > 0 THEN
    UPDATE "Notifikasi" SET "isPushSent" = true WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

-- Verify trigger still attached (idempotent check)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_notifikasi_send_fcm'
  ) THEN
    CREATE TRIGGER trg_notifikasi_send_fcm
      AFTER INSERT ON "Notifikasi"
      FOR EACH ROW
      EXECUTE FUNCTION public.fn_send_fcm_notification();
    RAISE NOTICE 'Created trigger trg_notifikasi_send_fcm';
  ELSE
    RAISE NOTICE 'Trigger trg_notifikasi_send_fcm already exists (function updated)';
  END IF;
END $$;

-- ============================================================================
-- Verification: test INSERT into Notifikasi (trigger should not fail now)
-- Run manually after migration:
--   INSERT INTO "Notifikasi" ("waliId", title, message, type, priority)
--   VALUES ('5aca1e3e-fcda-4455-b3a5-f962710d14a5', 'Test', 'FCM trigger fix', 'INFO', 'NORMAL');
-- ============================================================================
