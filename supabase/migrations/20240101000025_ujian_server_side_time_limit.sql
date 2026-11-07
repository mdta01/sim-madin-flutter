-- ============================================================================
-- SIM MADIN — Batas waktu ujian ditegakkan di SERVER
-- ============================================================================
-- MASALAH
-- ----------------------------------------------------------------------------
-- 1. `submit_ujian()` sama sekali tidak memeriksa batas waktu. Timer ujian
--    hanya berjalan di aplikasi (Timer.periodic di ujian_take_screen.dart),
--    jadi santri bisa mengubah jam perangkat atau menutup lalu membuka
--    aplikasi berkali-kali, dan tetap bisa submit kapan pun. Ujian 60 menit
--    bisa dikerjakan berjam-jam sambil mencari jawaban.
--
-- 2. `durationUsed` bisa negatif / tidak masuk akal bila `startTime` berada di
--    masa depan (jam perangkat berbeda dengan jam server).
--
-- SOLUSI
-- ----------------------------------------------------------------------------
-- Semua perhitungan waktu memakai NOW() di server, bukan jam perangkat:
--   * elapsed = NOW() - startTime
--   * toleransi 90 detik untuk latensi jaringan / auto-submit
--   * bila melewati batas + toleransi, jawaban yang masuk TETAP dinilai
--     (tidak dibuang), tetapi ditandai "terlambat" di UjianNilai.notes supaya
--     guru bisa meninjau — ini keadilan yang lebih baik daripada membuang
--     pekerjaan santri karena masalah jaringan.
--   * durationUsed di-clamp ke rentang wajar
--   * fungsi `ujian_remaining_seconds()` menyediakan sisa waktu otoritatif
--     supaya aplikasi tidak bergantung pada jam perangkat
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Sisa waktu otoritatif untuk sebuah sesi
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ujian_remaining_seconds(p_sesi_id TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sesi     RECORD;
  v_duration INTEGER;
  v_elapsed  INTEGER;
BEGIN
  SELECT s.id, s."startTime", s.status, u."durationMnt"
    INTO v_sesi
  FROM "UjianSesi" s
  JOIN "Ujian" u ON u.id = s."ujianId"
  WHERE s.id = p_sesi_id;

  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  IF v_sesi.status = 'FINISHED' THEN
    RETURN 0;
  END IF;

  v_duration := COALESCE(v_sesi."durationMnt", 90) * 60;
  v_elapsed  := GREATEST(
    0,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(v_sesi."startTime", NOW())))::INT
  );

  RETURN GREATEST(0, v_duration - v_elapsed);
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. submit_ujian dengan penegakan batas waktu
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_ujian(
  p_sesi_id TEXT,
  p_answers JSONB
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  final_score DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sesi        RECORD;
  v_soal        RECORD;
  v_existing    RECORD;
  v_total_score DOUBLE PRECISION := 0;
  v_total_bobot DOUBLE PRECISION := 0;
  v_final_score DOUBLE PRECISION;
  v_answer_item JSONB;
  v_elapsed     INTEGER;
  v_duration    INTEGER;
  v_tolerance   INTEGER := 90;  -- detik
  v_late        BOOLEAN := FALSE;
  v_answer      TEXT;
  v_is_correct  BOOLEAN;
BEGIN
  -- 1. Ambil & lock sesi
  SELECT s.id, s."ujianId", s."santriId", s.status, s."startTime",
         s.score, u."durationMnt"
    INTO v_sesi
  FROM "UjianSesi" s
  JOIN "Ujian" u ON u.id = s."ujianId"
  WHERE s.id = p_sesi_id
  FOR UPDATE OF s;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Sesi ujian tidak ditemukan'::TEXT,
      0.0::DOUBLE PRECISION;
    RETURN;
  END IF;

  IF v_sesi.status = 'FINISHED' THEN
    RETURN QUERY SELECT FALSE, 'Ujian sudah selesai'::TEXT,
      COALESCE(v_sesi.score, 0.0::DOUBLE PRECISION);
    RETURN;
  END IF;

  -- 2. Hitung waktu di server
  v_duration := COALESCE(v_sesi."durationMnt", 90) * 60;
  v_elapsed  := GREATEST(
    0,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(v_sesi."startTime", NOW())))::INT
  );
  v_late := v_elapsed > (v_duration + v_tolerance);

  -- 3. Simpan & nilai jawaban
  IF p_answers IS NOT NULL THEN
    FOR v_answer_item IN SELECT * FROM jsonb_array_elements(p_answers)
    LOOP
      SELECT us.id, us.bobot, bs.type, bs."correctAnswer"
        INTO v_soal
      FROM "UjianSoal" us
      JOIN "BankSoal" bs ON bs.id = us."bankSoalId"
      WHERE us.id = v_answer_item->>'ujianSoalId';

      IF NOT FOUND THEN
        CONTINUE;
      END IF;

      v_answer := v_answer_item->>'answer';

      IF v_soal.type = 'PG' THEN
        v_total_bobot := v_total_bobot + COALESCE(v_soal.bobot, 1.0);
        v_is_correct := UPPER(COALESCE(v_answer, ''))
                        = UPPER(COALESCE(v_soal."correctAnswer", '~'));

        IF v_is_correct THEN
          v_total_score := v_total_score + COALESCE(v_soal.bobot, 1.0);
        END IF;

        INSERT INTO "UjianJawaban" (
          id, "sesiId", "ujianSoalId", "santriId", answer,
          "isCorrect", score, "isAutoCorrected", "createdAt", "updatedAt"
        ) VALUES (
          gen_random_uuid()::text, p_sesi_id,
          v_answer_item->>'ujianSoalId', v_sesi."santriId",
          v_answer, v_is_correct,
          CASE WHEN v_is_correct THEN COALESCE(v_soal.bobot, 1.0) ELSE 0 END,
          true, NOW(), NOW()
        )
        ON CONFLICT ("sesiId", "ujianSoalId") DO UPDATE SET
          answer = EXCLUDED.answer,
          "isCorrect" = EXCLUDED."isCorrect",
          score = EXCLUDED.score,
          "isAutoCorrected" = true,
          "updatedAt" = NOW();
      ELSE
        INSERT INTO "UjianJawaban" (
          id, "sesiId", "ujianSoalId", "santriId", answer,
          "isAutoCorrected", "createdAt", "updatedAt"
        ) VALUES (
          gen_random_uuid()::text, p_sesi_id,
          v_answer_item->>'ujianSoalId', v_sesi."santriId",
          v_answer, false, NOW(), NOW()
        )
        ON CONFLICT ("sesiId", "ujianSoalId") DO UPDATE SET
          answer = EXCLUDED.answer,
          "updatedAt" = NOW();
      END IF;
    END LOOP;
  END IF;

  -- 4. Skor akhir (skala 0-100)
  v_final_score := CASE WHEN v_total_bobot > 0
    THEN (v_total_score / v_total_bobot) * 100
    ELSE 0 END;

  -- 5. Tutup sesi; durasi di-clamp ke rentang wajar
  UPDATE "UjianSesi"
  SET status = 'FINISHED',
      "endTime" = NOW(),
      score = v_final_score,
      "durationUsed" = LEAST(GREATEST(v_elapsed, 0), v_duration + v_tolerance),
      "isAutoCorrected" = true,
      "updatedAt" = NOW()
  WHERE id = p_sesi_id;

  -- 6. UjianNilai (upsert berdasarkan unique (ujianId, santriId))
  SELECT id INTO v_existing
  FROM "UjianNilai"
  WHERE "ujianId" = v_sesi."ujianId" AND "santriId" = v_sesi."santriId";

  IF FOUND THEN
    UPDATE "UjianNilai"
    SET score = v_final_score,
        "isAutoCorrect" = true,
        "gradedAt" = NOW(),
        notes = CASE WHEN v_late THEN
          'Dikumpulkan melewati batas waktu (' || v_elapsed || ' dari '
          || v_duration || ' detik) — perlu ditinjau guru.'
          ELSE notes END,
        "updatedAt" = NOW()
    WHERE id = v_existing.id;
  ELSE
    INSERT INTO "UjianNilai" (
      id, "ujianId", "santriId", score, "isAutoCorrect", "gradedAt",
      notes, "createdAt", "updatedAt"
    ) VALUES (
      gen_random_uuid()::text, v_sesi."ujianId", v_sesi."santriId",
      v_final_score, true, NOW(),
      CASE WHEN v_late THEN
        'Dikumpulkan melewati batas waktu (' || v_elapsed || ' dari '
        || v_duration || ' detik) — perlu ditinjau guru.' ELSE NULL END,
      NOW(), NOW()
    );
  END IF;

  IF v_late THEN
    RETURN QUERY SELECT TRUE,
      ('Dikumpulkan terlambat (' || v_elapsed || ' detik) — ditandai untuk '
       || 'ditinjau guru.')::TEXT, v_final_score;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'OK'::TEXT, v_final_score;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ujian_remaining_seconds(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_ujian(TEXT, JSONB) TO authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification:
--   SELECT public.ujian_remaining_seconds('<sesi-id>');  -- sisa detik
--   SELECT * FROM public.submit_ujian('<sesi-id>', '[]'::jsonb);
-- ============================================================================
