#!/bin/bash
# Wendet alle migrations/*.sql auf die VPS-Supabase an.
# Idempotent: nutzt zhuli.schema_migrations als Tracking.
# Usage: ./scripts/migrate.sh [--dry-run]
set -e

VPS="tobadin@187.124.3.125"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIG_DIR="$SCRIPT_DIR/../migrations"
DRY_RUN=0
[ "$1" = "--dry-run" ] && DRY_RUN=1

echo "→ ZhuLi Migrations"
[ "$DRY_RUN" = "1" ] && echo "  (DRY RUN — keine Schreibzugriffe)"

# Liste aller Migration-Files
FILES=$(ls "$MIG_DIR"/*.sql 2>/dev/null | sort)
[ -z "$FILES" ] && { echo "Keine Migrations gefunden."; exit 0; }

# Bereits angewandte Migrationen vom VPS holen
APPLIED=$(ssh "$VPS" "docker exec -i supabase-db psql -U postgres -d postgres -tA -c \"SELECT version FROM zhuli.schema_migrations\" 2>/dev/null" || echo "")

for f in $FILES; do
  base=$(basename "$f" .sql)
  if echo "$APPLIED" | grep -qx "$base"; then
    echo "  ✓ $base (übersprungen)"
    continue
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "  → $base (würde angewandt)"
    continue
  fi

  echo "  → $base (anwenden …)"
  cat "$f" | ssh "$VPS" "docker exec -i supabase-db psql -U postgres -d postgres -v ON_ERROR_STOP=1" \
    && echo "  ✓ $base (OK)" \
    || { echo "  ✗ $base FEHLGESCHLAGEN"; exit 1; }
done

echo "Done."
