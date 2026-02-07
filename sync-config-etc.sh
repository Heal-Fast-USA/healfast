#!/bin/bash
# Sync config/ to config_etc/ so bahmni-config container sees two distinct dirs (avoids "same file" cp error).
# Run once before first start, and after any change to config/.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config"
CONFIG_ETC="$SCRIPT_DIR/config_etc"
if [ ! -d "$CONFIG" ]; then
  echo "Error: $CONFIG not found." >&2
  exit 1
fi
mkdir -p "$CONFIG_ETC"
rsync -a --delete "$CONFIG/" "$CONFIG_ETC/" 2>/dev/null || cp -r "$CONFIG"/. "$CONFIG_ETC/"
echo "Synced $CONFIG -> $CONFIG_ETC"
