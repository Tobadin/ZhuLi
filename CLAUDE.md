# ZhuLi — n8n Workflows

## Projekt
Persönliche Assistenz "ZhuLi" auf Basis von n8n + ClickUp. Workflows leben auf dem VPS in der n8n-Instanz und werden hier als JSON versioniert.

## Architektur
- **n8n läuft auf VPS** (`tobadin@187.124.3.125`), Container `n8n`, URL `https://n8n.tobiasseidl.de`
- **Workflows** liegen unter `workflows/` als einzelne JSON-Dateien (Dateiname = Workflow-ID)
- **Export/Import** via `n8n export:workflow` / `n8n import:workflow` CLI im Container (kein API-Key nötig)

## Arbeitsweise
1. **Vor jeder Logik-Änderung**: `./scripts/pull.sh` — zieht aktuelle Workflows vom VPS
2. **Editieren**: JSON direkt in `workflows/` bearbeiten (Function-Nodes, Prompts, Bedingungen)
3. **Pushen**: `./scripts/push.sh <workflow-id>` — re-importiert auf den VPS
4. **Testen**: im n8n-UI (`https://n8n.tobiasseidl.de`) — Live-Daten + Pin-Daten + Execute
5. **Commit**: erst nach erfolgreichem Push, mit aussagekräftiger Message

## Was gehört in Claude Code (hier)
- Function/Code-Node-Logik (JavaScript)
- Prompt-Engineering bei LLM-Nodes
- Bulk-Refactoring über mehrere Workflows
- Suche nach Custom-Field-IDs / List-IDs
- Doku-Generierung aus Workflow-JSON

## Was gehört ins n8n-UI (Browser)
- Neue Workflows zusammenklicken
- Credentials/OAuth einrichten
- Live-Debugging mit echten Executions
- Webhook-Tests

## Wichtige IDs / Konventionen
- Workflow-Dateiname = `<workflow-id>.json` (z.B. `yS1DRrkgwlpDYJek.json`)
- Bei Konflikten: n8n-UI ist Source of Truth — `pull.sh` überschreibt lokal
- Niemals Credentials in JSON committen (n8n speichert sie nur als Referenz, das ist ok)

## Sicherheit
- Keine API-Keys, Tokens, Passwörter in Workflow-JSONs (n8n nutzt Credential-Referenzen — die sind ok)
- `.env` und `secrets/` sind in `.gitignore`
