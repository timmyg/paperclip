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

exec gosu node "$@"
