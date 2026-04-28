-- ============================================================
-- Error Tracking Log Table
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- Create or upgrade error_logs table
CREATE TABLE IF NOT EXISTS public.error_logs (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  level       TEXT NOT NULL DEFAULT 'error',          -- 'info', 'warn', 'error', 'fatal'
  source      TEXT NOT NULL DEFAULT 'unknown',         -- e.g. 'analyze-receipt', 'frontend', 'auth'
  message     TEXT NOT NULL,
  details     JSONB DEFAULT '{}'::jsonb,               -- extra context: model, status, stack, etc.
  user_agent  TEXT,                                     -- browser/device info (optional)
  resolved    BOOLEAN DEFAULT false                    -- mark resolved after debugging
);

ALTER TABLE public.error_logs ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now() NOT NULL;
ALTER TABLE public.error_logs ADD COLUMN IF NOT EXISTS level TEXT NOT NULL DEFAULT 'error';
ALTER TABLE public.error_logs ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'unknown';
ALTER TABLE public.error_logs ADD COLUMN IF NOT EXISTS message TEXT NOT NULL DEFAULT 'Unknown error';
ALTER TABLE public.error_logs ADD COLUMN IF NOT EXISTS details JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.error_logs ADD COLUMN IF NOT EXISTS user_agent TEXT;
ALTER TABLE public.error_logs ADD COLUMN IF NOT EXISTS resolved BOOLEAN DEFAULT false;

-- Index for fast querying
CREATE INDEX IF NOT EXISTS idx_error_logs_created_at ON public.error_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_error_logs_level ON public.error_logs (level);
CREATE INDEX IF NOT EXISTS idx_error_logs_source ON public.error_logs (source);

-- Enable RLS
ALTER TABLE public.error_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can insert error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Service role can read error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Service role can update error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Service role can delete error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Anon can insert error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Anon can read error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Anon can update error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Anon can delete error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Client can insert error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Admins can read error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Admins can update error logs" ON public.error_logs;
DROP POLICY IF EXISTS "Admins can delete error logs" ON public.error_logs;

-- Edge Functions with service role can manage logs.
CREATE POLICY "Service role can insert error logs"
  ON public.error_logs FOR INSERT
  TO service_role
  WITH CHECK (true);
CREATE POLICY "Service role can read error logs"
  ON public.error_logs FOR SELECT
  TO service_role
  USING (true);
CREATE POLICY "Service role can update error logs"
  ON public.error_logs FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);
CREATE POLICY "Service role can delete error logs"
  ON public.error_logs FOR DELETE
  TO service_role
  USING (true);

-- Browser clients can submit diagnostics, including before login.
CREATE POLICY "Client can insert error logs"
  ON public.error_logs FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Only system admins can browse, resolve, or clear logs from the app.
CREATE POLICY "Admins can read error logs"
  ON public.error_logs FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can update error logs"
  ON public.error_logs FOR UPDATE
  TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can delete error logs"
  ON public.error_logs FOR DELETE
  TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- Auto-cleanup: delete logs older than 90 days (optional, run manually or via cron)
-- DELETE FROM error_logs WHERE created_at < now() - INTERVAL '90 days';

-- ============================================================
-- DONE! Table is ready for error tracking.
-- ============================================================
