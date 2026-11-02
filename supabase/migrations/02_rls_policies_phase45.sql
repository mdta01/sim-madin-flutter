-- ============================================================================
-- SIM MADIN — RLS Policies (Phase 4+ — mobile_guru + mobile_wali) v2
-- ============================================================================
-- Corrected column names based on actual DB schema inspection.
-- Key facts:
--   - UjianNilai, UjianSesi: direct ujianId + santriId (no pesertaId)
--   - UjianJawaban: sesiId + santriId + ujianSoalId
--   - ChatMessage: chatRoomId (not roomId), senderWaliId/senderGuruId
--   - Pertemuan, BankSoal, Kompetensi: no deletedAt column
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Materi (deletedAt exists)
-- ---------------------------------------------------------------------------

ALTER TABLE "Materi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "materi_staff_read" ON "Materi"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND public.is_staff());
CREATE POLICY "materi_wali_read" ON "Materi"
  FOR SELECT TO authenticated
  USING (
    "deletedAt" IS NULL
    AND public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Santri" s
      JOIN "SantriWali" sw ON sw."santriId" = s.id
      WHERE s."kelasId" = "Materi"."kelasId"
        AND sw."waliId" = public.current_wali_id()
        AND sw."canAccess" = true
    )
  );
CREATE POLICY "materi_guru_write" ON "Materi"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

-- ---------------------------------------------------------------------------
-- Pertemuan (no deletedAt)
-- ---------------------------------------------------------------------------

ALTER TABLE "Pertemuan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pertemuan_staff_read" ON "Pertemuan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "pertemuan_wali_read" ON "Pertemuan"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Santri" s
      JOIN "SantriWali" sw ON sw."santriId" = s.id
      WHERE s."kelasId" = "Pertemuan"."kelasId"
        AND sw."waliId" = public.current_wali_id()
        AND sw."canAccess" = true
    )
  );
CREATE POLICY "pertemuan_guru_write" ON "Pertemuan"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND public.is_guru_of_kelas("kelasId")
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND public.is_guru_of_kelas("kelasId")
    )
  );

-- ---------------------------------------------------------------------------
-- Tugas (deletedAt exists)
-- ---------------------------------------------------------------------------

ALTER TABLE "Tugas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tugas_staff_read" ON "Tugas"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND public.is_staff());
CREATE POLICY "tugas_wali_read" ON "Tugas"
  FOR SELECT TO authenticated
  USING (
    "deletedAt" IS NULL
    AND public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Santri" s
      JOIN "SantriWali" sw ON sw."santriId" = s.id
      WHERE s."kelasId" = "Tugas"."kelasId"
        AND sw."waliId" = public.current_wali_id()
        AND sw."canAccess" = true
    )
  );
CREATE POLICY "tugas_guru_write" ON "Tugas"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

-- ---------------------------------------------------------------------------
-- PengumpulanTugas (no deletedAt)
-- ---------------------------------------------------------------------------

ALTER TABLE "PengumpulanTugas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pengumpulan_staff_read" ON "PengumpulanTugas"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "pengumpulan_wali_read" ON "PengumpulanTugas"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "pengumpulan_guru_write" ON "PengumpulanTugas"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Tugas" t
      WHERE t.id = "PengumpulanTugas"."tugasId"
        AND t."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Tugas" t
      WHERE t.id = "PengumpulanTugas"."tugasId"
        AND t."guruId" = public.current_guru_id()
    )
  );

-- ---------------------------------------------------------------------------
-- Kompetensi, BankSoal (no deletedAt)
-- ---------------------------------------------------------------------------

ALTER TABLE "Kompetensi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "kompetensi_read" ON "Kompetensi"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "kompetensi_admin_write" ON "Kompetensi"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "BankSoal" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "bank_soal_read" ON "BankSoal"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "bank_soal_guru_write" ON "BankSoal"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

-- ---------------------------------------------------------------------------
-- Ujian (deletedAt exists)
-- ---------------------------------------------------------------------------

ALTER TABLE "Ujian" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_staff_read" ON "Ujian"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND public.is_staff());
CREATE POLICY "ujian_wali_read" ON "Ujian"
  FOR SELECT TO authenticated
  USING (
    "deletedAt" IS NULL
    AND public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "UjianPeserta" up
      WHERE up."ujianId" = "Ujian".id
        AND public.is_wali_of_santri(up."santriId")
    )
  );
CREATE POLICY "ujian_guru_write" ON "Ujian"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

-- ---------------------------------------------------------------------------
-- UjianSoal (no deletedAt)
-- ---------------------------------------------------------------------------

ALTER TABLE "UjianSoal" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_soal_staff_read" ON "UjianSoal"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_soal_wali_read" ON "UjianSoal"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Ujian" u
      JOIN "UjianPeserta" up ON up."ujianId" = u.id
      WHERE u.id = "UjianSoal"."ujianId"
        AND public.is_wali_of_santri(up."santriId")
    )
  );
CREATE POLICY "ujian_soal_guru_write" ON "UjianSoal"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianSoal"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianSoal"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  );

-- ---------------------------------------------------------------------------
-- UjianPeserta (no deletedAt)
-- ---------------------------------------------------------------------------

ALTER TABLE "UjianPeserta" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_peserta_staff_read" ON "UjianPeserta"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_peserta_wali_read" ON "UjianPeserta"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_peserta_guru_write" ON "UjianPeserta"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianPeserta"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianPeserta"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  );

-- ---------------------------------------------------------------------------
-- UjianNilai (no deletedAt, has ujianId + santriId directly)
-- ---------------------------------------------------------------------------

ALTER TABLE "UjianNilai" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_nilai_staff_read" ON "UjianNilai"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_nilai_wali_read" ON "UjianNilai"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_nilai_guru_write" ON "UjianNilai"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianNilai"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianNilai"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  );

-- ---------------------------------------------------------------------------
-- UjianSesi (no deletedAt, has ujianId + santriId directly)
-- ---------------------------------------------------------------------------

ALTER TABLE "UjianSesi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_sesi_staff_read" ON "UjianSesi"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_sesi_wali_read" ON "UjianSesi"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_sesi_wali_insert" ON "UjianSesi"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_sesi_wali_update" ON "UjianSesi"
  FOR UPDATE TO authenticated
  USING (
    public.is_admin_level()
    OR (
      public.has_role('WALI')
      AND public.is_wali_of_santri("santriId")
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('WALI')
      AND public.is_wali_of_santri("santriId")
    )
  );

-- ---------------------------------------------------------------------------
-- UjianJawaban (has sesiId + santriId + ujianSoalId)
-- ---------------------------------------------------------------------------

ALTER TABLE "UjianJawaban" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_jawaban_staff_read" ON "UjianJawaban"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_jawaban_wali_read" ON "UjianJawaban"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_jawaban_wali_insert" ON "UjianJawaban"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_jawaban_guru_update" ON "UjianJawaban"
  FOR UPDATE TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "UjianSesi" us
      JOIN "Ujian" u ON u.id = us."ujianId"
      WHERE us.id = "UjianJawaban"."sesiId"
        AND u."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "UjianSesi" us
      JOIN "Ujian" u ON u.id = us."ujianId"
      WHERE us.id = "UjianJawaban"."sesiId"
        AND u."guruId" = public.current_guru_id()
    )
  );

-- ---------------------------------------------------------------------------
-- Rapor, RaporMapel, RaporCatatan (no deletedAt)
-- ---------------------------------------------------------------------------

ALTER TABLE "Rapor" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rapor_staff_read" ON "Rapor"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "rapor_wali_read" ON "Rapor"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "rapor_admin_write" ON "Rapor"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "RaporMapel" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rapor_mapel_staff_read" ON "RaporMapel"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "rapor_mapel_wali_read" ON "RaporMapel"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Rapor" r
      WHERE r.id = "RaporMapel"."raporId"
        AND public.is_wali_of_santri(r."santriId")
    )
  );
CREATE POLICY "rapor_mapel_admin_write" ON "RaporMapel"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "RaporCatatan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rapor_catatan_staff_read" ON "RaporCatatan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "rapor_catatan_wali_read" ON "RaporCatatan"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Rapor" r
      WHERE r.id = "RaporCatatan"."raporId"
        AND public.is_wali_of_santri(r."santriId")
    )
  );
CREATE POLICY "rapor_catatan_admin_write" ON "RaporCatatan"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

-- ---------------------------------------------------------------------------
-- Perkembangan Santri: PerkembanganQuran, HafalanKitab, AkhlakPenilaian,
-- Pembinaan, CatatanWaliKelas (no deletedAt)
-- ---------------------------------------------------------------------------

ALTER TABLE "PerkembanganQuran" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "perkembangan_quran_staff_read" ON "PerkembanganQuran"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "perkembangan_quran_wali_read" ON "PerkembanganQuran"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "perkembangan_quran_guru_write" ON "PerkembanganQuran"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "HafalanKitab" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hafalan_kitab_staff_read" ON "HafalanKitab"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "hafalan_kitab_wali_read" ON "HafalanKitab"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "hafalan_kitab_guru_write" ON "HafalanKitab"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "AkhlakPenilaian" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "akhlak_staff_read" ON "AkhlakPenilaian"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "akhlak_wali_read" ON "AkhlakPenilaian"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "akhlak_guru_write" ON "AkhlakPenilaian"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "Pembinaan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pembinaan_staff_read" ON "Pembinaan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "pembinaan_wali_read" ON "Pembinaan"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "pembinaan_guru_write" ON "Pembinaan"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "CatatanWaliKelas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "catatan_wali_kelas_staff_read" ON "CatatanWaliKelas"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "catatan_wali_kelas_wali_read" ON "CatatanWaliKelas"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "catatan_wali_kelas_wali_kelas_write" ON "CatatanWaliKelas"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND EXISTS (
        SELECT 1 FROM "Santri" s
        WHERE s.id = "CatatanWaliKelas"."santriId"
          AND public.is_wali_kelas_of(s."kelasId")
      )
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND EXISTS (
        SELECT 1 FROM "Santri" s
        WHERE s.id = "CatatanWaliKelas"."santriId"
          AND public.is_wali_kelas_of(s."kelasId")
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Notifikasi (no deletedAt, waliId)
-- ---------------------------------------------------------------------------

ALTER TABLE "Notifikasi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notifikasi_wali_read" ON "Notifikasi"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND "waliId" = public.current_wali_id()
  );
CREATE POLICY "notifikasi_staff_read" ON "Notifikasi"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "notifikasi_admin_insert" ON "Notifikasi"
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin_level());

-- ---------------------------------------------------------------------------
-- ChatRoom, ChatMessage (no deletedAt)
-- ChatRoom has waliId, guruId, santriId directly.
-- ChatMessage uses chatRoomId (not roomId), senderWaliId/senderGuruId.
-- ---------------------------------------------------------------------------

ALTER TABLE "ChatRoom" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_room_staff_read" ON "ChatRoom"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "chat_room_wali_read" ON "ChatRoom"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND "waliId" = public.current_wali_id()
  );
CREATE POLICY "chat_room_guru_read" ON "ChatRoom"
  FOR SELECT TO authenticated
  USING (
    public.has_role('GURU')
    AND "guruId" = public.current_guru_id()
  );
CREATE POLICY "chat_room_admin_write" ON "ChatRoom"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "ChatMessage" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_message_staff_read" ON "ChatMessage"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "chat_message_wali_read" ON "ChatMessage"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = public.current_wali_id()
    )
  );
CREATE POLICY "chat_message_guru_read" ON "ChatMessage"
  FOR SELECT TO authenticated
  USING (
    public.has_role('GURU')
    AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = public.current_guru_id()
    )
  );
CREATE POLICY "chat_message_wali_insert" ON "ChatMessage"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = public.current_wali_id()
    )
  );
CREATE POLICY "chat_message_guru_insert" ON "ChatMessage"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role('GURU')
    AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = public.current_guru_id()
    )
  );

-- ---------------------------------------------------------------------------
-- Surat, QRScan, Alumni (no deletedAt)
-- ---------------------------------------------------------------------------

ALTER TABLE "Surat" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "surat_staff_read" ON "Surat"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "surat_wali_read" ON "Surat"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND "santriId" IS NOT NULL
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "surat_admin_write" ON "Surat"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "QRScan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qr_scan_staff_read" ON "QRScan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "qr_scan_admin_write" ON "QRScan"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "Alumni" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "alumni_staff_read" ON "Alumni"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "alumni_admin_write" ON "Alumni"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());
