#!/bin/bash
# Startet den ZhuLi-Bot lokal. Lädt .env aus dem Projekt-Root.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."

if [ -f "$ROOT/.env" ]; then
  set -a
  source "$ROOT/.env"
  set +a
else
  echo "[ZhuLi] WARN: keine .env gefunden — kopiere .env.example und fülle sie aus"
fi

exec deno run --allow-net --allow-env --allow-read "$SCRIPT_DIR/src/main.ts"
