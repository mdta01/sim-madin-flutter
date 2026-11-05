-- ============================================================================
-- SIM MADIN — Fix Chat RLS: add INSERT policy for ChatMessage
-- ============================================================================
-- Bug: ChatMessage table hanya punya SELECT policy (`cm_wali`), tidak ada
-- INSERT policy. Akibatnya wali/guru tidak bisa kirim pesan chat — error
-- "new row violates row-level security policy for table ChatMessage".
--
-- Fix: tambah INSERT policy untuk wali + guru + staff.
-- Wali/guru bisa INSERT ke ChatMessage kalau mereka adalah peserta dari
-- ChatRoom tersebut (waliId = current_wali_id() OR guruId = current_guru_id()).
--
-- Idempotent — DROP IF EXISTS dulu.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ChatMessage INSERT policy untuk wali + guru + staff
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "cm_insert_participant" ON "ChatMessage";
CREATE POLICY "cm_insert_participant"
  ON "ChatMessage" FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Wali yang kirim: harus jadi peserta chat room (waliId = wali login)
    (has_role('WALI') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = current_wali_id()
        AND cr."isActive" = true
    ))
    -- Guru yang kirim: harus jadi peserta chat room (guruId = guru login)
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = current_guru_id()
        AND cr."isActive" = true
    ))
    -- Staff (admin/kepala/bendahara) bisa kirim ke chat manapun
    OR (is_staff())
  );

-- ----------------------------------------------------------------------------
-- 2. ChatMessage UPDATE policy (mark as read)
-- Wali bisa update isRead untuk pesan di chat room-nya sendiri.
-- Guru bisa update isRead untuk pesan di chat room-nya.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "cm_update_participant" ON "ChatMessage";
CREATE POLICY "cm_update_participant"
  ON "ChatMessage" FOR UPDATE
  TO authenticated
  USING (
    (has_role('WALI') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = current_wali_id()
    ))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = current_guru_id()
    ))
    OR is_staff()
  )
  WITH CHECK (
    (has_role('WALI') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = current_wali_id()
    ))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = current_guru_id()
    ))
    OR is_staff()
  );

-- ----------------------------------------------------------------------------
-- 3. ChatMessage DELETE policy — admin only (moderasi chat)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "cm_delete_admin" ON "ChatMessage";
CREATE POLICY "cm_delete_admin"
  ON "ChatMessage" FOR DELETE
  TO authenticated
  USING (is_admin_level());

-- ----------------------------------------------------------------------------
-- 4. Reload PostgREST schema cache
-- ----------------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification (run after migration):
--   SELECT policyname, cmd FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'ChatMessage' ORDER BY cmd;
-- ============================================================================
