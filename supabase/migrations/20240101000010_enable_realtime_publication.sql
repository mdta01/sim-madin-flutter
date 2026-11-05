-- ============================================================================
-- SIM MADIN — Enable Supabase Realtime for all subscribed tables
-- ============================================================================
-- Secara default, Supabase tidak meng-enable realtime untuk tabel apapun
-- (alasan keamanan). Aplikasi SIM MADIN subscribe ke 27 tabel untuk fitur:
--   - mobile_wali:    Notifikasi, ChatRoom, ChatMessage, Tagihan, Payment,
--                      Absensi, Nilai, Perkembangan* (4 jenis), UjianPeserta, UjianSesi
--   - mobile_guru:    Jadwal, Materi, Tugas, Pertemuan, Ujian, UjianSoal,
--                      PengumpulanTugas, ChatRoom, ChatMessage, Absensi, Nilai,
--                      Perkembangan* (4 jenis), Pengumuman, BankSoal
--   - mobile_kepala:  Santri, Payment, Tagihan, HonorGuru, Absensi, Nilai,
--                      Kas, TransaksiKas, Guru, Jadwal
--   - mobile_bendahara: Payment, Tagihan, HonorGuru, Kas, TransaksiKas,
--                      Santri, Guru
--
-- Tanpa realtime, UI mobile apps TIDAK akan auto-refresh saat admin insert/
-- update data di admin_desktop. User harus pull-to-refresh manual.
--
-- Migration ini idempotent — aman re-run. Pakai PL/pgSQL exception handler
-- untuk skip tabel yang sudah ada di publication (Postgres tidak support
-- IF NOT EXISTS syntax di ALTER PUBLICATION ... ADD TABLE).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Pastikan publication 'supabase_realtime' ada (default Supabase)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    -- Publication standar Supabase: publish inserts, updates, deletes
    CREATE PUBLICATION supabase_realtime
      WITH (publish = 'insert, update, delete, truncate');
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. Tambahkan 33 tabel ke publication (idempotent via exception handler)
-- ----------------------------------------------------------------------------
-- Catatan: Postgres TIDAK support `ALTER PUBLICATION ... ADD TABLE IF NOT EXISTS`
-- jadi kita pakai PL/pgSQL DO block dengan exception handling untuk skip
-- tabel yang sudah ada di publication (error: duplicate_table_in_publication).
-- Ini aman re-run tanpa error.

DO $$
DECLARE
  tbl_name TEXT;
  tables TEXT[] := ARRAY[
    'Santri', 'Guru', 'Kelas', 'MataPelajaran', 'Jadwal',
    'Materi', 'Tugas', 'Pertemuan', 'Absensi', 'Nilai',
    'Ujian', 'UjianSoal', 'UjianPeserta', 'UjianSesi', 'UjianJawaban',
    'UjianNilai', 'BankSoal', 'PengumpulanTugas',
    'PerkembanganQuran', 'HafalanKitab', 'AkhlakPenilaian', 'Pembinaan',
    'Tagihan', 'Payment', 'Kas', 'TransaksiKas', 'HonorGuru',
    'Announcement', 'Notifikasi', 'Surat',
    'ChatRoom', 'ChatMessage', 'AuditLog', 'Alumni'
  ];
BEGIN
  FOREACH tbl_name IN ARRAY tables LOOP
    BEGIN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        tbl_name
      );
      RAISE NOTICE 'Added % to supabase_realtime', tbl_name;
    EXCEPTION
      WHEN duplicate_table THEN
        -- Table already in publication — skip silently
        NULL;
      WHEN OTHERS THEN
        -- Other errors — log but don't fail migration
        RAISE NOTICE 'Skipped %: %', tbl_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- ----------------------------------------------------------------------------
-- 3. Reload PostgREST schema cache (so REST API picks up any changes)
-- ----------------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification (run after this migration):
--   SELECT count(*) FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
--   Expected: 33 tables
-- ============================================================================
