-- ============================================
-- ZhuLi — Initial Schema
-- Migration: 001
-- Schema:    zhuli.*
-- ============================================
-- Idempotent: kann mehrfach ausgeführt werden ohne Fehler.

CREATE SCHEMA IF NOT EXISTS zhuli;

-- ── Tracking-Tabelle für Migrations ───────────────────
CREATE TABLE IF NOT EXISTS zhuli.schema_migrations (
  version    TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── updated_at Trigger-Funktion ───────────────────────
CREATE OR REPLACE FUNCTION zhuli.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SPACES — Bereiche (Privat, Hausmeter, ...)
-- ============================================
CREATE TABLE IF NOT EXISTS zhuli.spaces (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  description TEXT,
  color       TEXT,                                  -- Hex oder Tailwind-Klasse
  position    INTEGER NOT NULL DEFAULT 0,
  archived    BOOLEAN NOT NULL DEFAULT FALSE,
  clickup_id  TEXT UNIQUE,                           -- für Migration
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_spaces_archived ON zhuli.spaces(archived);
DROP TRIGGER IF EXISTS trg_spaces_updated_at ON zhuli.spaces;
CREATE TRIGGER trg_spaces_updated_at BEFORE UPDATE ON zhuli.spaces
  FOR EACH ROW EXECUTE FUNCTION zhuli.set_updated_at();

-- ============================================
-- PROJECTS — Projekte innerhalb eines Space
-- ============================================
CREATE TABLE IF NOT EXISTS zhuli.projects (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id      UUID NOT NULL REFERENCES zhuli.spaces(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT,                                -- AI-generiert via Briefing/JF
  status        TEXT NOT NULL DEFAULT 'active',      -- active|waiting|done|archived
  responsible   UUID REFERENCES zhuli.contacts(id),  -- Verantwortlicher (FK kommt unten via ALTER)
  start_date    DATE,
  due_date      DATE,
  position      INTEGER NOT NULL DEFAULT 0,
  metadata      JSONB NOT NULL DEFAULT '{}'::jsonb,
  clickup_id    TEXT UNIQUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- responsible-FK weiter unten nach contacts-Definition
CREATE INDEX IF NOT EXISTS idx_projects_space ON zhuli.projects(space_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON zhuli.projects(status);
DROP TRIGGER IF EXISTS trg_projects_updated_at ON zhuli.projects;
CREATE TRIGGER trg_projects_updated_at BEFORE UPDATE ON zhuli.projects
  FOR EACH ROW EXECUTE FUNCTION zhuli.set_updated_at();

-- ============================================
-- CONTACTS — Personen / Firmen
-- ============================================
CREATE TABLE IF NOT EXISTS zhuli.contacts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  type            TEXT NOT NULL DEFAULT 'person',    -- person|company
  email           TEXT,
  phone           TEXT,
  company         TEXT,
  notes           TEXT,
  last_contact_at TIMESTAMPTZ,
  tags            TEXT[] DEFAULT '{}',
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
  clickup_id      TEXT UNIQUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_contacts_name ON zhuli.contacts(name);
CREATE INDEX IF NOT EXISTS idx_contacts_email ON zhuli.contacts(email);
DROP TRIGGER IF EXISTS trg_contacts_updated_at ON zhuli.contacts;
CREATE TRIGGER trg_contacts_updated_at BEFORE UPDATE ON zhuli.contacts
  FOR EACH ROW EXECUTE FUNCTION zhuli.set_updated_at();

-- Jetzt FK von projects.responsible → contacts.id
DO $$ BEGIN
  ALTER TABLE zhuli.projects
    ADD CONSTRAINT fk_projects_responsible
    FOREIGN KEY (responsible) REFERENCES zhuli.contacts(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- TASKS — Aufgaben
-- ============================================
CREATE TABLE IF NOT EXISTS zhuli.tasks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id      UUID NOT NULL REFERENCES zhuli.spaces(id) ON DELETE CASCADE,
  project_id    UUID REFERENCES zhuli.projects(id) ON DELETE SET NULL,
  title         TEXT NOT NULL,
  description   TEXT,
  status        TEXT NOT NULL DEFAULT 'open',        -- open|in_progress|done|archived
  priority      INTEGER,                             -- 1=high, 2, 3, 4, 5=low
  due_date      DATE,
  start_date    DATE,
  responsible   UUID REFERENCES zhuli.contacts(id) ON DELETE SET NULL,
  participants  UUID[] DEFAULT '{}',                 -- weitere beteiligte contacts
  tags          TEXT[] DEFAULT '{}',
  position      INTEGER NOT NULL DEFAULT 0,
  metadata      JSONB NOT NULL DEFAULT '{}'::jsonb,  -- frei für Migration aus ClickUp custom fields
  clickup_id    TEXT UNIQUE,
  completed_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tasks_space ON zhuli.tasks(space_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project ON zhuli.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON zhuli.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due ON zhuli.tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_responsible ON zhuli.tasks(responsible);
DROP TRIGGER IF EXISTS trg_tasks_updated_at ON zhuli.tasks;
CREATE TRIGGER trg_tasks_updated_at BEFORE UPDATE ON zhuli.tasks
  FOR EACH ROW EXECUTE FUNCTION zhuli.set_updated_at();

-- ============================================
-- DEPENDENCIES — Task-zu-Task Abhängigkeiten
-- ============================================
CREATE TABLE IF NOT EXISTS zhuli.dependencies (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocking_id   UUID NOT NULL REFERENCES zhuli.tasks(id) ON DELETE CASCADE, -- diese Task blockiert ...
  blocked_id    UUID NOT NULL REFERENCES zhuli.tasks(id) ON DELETE CASCADE, -- ... diese Task
  type          TEXT NOT NULL DEFAULT 'blocks',      -- blocks|relates|duplicates
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (blocking_id, blocked_id, type),
  CHECK (blocking_id <> blocked_id)
);
CREATE INDEX IF NOT EXISTS idx_deps_blocking ON zhuli.dependencies(blocking_id);
CREATE INDEX IF NOT EXISTS idx_deps_blocked ON zhuli.dependencies(blocked_id);

-- ============================================
-- SESSIONS — Multi-Step-Dialoge des Telegram-Bots
-- ============================================
CREATE TABLE IF NOT EXISTS zhuli.sessions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       BIGINT NOT NULL,                     -- Telegram-User-ID
  flow          TEXT NOT NULL,                       -- 'task_create' | 'briefing' | 'jour_fixe' | ...
  step          TEXT NOT NULL,                       -- aktueller Schritt
  state         JSONB NOT NULL DEFAULT '{}'::jsonb,  -- alles was der Flow braucht
  expires_at    TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '24 hours'),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON zhuli.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON zhuli.sessions(expires_at);
DROP TRIGGER IF EXISTS trg_sessions_updated_at ON zhuli.sessions;
CREATE TRIGGER trg_sessions_updated_at BEFORE UPDATE ON zhuli.sessions
  FOR EACH ROW EXECUTE FUNCTION zhuli.set_updated_at();

-- ============================================
-- EVENTS — Audit-Log für alles
-- ============================================
CREATE TABLE IF NOT EXISTS zhuli.events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type          TEXT NOT NULL,                       -- task.created | task.completed | error | ...
  entity_type   TEXT,                                -- task | project | contact | ...
  entity_id     UUID,
  user_id       BIGINT,
  payload       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_events_type ON zhuli.events(type);
CREATE INDEX IF NOT EXISTS idx_events_entity ON zhuli.events(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_events_created ON zhuli.events(created_at DESC);

-- ============================================
-- AI_INTERACTIONS — Chat-History + Claude-Calls
-- ============================================
CREATE TABLE IF NOT EXISTS zhuli.ai_interactions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       BIGINT,
  context       TEXT NOT NULL,                       -- 'chat' | 'briefing' | 'jour_fixe' | 'research' | ...
  entity_type   TEXT,                                -- bei Bezug zu task/project/contact
  entity_id     UUID,
  model         TEXT NOT NULL,                       -- claude-sonnet-4-6 etc.
  prompt        TEXT NOT NULL,
  response      TEXT,
  tokens_in     INTEGER,
  tokens_out    INTEGER,
  duration_ms   INTEGER,
  error         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ai_user ON zhuli.ai_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_context ON zhuli.ai_interactions(context);
CREATE INDEX IF NOT EXISTS idx_ai_created ON zhuli.ai_interactions(created_at DESC);

-- ============================================
-- RLS (vorerst permissive für service_role, später eng)
-- ============================================
ALTER TABLE zhuli.spaces           ENABLE ROW LEVEL SECURITY;
ALTER TABLE zhuli.projects         ENABLE ROW LEVEL SECURITY;
ALTER TABLE zhuli.contacts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE zhuli.tasks            ENABLE ROW LEVEL SECURITY;
ALTER TABLE zhuli.dependencies     ENABLE ROW LEVEL SECURITY;
ALTER TABLE zhuli.sessions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE zhuli.events           ENABLE ROW LEVEL SECURITY;
ALTER TABLE zhuli.ai_interactions  ENABLE ROW LEVEL SECURITY;

-- Service-Role darf alles (Bot greift mit service_role zu)
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['spaces','projects','contacts','tasks','dependencies','sessions','events','ai_interactions']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS service_all ON zhuli.%I', t);
    EXECUTE format('CREATE POLICY service_all ON zhuli.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', t);
  END LOOP;
END $$;

-- ── Migration vermerken ───────────────────────
INSERT INTO zhuli.schema_migrations(version) VALUES ('001_initial_schema')
  ON CONFLICT (version) DO NOTHING;
