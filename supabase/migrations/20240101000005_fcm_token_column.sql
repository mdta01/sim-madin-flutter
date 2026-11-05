-- ============================================================================
-- SIM MADIN — FCM Token Column Migration (P1)
-- ============================================================================
-- Tambah kolom fcmToken ke tabel User untuk menyimpan Firebase Cloud
-- Messaging token. Dipakai untuk push notification saat app di background.
--
-- Jalankan di Supabase Dashboard SQL Editor.
-- ============================================================================

-- Tambah kolom fcmToken ke tabel User (nullable — tidak semua user punya FCM token)
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;

-- Update RLS policy: user bisa update fcmToken dirinya sendiri
-- (sudah covered oleh policy "user_admin_write" yang mengizinkan
-- is_admin() untuk update semua, tapi kita perlu policy khusus
-- untuk user update fcmToken dirinya sendiri)
CREATE POLICY "user_update_fcm_token_self"
  ON "User"
  FOR UPDATE TO authenticated
  USING (id = public.current_user_id())
  WITH CHECK (id = public.current_user_id());

-- Comment
COMMENT ON COLUMN "User"."fcmToken" IS
  'Firebase Cloud Messaging token untuk push notification. Null jika user belum login di device atau tidak ada FCM.';
