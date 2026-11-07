-- ============================================================================
-- SIM MADIN — Postgres RPC Functions + Database Triggers (P0 Critical)
-- ============================================================================
-- File ini berisi:
--   1. RPC Functions untuk operasi kompleks yang harus atomic
--   2. Database Triggers untuk auto-update yang sebelumnya manual di client
--
-- Jalankan SETELAH file 00-03 di Supabase Dashboard SQL Editor.
-- Idempotent (CREATE OR REPLACE / IF NOT EXISTS).
-- ============================================================================

BEGIN;

-- ===========================================================================
-- PART 1: RPC FUNCTIONS (SECURITY DEFINER — berjalan sebagai server, bukan
--         caller. RLS bypass untuk operasi yang harus atomic.)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1.1 verify_payment(p_payment_id, p_kas_id)
-- ---------------------------------------------------------------------------
-- Atomic operation: verify payment + update Kas balance + update Tagihan.
-- Dipanggil oleh bendahara saat verify pembayaran PENDING → VERIFIED.
--
-- Sebelumnya di client (non-atomic, race condition):
--   1. UPDATE Payment SET status='VERIFIED' WHERE id=...
--   2. UPDATE Kas SET balance = balance + amount WHERE id=...  -- race!
--   3. UPDATE Tagihan SET paidAmount = paidAmount + amount, status=... WHERE id=...
--
-- Sekarang atomic di server:
--   SELECT verify_payment('payment-uuid', 'kas-uuid');
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.verify_payment(
  p_payment_id TEXT,
  p_kas_id TEXT DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  new_kas_balance DOUBLE PRECISION,
  new_tagihan_paid DOUBLE PRECISION,
  new_tagihan_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payment RECORD;
  v_kas_id TEXT;
  v_new_balance DOUBLE PRECISION DEFAULT 0;
  v_new_paid DOUBLE PRECISION DEFAULT 0;
  v_new_status TEXT DEFAULT NULL;
BEGIN
  -- 1. Fetch payment (lock row untuk prevent concurrent verify)
  SELECT id, amount, "tagihanId", status, "kasId"
    INTO v_payment
  FROM "Payment"
  WHERE id = p_payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Pembayaran tidak ditemukan'::TEXT,
      0.0, 0.0, NULL::TEXT;
    RETURN;
  END IF;

  -- 2. Cek status — hanya PENDING yang bisa di-verify
  IF v_payment.status != 'PENDING' THEN
    RETURN QUERY SELECT FALSE,
      'Pembayaran sudah ' || v_payment.status::TEXT,
      0.0, 0.0, NULL::TEXT;
    RETURN;
  END IF;

  -- 3. Tentukan kasId (parameter override atau dari payment)
  v_kas_id := COALESCE(p_kas_id, v_payment."kasId");

  -- 4. Update Payment status → VERIFIED
  UPDATE "Payment"
  SET status = 'VERIFIED',
      "kasId" = v_kas_id,
      "verifiedAt" = NOW(),
      "updatedAt" = NOW()
  WHERE id = p_payment_id;

  -- 5. Update Kas balance (atomic increment, no race condition)
  IF v_kas_id IS NOT NULL AND v_kas_id != '' THEN
    UPDATE "Kas"
    SET balance = balance + v_payment.amount,
        "updatedAt" = NOW()
    WHERE id = v_kas_id
    RETURNING balance INTO v_new_balance;
  END IF;

  -- 6. Update Tagihan paidAmount + status (kalau payment terkait tagihan)
  IF v_payment."tagihanId" IS NOT NULL AND v_payment."tagihanId" != '' THEN
    UPDATE "Tagihan"
    SET "paidAmount" = LEAST("paidAmount" + v_payment.amount, amount),
        status = CASE
          WHEN "paidAmount" + v_payment.amount >= amount THEN 'LUNAS'
          WHEN "paidAmount" + v_payment.amount > 0 THEN 'CICIL'
          ELSE 'BELUM_BAYAR'
        END,
        "updatedAt" = NOW()
    WHERE id = v_payment."tagihanId"
    RETURNING "paidAmount", status INTO v_new_paid, v_new_status;
  END IF;

  -- 7. Insert TransaksiKas otomatis (link ke payment)
  IF v_kas_id IS NOT NULL AND v_kas_id != '' THEN
    INSERT INTO "TransaksiKas" (
      id, "kasId", type, category, amount, description,
      "paymentId", "transaksiDate", "recordedById",
      "createdAt", "updatedAt"
    )
    VALUES (
      gen_random_uuid(), v_kas_id, 'PEMASUKAN', 'PEMBAYARAN_SANTRI',
      v_payment.amount,
      'Pembayaran ' || p_payment_id || ' (auto from verify_payment)',
      p_payment_id, NOW(), auth.uid()::text,
      NOW(), NOW()
    )
    ON CONFLICT DO NOTHING; -- idempotent
  END IF;

  RETURN QUERY SELECT TRUE, 'OK'::TEXT,
    COALESCE(v_new_balance, 0.0),
    COALESCE(v_new_paid, 0.0),
    COALESCE(v_new_status, ''::TEXT);
END;
$$;

-- Grant execute ke authenticated (bendahara/admin)
GRANT EXECUTE ON FUNCTION public.verify_payment(TEXT, TEXT) TO authenticated;

-- ---------------------------------------------------------------------------
-- 1.2 reject_payment(p_payment_id, p_reason)
-- ---------------------------------------------------------------------------
-- Reject payment: PENDING → REJECTED. Tidak update Kas/Tagihan.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reject_payment(
  p_payment_id TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_status TEXT;
BEGIN
  SELECT status INTO v_status FROM "Payment" WHERE id = p_payment_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Pembayaran tidak ditemukan'::TEXT;
    RETURN;
  END IF;

  IF v_status != 'PENDING' THEN
    RETURN QUERY SELECT FALSE, 'Pembayaran sudah ' || v_status::TEXT;
    RETURN;
  END IF;

  UPDATE "Payment"
  SET status = 'REJECTED',
      note = COALESCE(p_reason, note),
      "updatedAt" = NOW()
  WHERE id = p_payment_id;

  RETURN QUERY SELECT TRUE, 'OK'::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_payment(TEXT, TEXT) TO authenticated;

-- ---------------------------------------------------------------------------
-- 1.3 update_kas_balance(p_kas_id, p_delta)
-- ---------------------------------------------------------------------------
-- Atomic balance update: balance = balance + delta.
-- Dipakai oleh createTransaksiKas + verifyPayment.
-- Tidak dipanggil langsung oleh client — dipakai internal oleh RPC lain.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_kas_balance(
  p_kas_id TEXT,
  p_delta DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_balance DOUBLE PRECISION;
BEGIN
  UPDATE "Kas"
  SET balance = balance + p_delta,
      "updatedAt" = NOW()
  WHERE id = p_kas_id
  RETURNING balance INTO v_new_balance;

  RETURN COALESCE(v_new_balance, 0.0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_kas_balance(TEXT, DOUBLE PRECISION) TO authenticated;

-- ---------------------------------------------------------------------------
-- 1.4 create_transaksi_kas(p_kas_id, p_type, p_category, p_amount, p_desc, p_ref, p_recorded_by)
-- ---------------------------------------------------------------------------
-- Atomic: insert TransaksiKas + update Kas balance.
-- Mencegah race condition yang ada di client-side createTransaksiKas().
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_transaksi_kas(
  p_kas_id TEXT,
  p_type TEXT,         -- PEMASUKAN | PENGELUARAN
  p_category TEXT,     -- PEMBAYARAN_SANTRI | HONOR_GURU | OPERASIONAL | dll
  p_amount DOUBLE PRECISION,
  p_description TEXT,
  p_reference TEXT DEFAULT NULL,
  p_recorded_by TEXT DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  transaksi_id TEXT,
  new_kas_balance DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id TEXT;
  v_delta DOUBLE PRECISION;
  v_new_balance DOUBLE PRECISION;
BEGIN
  -- Hitung delta: pemasukan = +amount, pengeluaran = -amount
  v_delta := CASE WHEN p_type = 'PEMASUKAN' THEN p_amount ELSE -p_amount END;

  -- 1. Insert TransaksiKas
  v_id := gen_random_uuid()::text;
  INSERT INTO "TransaksiKas" (
    id, "kasId", type, category, amount, description,
    reference, "transaksiDate", "recordedById",
    "createdAt", "updatedAt"
  )
  VALUES (
    v_id, p_kas_id, p_type, p_category, p_amount, p_description,
    p_reference, NOW(), p_recorded_by,
    NOW(), NOW()
  );

  -- 2. Update Kas balance (atomic)
  v_new_balance := public.update_kas_balance(p_kas_id, v_delta);

  RETURN QUERY SELECT TRUE, v_id, v_new_balance;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_transaksi_kas(
  TEXT, TEXT, TEXT, DOUBLE PRECISION, TEXT, TEXT, TEXT
) TO authenticated;

-- ---------------------------------------------------------------------------
-- 1.5 update_honor_guru_status(p_honor_id, p_new_status, p_kas_id)
-- ---------------------------------------------------------------------------
-- Atomic: update HonorGuru status + create TransaksiKas + update Kas balance.
-- Dipakai saat bendahara approve (DRAFT→DISETUJUI) atau pay (DISETUJUI→DIBAYARKAN).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_honor_guru_status(
  p_honor_id TEXT,
  p_new_status TEXT,    -- DISETUJUI | DIBAYARKAN
  p_kas_id TEXT DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  new_kas_balance DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_honor RECORD;
  v_total DOUBLE PRECISION;
  v_new_balance DOUBLE PRECISION DEFAULT 0;
BEGIN
  -- 1. Fetch honor (lock row)
  SELECT id, status, "totalHonor", "honorMengajar", insentif, tunjangan, potongan,
    "guruId", "periodeLabel"
    INTO v_honor
  FROM "HonorGuru"
  WHERE id = p_honor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Honor tidak ditemukan'::TEXT, 0.0;
    RETURN;
  END IF;

  -- 2. Validasi transisi status
  IF p_new_status = 'DISETUJUI' AND v_honor.status != 'DRAFT' THEN
    RETURN QUERY SELECT FALSE, 'Honor harus berstatus DRAFT'::TEXT, 0.0;
    RETURN;
  END IF;

  IF p_new_status = 'DIBAYARKAN' AND v_honor.status != 'DISETUJUI' THEN
    RETURN QUERY SELECT FALSE, 'Honor harus berstatus DISETUJUI'::TEXT, 0.0;
    RETURN;
  END IF;

  -- 3. Hitung total honor
  v_total := COALESCE(v_honor."totalHonor", 0);
  IF v_total <= 0 THEN
    -- Compute from components
    v_total := COALESCE(v_honor."honorMengajar", 0)
      + COALESCE(v_honor.insentif, 0)
      + COALESCE(v_honor.tunjangan, 0)
      - COALESCE(v_honor.potongan, 0);
  END IF;

  -- 4. Update HonorGuru status
  UPDATE "HonorGuru"
  SET status = p_new_status,
      "updatedAt" = NOW()
  WHERE id = p_honor_id;

  -- 5. Kalau DIBAYARKAN: create TransaksiKas (pengeluaran) + update Kas balance
  IF p_new_status = 'DIBAYARKAN' AND p_kas_id IS NOT NULL AND p_kas_id != '' THEN
    v_new_balance := public.update_kas_balance(p_kas_id, -v_total);

    -- Insert TransaksiKas
    INSERT INTO "TransaksiKas" (
      id, "kasId", type, category, amount, description,
      "honorGuruId", "transaksiDate", "recordedById",
      "createdAt", "updatedAt"
    )
    VALUES (
      gen_random_uuid()::text, p_kas_id, 'PENGELUARAN', 'HONOR_GURU',
      v_total,
      'Pembayaran honor ' || v_honor."periodeLabel" || ' (auto)',
      p_honor_id, NOW(), auth.uid()::text,
      NOW(), NOW()
    )
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN QUERY SELECT TRUE, 'OK'::TEXT, COALESCE(v_new_balance, 0.0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_honor_guru_status(TEXT, TEXT, TEXT) TO authenticated;

-- ---------------------------------------------------------------------------
-- 1.6 submit_ujian(p_sesi_id, p_answers JSONB)
-- ---------------------------------------------------------------------------
-- Atomic ujian submission: insert/update jawaban + auto-correct PG +
-- compute score + update sesi status + upsert UjianNilai.
--
-- p_answers format: [{"ujianSoalId": "...", "answer": "A"}, ...]
-- ---------------------------------------------------------------------------
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
  v_sesi RECORD;
  v_answer RECORD;
  v_soal RECORD;
  v_total_score DOUBLE PRECISION := 0;
  v_total_bobot DOUBLE PRECISION := 0;
  v_final_score DOUBLE PRECISION;
  v_answer_item JSONB;
BEGIN
  -- 1. Fetch sesi (lock row)
  SELECT id, "ujianId", "santriId", status, "startTime"
    INTO v_sesi
  FROM "UjianSesi"
  WHERE id = p_sesi_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Sesi ujian tidak ditemukan'::TEXT, 0.0;
    RETURN;
  END IF;

  IF v_sesi.status = 'FINISHED' THEN
    RETURN QUERY SELECT FALSE, 'Ujian sudah selesai'::TEXT, 0.0;
    RETURN;
  END IF;

  -- 2. Loop through answers — insert/update jawaban + auto-correct PG
  FOR v_answer_item IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    -- Fetch soal + BankSoal untuk correct answer + bobot + type
    SELECT us.id, us.bobot, bs.type, bs."correctAnswer"
      INTO v_soal
    FROM "UjianSoal" us
    JOIN "BankSoal" bs ON bs.id = us."bankSoalId"
    WHERE us.id = v_answer_item->>'ujianSoalId';

    IF FOUND AND v_soal.type = 'PG' THEN
      -- Auto-correct: compare answer dengan correctAnswer
      v_total_bobot := v_total_bobot + COALESCE(v_soal.bobot, 1.0);

      IF UPPER(v_answer_item->>'answer') = UPPER(v_soal."correctAnswer") THEN
        v_total_score := v_total_score + COALESCE(v_soal.bobot, 1.0);
      END IF;

      -- Upsert jawaban
      INSERT INTO "UjianJawaban" (
        id, "sesiId", "ujianSoalId", "santriId", answer,
        "isCorrect", score, "isAutoCorrected",
        "createdAt", "updatedAt"
      )
      VALUES (
        gen_random_uuid()::text, p_sesi_id,
        v_answer_item->>'ujianSoalId', v_sesi."santriId",
        v_answer_item->>'answer',
        UPPER(v_answer_item->>'answer') = UPPER(v_soal."correctAnswer"),
        CASE WHEN UPPER(v_answer_item->>'answer') = UPPER(v_soal."correctAnswer")
          THEN v_soal.bobot ELSE 0 END,
        true,
        NOW(), NOW()
      )
      ON CONFLICT ("sesiId", "ujianSoalId") DO UPDATE SET
        answer = EXCLUDED.answer,
        "isCorrect" = EXCLUDED."isCorrect",
        score = EXCLUDED.score,
        "isAutoCorrected" = true,
        "updatedAt" = NOW();
    ELSE
      -- Non-PG (essay/isian): insert tanpa auto-correct
      INSERT INTO "UjianJawaban" (
        id, "sesiId", "ujianSoalId", "santriId", answer,
        "isAutoCorrected",
        "createdAt", "updatedAt"
      )
      VALUES (
        gen_random_uuid()::text, p_sesi_id,
        v_answer_item->>'ujianSoalId', v_sesi."santriId",
        v_answer_item->>'answer',
        false,
        NOW(), NOW()
      )
      ON CONFLICT ("sesiId", "ujianSoalId") DO UPDATE SET
        answer = EXCLUDED.answer,
        "updatedAt" = NOW();
    END IF;
  END LOOP;

  -- 3. Compute final score (0-100 scale)
  v_final_score := CASE WHEN v_total_bobot > 0
    THEN (v_total_score / v_total_bobot) * 100
    ELSE 0 END;

  -- 4. Update sesi: status FINISHED + score + endTime + durationUsed
  UPDATE "UjianSesi"
  SET status = 'FINISHED',
      "endTime" = NOW(),
      score = v_final_score,
      "durationUsed" = EXTRACT(EPOCH FROM (NOW() - "startTime"))::INT,
      "updatedAt" = NOW()
  WHERE id = p_sesi_id;

  -- 5. Upsert UjianNilai
  INSERT INTO "UjianNilai" (
    id, "ujianId", "santriId", score, "isAutoCorrect", "gradedAt",
    "createdAt", "updatedAt"
  )
  VALUES (
    gen_random_uuid()::text, v_sesi."ujianId", v_sesi."santriId",
    v_final_score, true, NOW(),
    NOW(), NOW()
  )
  ON CONFLICT ("ujianId", "santriId") DO UPDATE SET
    score = EXCLUDED.score,
    "isAutoCorrect" = true,
    "gradedAt" = NOW(),
    "updatedAt" = NOW();

  RETURN QUERY SELECT TRUE, 'OK'::TEXT, v_final_score;
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_ujian(TEXT, JSONB) TO authenticated;

-- ===========================================================================
-- PART 2: DATABASE TRIGGERS (auto-update yang sebelumnya manual di client)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 2.1 Trigger: after ChatMessage INSERT → update ChatRoom.lastMessage + lastMessageAt
-- ---------------------------------------------------------------------------
-- Sebelumnya di client (mutation_providers_wali/guru.dart):
--   await client.from('ChatMessage').insert(body);
--   await client.from('ChatRoom').update({
--     'lastMessage': message, 'lastMessageAt': DateTime.now().toIso8601String(),
--   }).eq('id', roomId);
--
-- Sekarang otomatis via trigger — tidak bisa lupa update ChatRoom.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_update_chat_room_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Hanya untuk INSERT
  IF TG_OP = 'INSERT' THEN
    UPDATE "ChatRoom"
    SET "lastMessage" = NEW.message,
        "lastMessageAt" = NOW(),
        "updatedAt" = NOW()
    WHERE id = NEW."chatRoomId";
  END IF;
  RETURN NEW;
END;
$$;

-- Drop trigger jika sudah ada, lalu create ulang
DROP TRIGGER IF EXISTS trg_chat_message_update_room ON "ChatMessage";
CREATE TRIGGER trg_chat_message_update_room
  AFTER INSERT ON "ChatMessage"
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_update_chat_room_last_message();

-- ---------------------------------------------------------------------------
-- 2.2 Trigger: after Payment UPDATE (status → VERIFIED) → auto update Tagihan
-- ---------------------------------------------------------------------------
-- Backup trigger: kalau ada verify yang dilakukan tanpa pakai RPC function
-- (mis. via admin dashboard atau manual SQL), Tagihan tetap ter-update.
--
-- Catatan: RPC verify_payment() sudah handle ini, tapi trigger ini sebagai
-- safety net untuk konsistensi data.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_payment_verified_update_tagihan()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_paid DOUBLE PRECISION;
BEGIN
  -- Hanya trigger kalau status berubah dari PENDING → VERIFIED
  IF TG_OP = 'UPDATE' AND OLD.status = 'PENDING' AND NEW.status = 'VERIFIED' THEN
    -- Cek apakah ini berasal dari RPC (sudah handle Tagihan) atau manual
    -- Heuristic: kalau verifiedAt baru saja di-set, kemungkinan dari RPC
    -- Tapi untuk safety, tetap update Tagihan (idempotent via LEAST)

    IF NEW."tagihanId" IS NOT NULL AND NEW."tagihanId" != '' THEN
      -- Get current paidAmount
      SELECT "paidAmount" INTO v_old_paid FROM "Tagihan" WHERE id = NEW."tagihanId";

      -- Update hanya kalau paidAmount belum include amount ini
      -- (cegah double-count kalau RPC sudah update + trigger fire lagi)
      -- Solusi: pakai tagihan_version counter atau cek delta
      -- Untuk simplicity: trigger ini hanya update status, bukan paidAmount
      -- (paidAmount di-handle oleh RPC verify_payment)
      -- Trigger hanya sync status tagihan:
      UPDATE "Tagihan"
      SET status = CASE
          WHEN "paidAmount" >= amount THEN 'LUNAS'
          WHEN "paidAmount" > 0 THEN 'CICIL'
          ELSE 'BELUM_BAYAR'
        END,
        "updatedAt" = NOW()
      WHERE id = NEW."tagihanId";
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payment_verified_update_tagihan ON "Payment";
CREATE TRIGGER trg_payment_verified_update_tagihan
  AFTER UPDATE ON "Payment"
  FOR EACH ROW
  WHEN (OLD.status = 'PENDING' AND NEW.status = 'VERIFIED')
  EXECUTE FUNCTION public.fn_payment_verified_update_tagihan();

-- ---------------------------------------------------------------------------
-- 2.3 Trigger: after Payment INSERT (status=VERIFIED langsung) → auto update
--           Kas balance + Tagihan (untuk pembayaran yang langsung verified)
-- ---------------------------------------------------------------------------
-- Kasus: bendahara input pembayaran tunai yang langsung verified (tidak perlu
-- pending verification). Trigger ini auto-update Kas + Tagihan.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_payment_insert_auto_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Hanya untuk INSERT dengan status VERIFIED (langsung verified)
  IF TG_OP = 'INSERT' AND NEW.status = 'VERIFIED' THEN
    -- Update Kas balance
    IF NEW."kasId" IS NOT NULL AND NEW."kasId" != '' THEN
      UPDATE "Kas"
      SET balance = balance + NEW.amount,
          "updatedAt" = NOW()
      WHERE id = NEW."kasId";
    END IF;

    -- Update Tagihan paidAmount + status
    IF NEW."tagihanId" IS NOT NULL AND NEW."tagihanId" != '' THEN
      UPDATE "Tagihan"
      SET "paidAmount" = LEAST("paidAmount" + NEW.amount, amount),
          status = CASE
            WHEN "paidAmount" + NEW.amount >= amount THEN 'LUNAS'
            WHEN "paidAmount" + NEW.amount > 0 THEN 'CICIL'
            ELSE 'BELUM_BAYAR'
          END,
          "updatedAt" = NOW()
      WHERE id = NEW."tagihanId";
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payment_insert_auto_update ON "Payment";
CREATE TRIGGER trg_payment_insert_auto_update
  AFTER INSERT ON "Payment"
  FOR EACH ROW
  WHEN (NEW.status = 'VERIFIED')
  EXECUTE FUNCTION public.fn_payment_insert_auto_update();

-- ---------------------------------------------------------------------------
-- 2.4 Trigger: after Santri INSERT → auto-create default SantriWali link
-- ---------------------------------------------------------------------------
-- Kalau santri dibuat dengan waliId, otomatis buat SantriWali record.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_santri_insert_auto_wali_link()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW."waliId" IS NOT NULL AND NEW."waliId" != '' THEN
    -- Catatan: "SantriWali" tidak punya kolom updatedAt (lihat baseline).
    -- Mengirimnya membuat trigger ini gagal sehingga penautan wali–santri
    -- otomatis tidak pernah berjalan.
    INSERT INTO "SantriWali" (
      id, "santriId", "waliId", "canAccess", "createdAt"
    )
    VALUES (
      gen_random_uuid()::text, NEW.id, NEW."waliId", true,
      NOW()
    )
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_santri_insert_auto_wali_link ON "Santri";
CREATE TRIGGER trg_santri_insert_auto_wali_link
  AFTER INSERT ON "Santri"
  FOR EACH ROW
  WHEN (NEW."waliId" IS NOT NULL)
  EXECUTE FUNCTION public.fn_santri_insert_auto_wali_link();

-- ---------------------------------------------------------------------------
-- 2.5 Trigger: auto-generate invoice number untuk Payment
-- ---------------------------------------------------------------------------
-- Format: INV-{YEAR}-{SEQUENCE:6digit} → contoh: INV-2026-000001
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_payment_auto_invoice_no()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year INT;
  v_count INT;
  v_invoice TEXT;
BEGIN
  IF TG_OP = 'INSERT' AND (NEW."invoiceNo" IS NULL OR NEW."invoiceNo" = '') THEN
    v_year := EXTRACT(YEAR FROM NOW());
    SELECT COUNT(*) + 1 INTO v_count FROM "Payment"
    WHERE "invoiceNo" LIKE 'INV-' || v_year || '-%';

    v_invoice := 'INV-' || v_year || '-' || LPAD(v_count::TEXT, 6, '0');
    NEW."invoiceNo" := v_invoice;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payment_auto_invoice_no ON "Payment";
CREATE TRIGGER trg_payment_auto_invoice_no
  BEFORE INSERT ON "Payment"
  FOR EACH ROW
  WHEN (NEW."invoiceNo" IS NULL OR NEW."invoiceNo" = '')
  EXECUTE FUNCTION public.fn_payment_auto_invoice_no();

-- ---------------------------------------------------------------------------
-- 2.6 Trigger: auto-update updatedAt untuk semua tabel
-- ---------------------------------------------------------------------------
-- Untuk tabel yang belum punya trigger updatedAt otomatis.
-- Prisma sebelumnya auto-handle ini, tapi Supabase client tidak.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_auto_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW."updatedAt" = NOW();
  RETURN NEW;
END;
$$;

-- Apply ke tabel-tabel kritis yang sering di-update
DROP TRIGGER IF EXISTS trg_santri_updated_at ON "Santri";
CREATE TRIGGER trg_santri_updated_at BEFORE UPDATE ON "Santri"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_payment_updated_at ON "Payment";
CREATE TRIGGER trg_payment_updated_at BEFORE UPDATE ON "Payment"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_tagihan_updated_at ON "Tagihan";
CREATE TRIGGER trg_tagihan_updated_at BEFORE UPDATE ON "Tagihan"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_kas_updated_at ON "Kas";
CREATE TRIGGER trg_kas_updated_at BEFORE UPDATE ON "Kas"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_honor_guru_updated_at ON "HonorGuru";
CREATE TRIGGER trg_honor_guru_updated_at BEFORE UPDATE ON "HonorGuru"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_chat_room_updated_at ON "ChatRoom";
CREATE TRIGGER trg_chat_room_updated_at BEFORE UPDATE ON "ChatRoom"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_wali_updated_at ON "Wali";
CREATE TRIGGER trg_wali_updated_at BEFORE UPDATE ON "Wali"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_user_updated_at ON "User";
CREATE TRIGGER trg_user_updated_at BEFORE UPDATE ON "User"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_guru_updated_at ON "Guru";
CREATE TRIGGER trg_guru_updated_at BEFORE UPDATE ON "Guru"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

COMMIT;

-- ============================================================================
-- Summary:
--   RPC Functions (5):
--     1. verify_payment(paymentId, kasId) → atomic verify + Kas + Tagihan + TransaksiKas
--     2. reject_payment(paymentId, reason) → safe reject
--     3. update_kas_balance(kasId, delta) → atomic balance update
--     4. create_transaksi_kas(...) → atomic insert + balance update
--     5. update_honor_guru_status(honorId, newStatus, kasId) → atomic honor + TransaksiKas + Kas
--     6. submit_ujian(sesiId, answers) → atomic jawaban + auto-correct + score + nilai
--
--   Triggers (6):
--     1. trg_chat_message_update_room → auto update ChatRoom.lastMessage + lastMessageAt
--     2. trg_payment_verified_update_tagihan → sync Tagihan status saat Payment verified
--     3. trg_payment_insert_auto_update → auto Kas + Tagihan untuk direct-verified Payment
--     4. trg_santri_insert_auto_wali_link → auto-create SantriWali saat Santri insert
--     5. trg_payment_auto_invoice_no → auto-generate INV-{YEAR}-{SEQ:6}
--     6. trg_*_updated_at → auto-update updatedAt untuk 10 tabel kritis
-- ============================================================================
