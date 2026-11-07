-- ============================================================================
-- SIM MADIN — DEFAULT untuk id, createdAt, updatedAt (hardening)
-- ============================================================================
-- Baseline schema dibuat meniru Prisma: `id` (cuid), `createdAt`, dan
-- `updatedAt` diisi oleh APLIKASI, jadi kolomnya NOT NULL tanpa DEFAULT.
--
-- Konsekuensi yang sudah ditemukan:
--   1. Aplikasi Flutter gagal INSERT kalau lupa mengirim kolom tsb
--      (diperbaiki di sisi Dart lewat rowFor()/patchFor()).
--   2. Seed data (migration 12) dan trigger sendiri juga tidak selalu
--      mengirim `id`/`createdAt`, sehingga insert-nya gagal di database baru.
--   3. Integrasi lain (n8n, script admin, impor CSV, RPC manual) akan
--      mengalami error yang sama.
--
-- Fix berlapis:
--   * `id`        -> DEFAULT hasil gen_random_uuid() tanpa tanda hubung
--                    (kolom bertipe text, UUID valid & tidak bentrok cuid)
--   * `createdAt` -> DEFAULT now() bila masih NOT NULL tanpa default
--   * `updatedAt` -> DEFAULT now() + trigger BEFORE UPDATE umur-panjang
--                    (fn_auto_updated_at sudah dipakai untuk 10 tabel;
--                    migration ini memasangnya untuk SEMUA tabel yang
--                    punya kolom updatedAt, sehingga tidak ada lagi baris
--                    yang "lupa" update timestamp).
--
-- Semua langkah idempotent dan tidak mengubah data yang sudah ada.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- ----------------------------------------------------------------------------
-- 1. Helper updatedAt (definisi longgar agar bisa dipakai semua tabel)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_auto_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW."updatedAt" := now();
  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Pasang DEFAULT pada kolom id / createdAt / updatedAt
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
  v_count INT := 0;
BEGIN
  FOR r IN
    SELECT c.table_name, c.column_name, c.data_type, c.is_nullable,
           c.column_default, t.column_name AS updated_col
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema
     AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    LEFT JOIN information_schema.columns u
      ON u.table_schema = c.table_schema
     AND u.table_name = c.table_name
     AND u.column_name = 'updatedAt'
    WHERE c.table_schema = 'public'
      AND c.column_name IN ('id', 'createdAt')
  LOOP
    -- id: hanya untuk kolom text/uuid tanpa default
    IF r.column_name = 'id'
       AND r.data_type IN ('text', 'character varying', 'uuid')
       AND r.column_default IS NULL THEN
      BEGIN
        IF r.data_type = 'uuid' THEN
          EXECUTE format(
            'ALTER TABLE public.%I ALTER COLUMN id SET DEFAULT gen_random_uuid()',
            r.table_name
          );
        ELSE
          EXECUTE format(
            'ALTER TABLE public.%I ALTER COLUMN id SET DEFAULT '
            'replace(gen_random_uuid()::text, ''-'', '''')',
            r.table_name
          );
        END IF;
        v_count := v_count + 1;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Gagal set default id untuk %: %', r.table_name, SQLERRM;
      END;
    END IF;

    -- createdAt: hanya bila NOT NULL dan belum punya default
    IF r.column_name = 'createdAt'
       AND r.is_nullable = 'NO'
       AND r.column_default IS NULL THEN
      BEGIN
        EXECUTE format(
          'ALTER TABLE public.%I ALTER COLUMN "createdAt" SET DEFAULT now()',
          r.table_name
        );
        v_count := v_count + 1;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Gagal set default createdAt untuk %: %', r.table_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- updatedAt: NOT NULL tanpa default -> now()
  FOR r IN
    SELECT c.table_name, c.is_nullable, c.column_default
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    WHERE c.table_schema = 'public'
      AND c.column_name = 'updatedAt'
  LOOP
    IF r.is_nullable = 'NO' AND r.column_default IS NULL THEN
      BEGIN
        EXECUTE format(
          'ALTER TABLE public.%I ALTER COLUMN "updatedAt" SET DEFAULT now()',
          r.table_name
        );
        v_count := v_count + 1;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Gagal set default updatedAt untuk %: %', r.table_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- Backfill baris lama yang NULL (jaga-jaga).
  FOR r IN
    SELECT c.table_name
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    WHERE c.table_schema = 'public'
      AND c.column_name = 'updatedAt'
      AND c.is_nullable = 'YES'
  LOOP
    BEGIN
      EXECUTE format(
        'UPDATE public.%I SET "updatedAt" = now() WHERE "updatedAt" IS NULL',
        r.table_name
      );
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END LOOP;

  RAISE NOTICE 'Selesai: % default kolom ditambahkan.', v_count;
END $$;

-- ----------------------------------------------------------------------------
-- 3. Trigger updatedAt untuk semua tabel yang memilikinya
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
  v_count INT := 0;
BEGIN
  FOR r IN
    SELECT c.table_name
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    WHERE c.table_schema = 'public'
      AND c.column_name = 'updatedAt'
    ORDER BY c.table_name
  LOOP
    BEGIN
      EXECUTE format(
        'DROP TRIGGER IF EXISTS %I ON public.%I',
        'trg_' || r.table_name || '_updated_at', r.table_name
      );
      EXECUTE format(
        'CREATE TRIGGER %I BEFORE UPDATE ON public.%I '
        'FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at()',
        'trg_' || r.table_name || '_updated_at', r.table_name
      );
      v_count := v_count + 1;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Gagal pasang trigger updatedAt untuk %: %', r.table_name, SQLERRM;
    END;
  END LOOP;
  RAISE NOTICE 'Selesai: % trigger updatedAt dipasang.', v_count;
END $$;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification:
--   SELECT table_name, column_name, column_default, is_nullable
--   FROM information_schema.columns
--   WHERE table_schema = 'public' AND column_name IN ('id','createdAt','updatedAt')
--     AND column_default IS NULL AND is_nullable = 'NO';
--   -- Expected: 0 rows (semua punya default)
-- ============================================================================
