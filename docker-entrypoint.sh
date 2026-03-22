#!/bin/sh
set -e
# Railway volumes mount as root-owned. Fix ownership before dropping to node user.
chown -R node:node /paperclip
exec gosu node "$@"
