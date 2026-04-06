#!/bin/bash
# Pusht eine lokale Workflow-JSON zurück in die n8n-Instanz auf dem VPS
# Usage: ./scripts/push.sh <workflow-id>
set -e

VPS="tobadin@187.124.3.125"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WF_DIR="$SCRIPT_DIR/../workflows"

if [ -z "$1" ]; then
  echo "Usage: $0 <workflow-id>"
  exit 1
fi

ID="$1"
FILE="$WF_DIR/$ID.json"
[ -f "$FILE" ] || { echo "✗ $FILE nicht gefunden"; exit 1; }

# n8n import:workflow erwartet ein Array
TMP=$(mktemp)
python3 -c "import json; d=json.load(open('$FILE')); json.dump([d], open('$TMP','w'))"

echo "→ Pushing workflow $ID …"
scp -q "$TMP" "$VPS:/tmp/wf_push_$ID.json"
ssh "$VPS" "docker cp /tmp/wf_push_$ID.json n8n:/tmp/ && docker exec n8n n8n import:workflow --input=/tmp/wf_push_$ID.json && rm /tmp/wf_push_$ID.json && docker exec n8n rm /tmp/wf_push_$ID.json"
rm "$TMP"
echo "✓ Workflow $ID gepusht. Im n8n-UI ggf. neu öffnen."
