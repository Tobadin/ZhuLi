#!/bin/bash
# Zieht alle n8n-Workflows vom VPS und speichert sie als einzelne JSONs in workflows/
# Usage: ./scripts/pull.sh [workflow-id]
#   ohne Argument → alle Workflows
#   mit ID        → nur den einen
set -e

VPS="tobadin@187.124.3.125"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WF_DIR="$SCRIPT_DIR/../workflows"
mkdir -p "$WF_DIR"

if [ -n "$1" ]; then
  ID="$1"
  echo "→ Pulling workflow $ID …"
  JSON=$(ssh "$VPS" "docker exec n8n sh -c 'n8n export:workflow --id=$ID --output=/tmp/wf_$ID.json >/dev/null 2>&1 && cat /tmp/wf_$ID.json && rm /tmp/wf_$ID.json'")
  # n8n exportiert ein Array — wir wollen den ersten Eintrag als pretty-JSON
  echo "$JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d[0], indent=2, ensure_ascii=False))" > "$WF_DIR/$ID.json"
  echo "✓ workflows/$ID.json"
else
  echo "→ Pulling ALL workflows …"
  ssh "$VPS" "docker exec n8n sh -c 'n8n export:workflow --all --separate --output=/tmp/n8n_export/ >/dev/null 2>&1 && tar -C /tmp -czf - n8n_export'" \
    | tar -xzf - -C /tmp/
  for f in /tmp/n8n_export/*.json; do
    ID=$(python3 -c "import json; print(json.load(open('$f'))['id'])")
    python3 -c "import json; d=json.load(open('$f')); print(json.dumps(d, indent=2, ensure_ascii=False))" > "$WF_DIR/$ID.json"
    echo "✓ workflows/$ID.json"
  done
  ssh "$VPS" "docker exec n8n rm -rf /tmp/n8n_export"
  rm -rf /tmp/n8n_export
fi

echo "Done."
