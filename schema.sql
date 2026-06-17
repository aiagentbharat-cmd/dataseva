-- ============================================================
-- DATASEVA — SUPABASE SCHEMA
-- Run this in Supabase SQL Editor (supabase.com → your project → SQL Editor)
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE 1: COLLECTORS
-- ============================================================
CREATE TABLE collectors (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),

  -- Identity
  first_name        TEXT NOT NULL,
  last_name         TEXT NOT NULL,
  mobile            TEXT NOT NULL UNIQUE,
  email             TEXT,
  age               INT CHECK (age >= 18 AND age <= 65),
  upi_id            TEXT,

  -- Location
  city              TEXT NOT NULL,
  city_other        TEXT,                        -- filled if city = 'Other'
  state             TEXT NOT NULL,
  state_other       TEXT,                        -- filled if state = 'Other'
  pincode           TEXT,

  -- Skills & Tasks
  tasks             TEXT[] NOT NULL DEFAULT '{}', -- ['household','warehouse',...]
  languages         TEXT[] NOT NULL DEFAULT '{}',
  experience_level  TEXT CHECK (experience_level IN ('new','mid','senior')),

  -- Equipment
  camera_equipment  TEXT[] DEFAULT '{}',
  wearable_sensors  TEXT[] DEFAULT '{}',
  home_environment  TEXT,
  internet_speed    TEXT,

  -- Rate
  hourly_rate       INT NOT NULL CHECK (hourly_rate >= 300),
  min_engagement    TEXT DEFAULT '1hr',
  open_to_managed   BOOLEAN DEFAULT TRUE,

  -- Availability
  availability      TEXT[] DEFAULT '{}',

  -- Verification
  aadhaar_verified  BOOLEAN DEFAULT FALSE,
  aadhaar_number    TEXT,                        -- store hashed in production

  -- Profile Status
  status            TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','paused','deleted')),
  paused_until      TIMESTAMPTZ,
  pause_reason      TEXT,
  rejection_note    TEXT,
  admin_note        TEXT,

  -- Bio
  bio               TEXT,

  -- Profile photo (Supabase Storage URL)
  photo_url         TEXT,

  -- Metadata
  profile_views     INT DEFAULT 0,
  contact_unlocks   INT DEFAULT 0
);

-- Index for matchmaking queries
CREATE INDEX idx_collectors_status   ON collectors(status);
CREATE INDEX idx_collectors_city     ON collectors(city);
CREATE INDEX idx_collectors_rate     ON collectors(hourly_rate);
CREATE INDEX idx_collectors_tasks    ON collectors USING GIN(tasks);
CREATE INDEX idx_collectors_languages ON collectors USING GIN(languages);

-- ============================================================
-- TABLE 2: COMPANIES
-- ============================================================
CREATE TABLE companies (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),

  -- Identity
  legal_name        TEXT NOT NULL,
  trade_name        TEXT,
  gstin             TEXT NOT NULL UNIQUE,
  pan               TEXT,
  industry          TEXT,
  company_size      TEXT,

  -- Address
  address           TEXT,
  city              TEXT NOT NULL,
  city_other        TEXT,
  state             TEXT NOT NULL,
  state_other       TEXT,
  pincode           TEXT,

  -- Contact Person
  contact_name      TEXT NOT NULL,
  designation       TEXT,
  email             TEXT NOT NULL UNIQUE,
  mobile            TEXT NOT NULL,

  -- Requirements
  required_tasks    TEXT[] DEFAULT '{}',
  monthly_budget    TEXT,
  preferred_cities  TEXT[] DEFAULT '{}',

  -- Compliance
  consent_confirmed BOOLEAN DEFAULT FALSE,

  -- Status
  status            TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','suspended')),
  gstin_verified    BOOLEAN DEFAULT FALSE,
  rejection_note    TEXT,
  admin_note        TEXT
);

CREATE INDEX idx_companies_status ON companies(status);
CREATE INDEX idx_companies_gstin  ON companies(gstin);
CREATE INDEX idx_companies_city   ON companies(city);

-- ============================================================
-- TABLE 3: CONTACT LOGS (when company unlocks collector phone)
-- ============================================================
CREATE TABLE contact_logs (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  company_id     UUID REFERENCES companies(id) ON DELETE SET NULL,
  collector_id   UUID REFERENCES collectors(id) ON DELETE SET NULL,
  company_name   TEXT,
  collector_name TEXT,
  project_desc   TEXT,
  hours_needed   TEXT,
  status         TEXT DEFAULT 'contacted' CHECK (status IN ('contacted','hired','declined','no_response'))
);

CREATE INDEX idx_contact_logs_company   ON contact_logs(company_id);
CREATE INDEX idx_contact_logs_collector ON contact_logs(collector_id);

-- ============================================================
-- TABLE 4: MANAGED SERVICE QUOTES
-- ============================================================
CREATE TABLE managed_quotes (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  company_name   TEXT NOT NULL,
  gstin          TEXT NOT NULL,
  contact_name   TEXT NOT NULL,
  mobile         TEXT NOT NULL,
  tasks_needed   TEXT[] DEFAULT '{}',
  hours_needed   TEXT,
  budget_range   TEXT,
  description    TEXT,
  plan_selected  TEXT,
  status         TEXT DEFAULT 'new' CHECK (status IN ('new','contacted','proposal_sent','converted','closed'))
);

-- ============================================================
-- TABLE 5: ADMIN USERS (for admin panel login)
-- ============================================================
CREATE TABLE admin_users (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  email       TEXT NOT NULL UNIQUE,
  role        TEXT DEFAULT 'admin' CHECK (role IN ('super_admin','admin','moderator')),
  last_login  TIMESTAMPTZ
);

-- ============================================================
-- TABLE 6: AUDIT LOG (every admin action tracked)
-- ============================================================
CREATE TABLE audit_log (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  admin_email  TEXT NOT NULL,
  action       TEXT NOT NULL,   -- 'approve_collector', 'reject_company', etc.
  target_type  TEXT NOT NULL,   -- 'collector' | 'company'
  target_id    UUID NOT NULL,
  target_name  TEXT,
  note         TEXT
);

CREATE INDEX idx_audit_created ON audit_log(created_at DESC);

-- ============================================================
-- AUTO-UPDATE updated_at TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_collectors_updated BEFORE UPDATE ON collectors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_companies_updated BEFORE UPDATE ON companies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS
ALTER TABLE collectors    ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies     ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_logs  ENABLE ROW LEVEL SECURITY;
ALTER TABLE managed_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log     ENABLE ROW LEVEL SECURITY;

-- Public can INSERT (registration)
CREATE POLICY "collectors_insert" ON collectors FOR INSERT WITH CHECK (true);
CREATE POLICY "companies_insert"  ON companies  FOR INSERT WITH CHECK (true);
CREATE POLICY "quotes_insert"     ON managed_quotes FOR INSERT WITH CHECK (true);
CREATE POLICY "contacts_insert"   ON contact_logs FOR INSERT WITH CHECK (true);

-- Public can only SELECT approved + active collectors (for browse/match)
CREATE POLICY "collectors_select_public" ON collectors FOR SELECT
  USING (status = 'approved');

-- Public can SELECT approved companies (for trust display)
CREATE POLICY "companies_select_public" ON companies FOR SELECT
  USING (status = 'approved');

-- Service role (admin) bypasses RLS — set in Supabase dashboard
-- Use service_role key ONLY in admin panel, never in frontend

-- ============================================================
-- USEFUL VIEWS FOR ADMIN DASHBOARD
-- ============================================================

CREATE VIEW admin_collector_summary AS
SELECT
  id, first_name || ' ' || last_name AS name,
  mobile, city, state, tasks, hourly_rate,
  experience_level, aadhaar_verified,
  status, created_at, admin_note
FROM collectors
ORDER BY created_at DESC;

CREATE VIEW admin_company_summary AS
SELECT
  id, legal_name, gstin, gstin_verified,
  contact_name, email, mobile,
  city, state, industry, monthly_budget,
  status, created_at, admin_note
FROM companies
ORDER BY created_at DESC;

CREATE VIEW admin_dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM collectors WHERE status='pending')   AS pending_collectors,
  (SELECT COUNT(*) FROM collectors WHERE status='approved')  AS approved_collectors,
  (SELECT COUNT(*) FROM collectors WHERE status='rejected')  AS rejected_collectors,
  (SELECT COUNT(*) FROM companies  WHERE status='pending')   AS pending_companies,
  (SELECT COUNT(*) FROM companies  WHERE status='approved')  AS approved_companies,
  (SELECT COUNT(*) FROM companies  WHERE status='rejected')  AS rejected_companies,
  (SELECT COUNT(*) FROM contact_logs)                        AS total_contacts,
  (SELECT COUNT(*) FROM managed_quotes)                      AS total_quotes;

-- ============================================================
-- SEED: Insert your admin user (replace with your email)
-- ============================================================
INSERT INTO admin_users (email, role) VALUES ('admin@dataseva.in', 'super_admin');

-- ============================================================
-- CAPACITY CHECK
-- 100,000 collectors × ~3KB avg = ~300MB  ✓ within 500MB free tier
-- 10,000  companies  × ~2KB avg = ~20MB   ✓
-- 1M contact logs    × ~0.5KB  = ~500MB   → upgrade to Pro ($25/mo) when needed
-- ============================================================
