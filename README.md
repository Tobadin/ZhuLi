# ZhuLi

Persönliche AI-Assistenz für Tasks, Projekte, Kontakte, Briefings und Recherche.
Ersetzt einen historisch gewachsenen n8n-Workflow durch ein sauberes Custom-System.

> *"Zhu Li, do the thing."* — Varrick

## Status
🚧 In Aufbau — siehe [BACKLOG.md](BACKLOG.md)

## Stack
- **Backend**: Supabase (Postgres + PostgREST + Edge Functions), Schema `zhuli.*`
- **Bot**: Deno/TypeScript, Telegram-API
- **AI**: Claude (Anthropic)
- **Frontend** (ab Phase 4): Next.js 14 + Tailwind, mit Gantt/Kanban/Kalender

## Verzeichnisstruktur
```
ZhuLi/
├── CLAUDE.md           # Projekt-Kontext für Claude Code (Vision, Regeln, Phasen)
├── BACKLOG.md          # Stories pro Phase
├── README.md           # diese Datei
├── .gitignore
├── migrations/         # SQL-Migrationen für Schema zhuli.*
│   └── 001_initial_schema.sql
├── scripts/            # Helper-Scripts
│   ├── pull.sh         # n8n-Workflows vom VPS ziehen (Migrations-Quelle)
│   ├── push.sh         # n8n-Workflow zurück pushen
│   └── migrate.sh      # ZhuLi-Migrationen auf VPS anwenden (kommt in Phase 1)
├── workflows/          # Snapshot des alten n8n-Workflows als Spec
│   └── yS1DRrkgwlpDYJek.json
└── bot/                # Bot-Service (kommt in Phase 1)
```

## Phasen (Kurzfassung)
1. **Backend + Schema** — Repo, Supabase-Schema, Migrations
2. **Telegram-Bot komplett** — alle Features als sauberer Bot
3. **Migration + Cut-Over** — ClickUp → ZhuLi, n8n abschalten
4. **Frontend-MVP** — Tasks, Projekte, Kontakte
5. **Wow-Features** — Gantt, Kanban, Kalender, AI-Sidebar
6. **Polish + ClickUp-Kündigung**

Details: [BACKLOG.md](BACKLOG.md)

## Quickstart (für Tobadin)
```bash
cd ~/ZhuLi
claude          # öffnet Claude Code in diesem Projekt
```
Claude kennt durch CLAUDE.md den vollen Kontext und arbeitet das BACKLOG.md ab.

## Wichtig
- **Solange ZhuLi noch nicht fertig ist**: der alte n8n-Workflow ist Daily Driver und bleibt unangetastet
- **Bot wird mit Test-Token entwickelt**, nicht mit dem echten — Cut-Over ist Phase 3
- **Migration ist einmalig**: ClickUp → ZhuLi, danach ist ClickUp read-only
