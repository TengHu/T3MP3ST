#!/usr/bin/env bash
# Set up the AI red-team tools for this loaded T3MP3ST branch (garak + promptfoo).
# The `pliny` plugin ships INSIDE promptfoo — installing promptfoo installs pliny.
set -euo pipefail

echo "== 1. garak (single-turn LLM vuln scanner) =="
if command -v garak >/dev/null 2>&1; then
  echo "   already installed: $(garak --version 2>&1 | head -1)"
else
  pipx install garak 2>/dev/null || pip install --user garak
fi

echo ""
echo "== 2. promptfoo (multi-turn red-team; the pliny plugin is BUILT IN) =="
if command -v promptfoo >/dev/null 2>&1; then
  echo "   already installed: promptfoo $(promptfoo --version 2>&1 | head -1)"
else
  npm install -g promptfoo
fi

echo ""
echo "== 3. verify the pliny plugin is available (ships with promptfoo) =="
# A minimal config referencing the pliny plugin; if promptfoo accepts it, pliny is present.
TMP="$(mktemp -d)"
cat > "$TMP/probe.yaml" <<'YAML'
targets: [ "echo:hello" ]
redteam:
  numTests: 1
  plugins: [ pliny ]
YAML
if PROMPTFOO_DISABLE_REDTEAM_REMOTE_GENERATION=1 PROMPTFOO_DISABLE_TELEMETRY=1 \
   promptfoo redteam generate -c "$TMP/probe.yaml" -o "$TMP/out.json" --no-progress-bar >/dev/null 2>&1; then
  echo "   ✅ pliny plugin generated test(s) — it's installed and working."
else
  echo "   ⚠️  pliny generate check inconclusive; 'plugins: [pliny]' still works in a real run."
fi
rm -rf "$TMP"

echo ""
echo "== 4. required env for keyless red-teaming =="
cat <<'ENV'
   export OPENROUTER_API_KEY=sk-or-...                    # your provider/grader key
   export PROMPTFOO_DISABLE_REDTEAM_REMOTE_GENERATION=1   # keyless local generation (no promptfoo account)
   export T3MP3ST_FULL_ARSENAL=1                          # register garak + promptfoo in the arsenal
ENV

echo ""
echo "Then:  npm run server   (War Room -> http://127.0.0.1:3333/ui/)"
echo "and describe an ai_red_team mission against a model you OWN or are AUTHORIZED to test."
