#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
# and fix volume ownership only when a remap is needed
changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

if [ "$changed" = "1" ]; then
    chown -R node:node /paperclip
fi

# Railway mounts volumes as root. Ensure the mount point is always writable
# by node regardless of whether UID/GID remapping triggered above.
chown node:node /paperclip

# Pre-configure OpenCode to allow external_directory access in headless mode.
# Only written if absent so a richer config written post-setup is preserved.
mkdir -p /paperclip/.config/opencode
if [ ! -f /paperclip/.config/opencode/opencode.json ]; then
    echo '{"permission":"allow"}' > /paperclip/.config/opencode/opencode.json
    chown node:node /paperclip/.config/opencode/opencode.json
fi

# Generate one-time bootstrap invite if not already done.
# Output logged to stdout so the invite URL appears in Railway deployment logs.
gosu node node /app/bootstrap.cjs

exec gosu node "$@"
