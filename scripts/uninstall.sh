#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="${THEME_NAME:-ZeroWay}"
THEME_DIR="${THEME_DIR:-/usr/share/sddm/themes}"
SDDM_CONF_DIR="${SDDM_CONF_DIR:-/etc/sddm.conf.d}"
SDDM_CONF_FILE="${SDDM_CONF_FILE:-$SDDM_CONF_DIR/10-zeroway-theme.conf}"
TARGET_DIR="$THEME_DIR/$THEME_NAME"

if [[ "${EUID}" -ne 0 ]]; then
  echo "This uninstaller must run as root."
  echo "Run: sudo ./scripts/uninstall.sh"
  exit 1
fi

if [[ -d "$TARGET_DIR" ]]; then
  rm -rf "$TARGET_DIR"
  echo "Removed theme directory: $TARGET_DIR"
else
  echo "Theme directory not found: $TARGET_DIR"
fi

if [[ -f "$SDDM_CONF_FILE" ]]; then
  rm -f "$SDDM_CONF_FILE"
  echo "Removed SDDM config: $SDDM_CONF_FILE"
else
  echo "SDDM config not found: $SDDM_CONF_FILE"
fi

cat <<MSG
Uninstall complete for theme: $THEME_NAME

If SDDM fails to load, set another theme manually in your SDDM config.
MSG
