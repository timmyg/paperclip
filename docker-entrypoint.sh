#!/bin/sh
set -e
# Railway volumes mount as root-owned. Fix ownership before dropping to node user.
chown -R node:node /paperclip

# Write Codex OAuth auth.json from CODEX_AUTH_JSON env var (full JSON blob)
if [ -n "$CODEX_AUTH_JSON" ]; then
  mkdir -p /paperclip/.codex
  printf '%s' "$CODEX_AUTH_JSON" > /paperclip/.codex/auth.json
  chown -R node:node /paperclip/.codex
  echo "Codex auth.json written from CODEX_AUTH_JSON env var"
fi

# Pre-configure OpenCode to allow external_directory permissions (headless mode)
OPENCODE_CONFIG_DIR="/home/node/.config/opencode"
OPENCODE_CONFIG="$OPENCODE_CONFIG_DIR/opencode.json"
mkdir -p "$OPENCODE_CONFIG_DIR"
if [ -f "$OPENCODE_CONFIG" ]; then
  # Merge permission into existing config
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$OPENCODE_CONFIG','utf8'));
    cfg.permission = 'allow';
    fs.writeFileSync('$OPENCODE_CONFIG', JSON.stringify(cfg, null, 2) + '\n');
  " 2>/dev/null || true
else
  printf '{"permission":"allow"}\n' > "$OPENCODE_CONFIG"
fi
chown -R node:node "$OPENCODE_CONFIG_DIR"
echo "OpenCode permission=allow configured"

exec gosu node "$@"
