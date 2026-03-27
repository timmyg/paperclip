#!/bin/sh
set -e
# Railway volumes mount as root-owned. Fix ownership before dropping to node user.
chown -R node:node /paperclip

# Write Codex OAuth auth.json from env vars (ChatGPT subscription auth)
if [ -n "$CODEX_REFRESH_TOKEN" ]; then
  mkdir -p /paperclip/.codex
  cat > /paperclip/.codex/auth.json <<AUTHEOF
{
  "auth_mode": "chatgpt",
  "OPENAI_API_KEY": null,
  "tokens": {
    "id_token": null,
    "access_token": null,
    "refresh_token": "${CODEX_REFRESH_TOKEN}",
    "account_id": "${CODEX_ACCOUNT_ID:-}"
  },
  "last_refresh": null
}
AUTHEOF
  chown -R node:node /paperclip/.codex
  echo "Codex OAuth auth.json written from env vars"
fi

exec gosu node "$@"
