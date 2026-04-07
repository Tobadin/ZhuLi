# ZhuLi — Persönliche Assistenz (n8n-Workflow-Ablösung)

## Vision
ZhuLi ist Tobadins persönliche AI-Assistenz für Tasks, Projekte, Kontakte, Briefings und Recherche. Sie ersetzt einen historisch gewachsenen n8n-Workflow (277 Nodes, monolithisch, fragil) durch ein sauberes Custom-System mit eigenem Datenmodell, Telegram-Bot und (später) Web-Frontend mit Gantt/Kanban/Kalender.

**Namensherkunft**: Zhu Li (Korra) — die immer alles erledigt.

## Strategie
**Bauen ohne Parallelbetrieb.** ZhuLi wird vollständig fertiggebaut und getestet, BEVOR sie produktiv genutzt wird. Bis dahin bleibt der alte n8n-Workflow Tobadins Daily Driver. Cut-Over erfolgt an einem definierten Tag mit einmaliger Datenmigration aus ClickUp.

**Ziel: ClickUp ersetzen.** Eigenes Datenmodell ist Source of Truth. ClickUp-Account wird nach 4 Wochen Probebetrieb gekündigt.

## Phasen (siehe BACKLOG.md für Details)
1. **Backend + Schema** (~2 Tage) — Repo, Supabase-Schema `zhuli.*`, Migrations
2. **Telegram-Bot komplett** (~6-7 Tage) — alle Features des n8n-Workflows als sauberer Bot
3. **Migration + Cut-Over** (~1-2 Tage) — ClickUp → ZhuLi, n8n abschalten
4. **Frontend-MVP** (~4-5 Tage) — Tasks, Projekte, Kontakte, Quick-Add, Mobile
5. **Wow-Features** (~3-5 Tage) — Gantt, Kanban, Kalender, AI-Sidebar, Suche
6. **Polish + ClickUp-Kündigung** (~2 Tage)

**Total: ~18-22 Arbeitstage über mehrere Wochen.**

## Architektur (FEST)

### Backend
- **Datenbank**: Supabase auf VPS (`tobadin@187.124.3.125`), eigenes Schema `zhuli.*`
- **API**: PostgREST automatisch (Supabase) — KEINE eigene REST-API bauen
- **Custom-Logik**: Supabase Edge Functions (Deno/TypeScript), Prefix `zhuli-*`
- **Bot-Service**: Deno-Service nach Teamchef-Pattern, läuft als systemd-Service auf dem Keller-PC
- **AI**: Claude API (Anthropic), Modell nach Use-Case (Sonnet für Routine, Opus für komplexe Briefings)

### Frontend (ab Phase 4)
- **Entscheidung Hausmeter-Modul vs. eigenständig**: WIRD IN PHASE 4 GETROFFEN, nicht jetzt
- Default-Annahme: eigenständige Next.js-App unter `zhuli.tobiasseidl.de`
- Falls Hausmeter-Modul: eigene Routes `/zhuli/*`, eigene Tabellen, additive UI-Komponenten

### Externe Integrationen
- **Telegram** — primärer Eingabe-Kanal (Bot-Token in `.env`)
- **Google Calendar** — read-only für tägliches Briefing
- **ClickUp** — nur in Phase 3 für Migration, danach NICHT mehr
- **Anthropic Web Search** — für Recherche-Modul

## Architektur-Regeln (verbindlich)
1. **KEINE neuen Container** — alles läuft auf der bestehenden Supabase-Instanz + lokalem Bot-Service
2. **KEINE eigene REST-API** — PostgREST + Edge Functions reichen
3. **Schema `zhuli.*`** — keine Vermischung mit `public.*` (Hausmeter)
4. **Eigene Migrationen** in `migrations/` — versioniert, idempotent wo möglich
5. **Keine Secrets in Git** — `.env`, Tokens, Credentials in `.gitignore`
6. **Idempotente Operationen** wo möglich (Migration muss mehrfach laufbar sein)
7. **Audit-Log Pflicht** — jede Mutation schreibt in `zhuli.events`

## Datenmodell (Phase 1)
8 Kerntabellen im Schema `zhuli.*`:
- `spaces` — Bereiche (Privat, Hausmeter, Sonstiges, ...)
- `projects` — Projekte innerhalb eines Space
- `tasks` — Aufgaben (gehören zu Project oder direkt zu Space)
- `contacts` — Kontakte (Person/Firma)
- `dependencies` — Task-zu-Task Abhängigkeiten
- `sessions` — Multi-Step-Dialoge im Telegram-Bot (State!)
- `events` — Audit-Log
- `ai_interactions` — Chat-History + Claude-Calls

Details siehe `migrations/001_initial_schema.sql`.

## Arbeitsweise (für Claude Code)

### Wenn du in einer ZhuLi-Session bist
1. **Lies BACKLOG.md** — was ist als nächstes dran?
2. **Status: in_progress markieren**, dann arbeiten
3. **Pro Story**: Code schreiben → testen → committen → Status: done
4. **Bei Unklarheiten**: Tobadin fragen, NICHT raten
5. **Bei Architektur-Entscheidungen**: Tobadin fragen, NICHT vorpreschen
6. **Tobadin hat YOLO erlaubt** — du darfst proaktiv arbeiten, aber bei Architektur-Brüchen, externen Calls (n8n abschalten, ClickUp-Schreibzugriff, Migrations scharf laufen) IMMER fragen

### Was du NICHT tun darfst (ohne Bestätigung)
- Migration scharf laufen lassen (Daten aus ClickUp ziehen)
- n8n-Workflow auf VPS deaktivieren
- Bestehende Hausmeter-Tabellen anfassen
- Telegram-Bot mit Tobadin-Token starten (nur Test-Token)
- ClickUp-Account kündigen
- Force-Push, History-Rewrite

### Was du IMMER tun darfst (YOLO)
- Code in `~/ZhuLi/` schreiben/ändern/löschen
- Lokale Tests laufen lassen
- Migrations-SQL schreiben (nicht ausführen)
- Bot-Logik bauen
- Edge Functions schreiben
- Git committen + zu GitHub pushen
- BACKLOG.md aktualisieren
- Schema iterieren

## Tech-Konventionen
- **TypeScript** — strict mode, keine `any`-Wildwüchse
- **Deno** für Bot + Edge Functions (kein Node)
- **Tabellennamen**: englisch, snake_case, plural (`tasks`, `contacts`)
- **UUIDs** als Primary Keys (`gen_random_uuid()`)
- **Timestamps**: `created_at`, `updated_at` mit `TIMESTAMPTZ DEFAULT now()`
- **RLS**: Erstmal nur Tobadin als einziger User, später erweiterbar
- **Bot-Sessions**: in `zhuli.sessions` persistiert (NICHT im Bot-RAM, damit Restarts überleben)

## Wichtige Referenzen
- **n8n-Workflow als Spec**: `workflows/yS1DRrkgwlpDYJek.json` (277 Nodes, alle Features die ZhuLi nachbauen muss)
- **Teamchef als Vorbild**: `~/teamchef/src/` (Bot-Pattern, Telegram-Integration, Claude-Wrapper)
- **Hausmeter CLAUDE.md**: `~/teamchef/CLAUDE.md` (VPS-Zugang, Supabase-Konventionen)
- **ClickUp-Daten** (für Migration): via ClickUp-API, Token kommt vor Phase 3 von Tobadin

## VPS-Zugang (geerbt von Hausmeter)
```
ssh tobadin@187.124.3.125
```
Supabase: `~/services/supabase/supabase/docker/`
DB: `docker exec -i supabase-db psql -U postgres -d postgres`

## Repo
- **GitHub**: https://github.com/Tobadin/ZhuLi
- **Branch**: `master` (default)
- **Lokal**: `~/ZhuLi/`
