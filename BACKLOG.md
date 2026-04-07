# ZhuLi Backlog

Status-Legende: ⬜ todo · 🟨 in_progress · ✅ done · 🟥 blocked

---

## Phase 1 — Backend + Schema (~2 Tage)

### 1.1 ✅ Repo-Setup
Repo-Skelett, GitHub-Remote, CLAUDE.md, README.md, .gitignore, BACKLOG.md.

### 1.2 ⬜ Supabase-Schema `zhuli.*` (Initial Migration)
Datei: `migrations/001_initial_schema.sql`
- Schema `zhuli` anlegen
- 8 Tabellen: spaces, projects, tasks, contacts, dependencies, sessions, events, ai_interactions
- Indizes auf Foreign Keys + häufig gefilterte Spalten
- Trigger für `updated_at`
- RLS aktivieren (vorerst permissive, später eng)
**DoD**: Migration läuft auf einem leeren Postgres durch (lokal getestet via docker).

### 1.3 ⬜ Migrations-Runner-Script
Datei: `scripts/migrate.sh`
- Liest alle `migrations/*.sql` in Reihenfolge
- Wendet sie auf VPS-Supabase an via SSH+psql
- Tracking-Tabelle `zhuli.schema_migrations` (welche schon angewandt)
**DoD**: `./scripts/migrate.sh` läuft idempotent, zeigt was gemacht wurde.

### 1.4 ⬜ Schema auf VPS deployen
- Via `scripts/migrate.sh` auf VPS-Supabase laufen lassen
- Verifizieren: `\dn zhuli` + `\dt zhuli.*`
**DoD**: Tobadin bestätigt — Schema steht auf Produktiv-VPS.
**⚠️ FREIGABE NÖTIG** vor Ausführung.

### 1.5 ⬜ Bot-Service-Skelett
Verzeichnis: `bot/`
- Deno-Service nach Teamchef-Pattern
- `bot/src/config.ts` — liest .env
- `bot/src/telegram.ts` — Telegram-API-Wrapper
- `bot/src/db.ts` — Supabase-Client (PostgREST)
- `bot/src/claude.ts` — Anthropic-API-Wrapper
- `bot/src/main.ts` — Entry, Polling-Loop
- `.env.example` mit allen nötigen Variablen
**DoD**: `deno run -A bot/src/main.ts` startet ohne Crash, loggt "ready".

### 1.6 ⬜ Session-State in DB
- `bot/src/sessions.ts` — Lese/Schreibe Sessions aus `zhuli.sessions`
- Multi-Step-Dialoge persistieren (überlebt Restarts!)
- Cleanup für alte Sessions (>24h)
**DoD**: Test-Session wird angelegt, geupdated, gelesen — alles in DB.

---

## Phase 2 — Telegram-Bot komplett (~6-7 Tage)

### 2.1 ⬜ Task erfassen (Quick-Add)
Telegram: Text → "ZhuLi Task: …" → Bot fragt Space → Project → Due → Prio → Task in `zhuli.tasks`
**DoD**: Task in DB sichtbar, Telegram-Bestätigung kommt.

### 2.2 ⬜ Task-Aktionen via Buttons
- Erledigt
- Verschieben (Datum-Auswahl)
- Beschreibung anfordern (Inline-Edit)
- Detail anzeigen
**DoD**: Alle 4 Aktionen funktionieren mit Inline-Buttons.

### 2.3 ⬜ Tasks-Liste anzeigen
- Filter: heute, diese Woche, alle, nach Projekt, nach Verantwortlicher
- Pagination
**DoD**: `/tasks` zeigt aktuelle Tasks korrekt gefiltert.

### 2.4 ⬜ Projekt-Management
- Projekt anlegen/umbenennen/archivieren
- Verantwortliche zuweisen
- Beteiligten-Liste pflegen
- Projekt-Status ("Aktiv", "Wartend", "Abgeschlossen")
**DoD**: Projekt-CRUD via Bot funktioniert, Audit in `events`.

### 2.5 ⬜ Kontakte-Modul
- Kontakt anlegen/bearbeiten/notieren
- Kontakt mit Tasks/Projekten verknüpfen
- "Letzter Kontakt"-Feld auto-update
**DoD**: Kontakte werden korrekt gespeichert + verknüpft.

### 2.6 ⬜ Briefing-Mode (Multi-Step)
Telegram-Dialog: Bot stellt strukturierte Fragen → AI generiert Projektbeschreibung → speichert in Project-Description.
**DoD**: Vollständiger Briefing-Flow läuft, Projekt hat danach Beschreibung.

### 2.7 ⬜ Jour-Fixe-Mode (Multi-Round-Dialog)
- Bot eröffnet JF zu einem Projekt
- Mehrere Frage-Antwort-Runden
- AI fasst zusammen → updated Projektbeschreibung
**DoD**: JF läuft Multi-Round, am Ende ist Projekt-Doc aktualisiert.

### 2.8 ⬜ Tägliches Briefing (Cron)
Edge Function `zhuli-daily-briefing`, Cron 07:00:
- Lädt offene Tasks + Google Calendar + relevante Projekte
- Claude generiert Briefing-Text
- Sendet via Telegram
**DoD**: Cron triggert, Briefing kommt an.

### 2.9 ⬜ Recherche-Modul
- Telegram: "ZhuLi recherchiere: …"
- Anthropic Web Search → Ergebnis
- Optional: Nachfrage-Loop
- Optional: in Projekt/Task-Beschreibung speichern
**DoD**: Recherche läuft End-to-End.

### 2.10 ⬜ Dependencies
- Task A blockiert Task B → in `zhuli.dependencies`
- Bei Erledigung von A → B wird "befreit", Notification
- Dep entfernen
**DoD**: Dependency-Graph funktioniert, Befreiung triggert.

### 2.11 ⬜ Auto-Tagging nach täglichem Briefing
- Nach Briefing: Tasks ohne Verantwortliche → AI rät → setzt
- Tasks ohne Prio → AI klassifiziert
**DoD**: Tasks werden nach Briefing angereichert.

### 2.12 ⬜ Chat-Mode (allgemeiner AI-Chat mit Kontext)
- Telegram: freie Frage → Bot lädt Tasks/Projekte als Kontext → Claude antwortet
**DoD**: Chat funktioniert mit Projekt-Kontext.

### 2.13 ⬜ Projekt-Notizen
- Notiz an Projekt anhängen → AI klassifiziert → in passendes Doc/Section
**DoD**: Notizen landen sortiert.

### 2.14 ⬜ Fehler-Behandlung + Logging
- Alle Fehler in `zhuli.events`
- Telegram-Notification bei kritischen Fehlern
**DoD**: Bot fällt nicht stumm aus.

---

## Phase 3 — Migration + Cut-Over (~1-2 Tage)

### 3.1 ⬜ Mapping-Session mit Tobadin
- Welche ClickUp-Custom-Fields → welche ZhuLi-Felder?
- Welche Tag-Hacks fallen weg?
- Welche Spaces/Lists werden migriert, welche archiviert?
**DoD**: Mapping-Doc `migrations/clickup_mapping.md` erstellt.
**⚠️ FREIGABE NÖTIG** — manuelle Session.

### 3.2 ⬜ Migrations-Skript ClickUp → ZhuLi
Datei: `scripts/migrate-from-clickup.ts`
- Liest via ClickUp-API: Spaces, Folders, Lists, Tasks, Comments, Tags, Custom Fields, Dependencies, Contacts
- Mappt auf ZhuLi-Schema
- Schreibt in Supabase
- Idempotent über `clickup_id`
- Trockenlauf-Modus (`--dry-run`)
**DoD**: Trockenlauf zeigt was migriert würde, ohne zu schreiben.

### 3.3 ⬜ Trockenlauf
- Migration mit `--dry-run` auf echten ClickUp-Daten
- Tobadin reviewed das Ergebnis
**DoD**: Tobadin akzeptiert das Mapping.

### 3.4 ⬜ Scharfe Migration (CUT-OVER)
**⚠️ FREIGABE NÖTIG** — geplanter Termin.
- Migration laufen lassen
- n8n-Workflow auf VPS deaktivieren
- ZhuLi-Bot scharf schalten (echtes Tobadin-Token)
**DoD**: ZhuLi ist Daily Driver. ClickUp wird read-only behandelt.

---

## Phase 4 — Frontend-MVP (~4-5 Tage)

### 4.0 ⬜ Architektur-Entscheidung: Hausmeter-Modul vs. eigenständig
**⚠️ FREIGABE NÖTIG** — strategische Entscheidung mit Tobadin.

### 4.1 ⬜ Next.js-Setup
- Tailwind, TypeScript, Supabase JS, Auth-Layout
- Login mit Supabase Auth (Tobadin als Superadmin)
**DoD**: Login funktioniert, leeres Dashboard erreichbar.

### 4.2 ⬜ Tasks-Liste
- Tabelle (Desktop) + Cards (Mobile)
- Filter: Status, Projekt, Verantwortliche, Due
- Inline-Erledigt-Button
**DoD**: Alle Tasks sichtbar, filterbar, erledigbar.

### 4.3 ⬜ Task-Detail-Seite
- Alle Felder editierbar (Inline)
- Kommentare/Notizen
- Dependencies sichtbar
**DoD**: Task vollständig editierbar im Web.

### 4.4 ⬜ Projekt-Übersicht + Detail
- Liste aller Projekte
- Projekt-Detail mit Tasks, Beteiligten, Beschreibung
**DoD**: Projekt-CRUD im Web.

### 4.5 ⬜ Kontakte
- Liste + Detail + Verknüpfungen zu Tasks/Projekten
**DoD**: Kontakte im Web nutzbar.

### 4.6 ⬜ Quick-Add (Modal mit Shortcuts)
- Tastenkürzel `n` öffnet Modal
- Schnell-Erfassung wie im Telegram
**DoD**: 5-Sekunden-Task-Erfassung.

### 4.7 ⬜ Mobile-Polish
**DoD**: Auf Handy bedienbar, alle Views responsive.

---

## Phase 5 — Wow-Features (~3-5 Tage)

### 5.1 ⬜ Gantt-Chart
- Library: `frappe-gantt` oder `gantt-task-react`
- Drag&Drop für Daten
- Dependencies als Pfeile
**DoD**: Gantt zeigt aktuelle Tasks korrekt.

### 5.2 ⬜ Kanban-Board
- Library: `@dnd-kit`
- Spalten: Backlog, Heute, Diese Woche, Erledigt
**DoD**: Drag&Drop ändert Status.

### 5.3 ⬜ Kalender-View
- Library: `fullcalendar`
- Tasks + Google-Cal-Events overlay
**DoD**: Kalender-View funktioniert, GCal sichtbar.

### 5.4 ⬜ AI-Sidebar
- Permanenter Chat rechts
- Kontext: aktueller Screen (Projekt/Task)
- Streaming-Antworten
**DoD**: AI-Sidebar überall verfügbar.

### 5.5 ⬜ Globale Suche
- Postgres FTS
- Suche über Tasks/Projekte/Kontakte/Notizen
**DoD**: `/` öffnet Suche, Ergebnisse in <500ms.

---

## Phase 6 — Polish + ClickUp-Kündigung (~2 Tage)

### 6.1 ⬜ Performance-Pass
- Lazy Loading, Pagination, Caching
**DoD**: Alles schnell auch bei 1000+ Tasks.

### 6.2 ⬜ Notifications
- Browser Push für Web
- Telegram für mobile
**DoD**: Notifications kommen an.

### 6.3 ⬜ Backup-Strategie
- Tägliches DB-Backup von `zhuli.*`
**DoD**: Backup läuft als Cron, getestet wiederherstellbar.

### 6.4 ⬜ ClickUp-Account kündigen
**⚠️ FREIGABE NÖTIG** — finaler Schritt nach 4 Wochen Probebetrieb.
**DoD**: Account gekündigt, Backup von ClickUp-Export im Repo.
