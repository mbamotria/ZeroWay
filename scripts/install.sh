#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="${THEME_NAME:-ZeroWay}"
THEME_DIR="${THEME_DIR:-/usr/share/sddm/themes}"
SDDM_CONF_DIR="${SDDM_CONF_DIR:-/etc/sddm.conf.d}"
SDDM_CONF_FILE="${SDDM_CONF_FILE:-$SDDM_CONF_DIR/10-zeroway-theme.conf}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$THEME_DIR/$THEME_NAME"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

if [[ "${EUID}" -ne 0 ]]; then
  echo "This installer must run as root."
  echo "Run: sudo ./scripts/install.sh"
  exit 1
fi

mkdir -p "$THEME_DIR"
mkdir -p "$SDDM_CONF_DIR"

if [[ -d "$TARGET_DIR" ]]; then
  BACKUP_DIR="${TARGET_DIR}.bak.${TIMESTAMP}"
  echo "Existing theme found. Backing up to: $BACKUP_DIR"
  mv "$TARGET_DIR" "$BACKUP_DIR"
fi

mkdir -p "$TARGET_DIR"

tar -C "$REPO_ROOT" \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='scripts' \
  --exclude='CodexReport.md' \
  -cf - . | tar -C "$TARGET_DIR" -xf -

cat > "$SDDM_CONF_FILE" <<CFG
[Theme]
Current=$THEME_NAME
CFG

cat <<MSG
Installed theme: $THEME_NAME
Theme path: $TARGET_DIR
SDDM config: $SDDM_CONF_FILE

Next step:
- Restart SDDM or reboot to apply.
MSG
