-- ============================================================================
-- SIM MADIN — Lengkapi publication realtime
-- ============================================================================
-- Migration 10 menambahkan 33 tabel ke publication `supabase_realtime`, TAPI
-- daftar aplikasi (lihat packages/api_client/lib/realtime_coordinator.dart)
-- subscribe ke tabel yang BELUM ada di publication:
--
--   TahunAjaran, Semester, JenisTagihan, Wali          -> master data
--   User, UserRole, Role, RolePermission, SystemSetting -> admin_desktop
--   Kompetensi, Rapor                                   -> guru / admin
--
-- Tabel yang tidak ada di publication TIDAK memicu event realtime, dan
-- Supabase tidak melaporkan error apa pun — jadi gejalanya adalah "data baru
-- dari admin tidak muncul di app mobile" tanpa pesan kesalahan sama sekali.
--
-- Migration ini melengkapi daftar supaya SEMUA tabel yang di-subscribe
-- aplikasi benar-benar memancarkan perubahan. Idempotent: tabel yang sudah
-- ada di publication akan dilewati.
-- ============================================================================

DO $$
DECLARE
  tbl TEXT;
  tables TEXT[] := ARRAY[
    -- Master data (dipakai semua aplikasi)
    'TahunAjaran',
    'Semester',
    'JenisTagihan',
    'Wali',
    -- Admin desktop
    'User',
    'UserRole',
    'Role',
    'RolePermission',
    'SystemSetting',
    -- Akademik
    'Kompetensi',
    'Rapor',
    'CatatanWaliKelas',
    'PerkembanganQuran'
  ];
  added INT := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime
      WITH (publish = 'insert, update, delete, truncate');
  END IF;

  FOREACH tbl IN ARRAY tables LOOP
    -- Lewati tabel yang belum ada (mis. migration baseline belum jalan).
    IF to_regclass(format('public.%I', tbl)) IS NULL THEN
      RAISE NOTICE 'Lewati %: tabel belum ada', tbl;
      CONTINUE;
    END IF;

    -- Lewati kalau sudah terdaftar.
    IF EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = tbl
    ) THEN
      CONTINUE;
    END IF;

    BEGIN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl
      );
      added := added + 1;
      RAISE NOTICE 'Ditambahkan ke realtime: %', tbl;
    EXCEPTION
      WHEN duplicate_object THEN
        NULL; -- balapan dengan migrasi lain, aman diabaikan
      WHEN OTHERS THEN
        RAISE NOTICE 'Gagal menambahkan %: %', tbl, SQLERRM;
    END;
  END LOOP;

  RAISE NOTICE 'Selesai. % tabel baru ditambahkan ke publication.', added;
END $$;

-- Wajib: tanpa ini, PostgREST/Realtime masih memakai cache skema lama.
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification (harus mencakup semua tabel di realtime_coordinator.dart):
--   SELECT tablename FROM pg_publication_tables
--   WHERE pubname = 'supabase_realtime' ORDER BY tablename;
-- ============================================================================
