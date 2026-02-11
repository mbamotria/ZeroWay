#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="${THEME_NAME:-ZeroWay}"
THEME_DIR="${THEME_DIR:-/usr/share/sddm/themes}"
SDDM_CONF_DIR="${SDDM_CONF_DIR:-/etc/sddm.conf.d}"
SDDM_CONF_FILE="${SDDM_CONF_FILE:-$SDDM_CONF_DIR/10-zeroway-theme.conf}"
ACTIVATE_THEME="${ACTIVATE_THEME:-1}"
SKIP_DEP_CHECK="${SKIP_DEP_CHECK:-0}"
AUTO_INSTALL_DEPS="${AUTO_INSTALL_DEPS:-1}"
DEBUG_DEP_CHECK="${DEBUG_DEP_CHECK:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$THEME_DIR/$THEME_NAME"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

QML_ROOTS=(
  "/usr/lib/qt/qml"
  "/usr/lib/qt5/qml"
  "/usr/lib/qt6/qml"
  "/usr/lib64/qt5/qml"
  "/usr/lib64/qt6/qml"
  "/usr/lib/x86_64-linux-gnu/qt5/qml"
  "/usr/lib/x86_64-linux-gnu/qt6/qml"
  "/usr/lib/aarch64-linux-gnu/qt5/qml"
  "/usr/lib/aarch64-linux-gnu/qt6/qml"
)

collect_qml_roots() {
  local discovered=()
  local cmd out line

  discovered+=("${QML_ROOTS[@]}")

  if [[ -n "${QML2_IMPORT_PATH:-}" ]]; then
    IFS=':' read -r -a out <<< "${QML2_IMPORT_PATH}"
    discovered+=("${out[@]}")
  fi

  for cmd in qtpaths qtpaths6 qtpaths5; do
    if command -v "$cmd" >/dev/null 2>&1; then
      line="$($cmd --query QML2_IMPORT_PATH 2>/dev/null || true)"
      if [[ -n "$line" ]]; then
        IFS=':' read -r -a out <<< "$line"
        discovered+=("${out[@]}")
      fi
    fi
  done

  if [[ "$DEBUG_DEP_CHECK" == "1" ]]; then
    echo "QML roots being checked:"
  fi

  local root
  local -A seen=()
  for root in "${discovered[@]}"; do
    [[ -z "$root" ]] && continue
    [[ ! -d "$root" ]] && continue
    if [[ -z "${seen[$root]:-}" ]]; then
      seen[$root]=1
      if [[ "$DEBUG_DEP_CHECK" == "1" ]]; then
        echo "- $root"
      fi
      printf '%s\n' "$root"
    fi
  done
}

has_qml_module() {
  local module_path="$1"
  local root
  while IFS= read -r root; do
    if [[ -d "$root/$module_path" ]]; then
      return 0
    fi
  done < <(collect_qml_roots)
  return 1
}

detect_missing_modules() {
  local missing=()
  if ! has_qml_module "QtQuick"; then
    missing+=("QtQuick")
  fi
  if ! has_qml_module "QtQuick/Controls"; then
    missing+=("QtQuick.Controls")
  fi
  if ! has_qml_module "QtGraphicalEffects"; then
    missing+=("QtGraphicalEffects")
  fi
  if ! has_qml_module "SddmComponents"; then
    missing+=("SddmComponents")
  fi
  printf '%s\n' "${missing[@]}"
}

try_install_dependencies() {
  if [[ "$AUTO_INSTALL_DEPS" != "1" ]]; then
    return 1
  fi

  if command -v pacman >/dev/null 2>&1; then
    echo "Attempting to install required dependencies via pacman..."
    pacman -S --needed sddm qt5-declarative qt5-quickcontrols2 qt5-graphicaleffects
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    echo "Attempting to install required dependencies via apt-get..."
    apt-get update
    apt-get install -y sddm qml-module-qtquick-controls2 qml-module-qtgraphicaleffects qml-module-qtquick2
    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    echo "Attempting to install required dependencies via dnf..."
    dnf install -y sddm qt5-qtdeclarative qt5-qtquickcontrols2 qt5-qtgraphicaleffects
    return 0
  fi

  return 1
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "This installer must run as root."
  echo "Run: sudo ./scripts/install.sh"
  exit 1
fi

if [[ "$SKIP_DEP_CHECK" != "1" ]]; then
  mapfile -t missing_modules < <(detect_missing_modules)
  if [[ "${#missing_modules[@]}" -gt 0 ]]; then
    echo "Missing QML modules detected:"
    printf -- '- %s\n' "${missing_modules[@]}"

    if try_install_dependencies; then
      mapfile -t missing_modules < <(detect_missing_modules)
    fi
  fi

  if [[ "${#missing_modules[@]}" -gt 0 ]]; then
    cat <<MSG
Dependency check failed. Installation aborted before changing active SDDM theme.

Missing modules after install attempt:
$(printf -- '- %s\n' "${missing_modules[@]}")

On Arch Linux, install/verify:
- sddm
- qt5-graphicaleffects
- qt5-quickcontrols2
- qt5-declarative

Then run installer again, or bypass checks with:
SKIP_DEP_CHECK=1 sudo ./scripts/install.sh
MSG
    exit 1
  fi
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

if [[ "$ACTIVATE_THEME" == "1" ]]; then
  cat > "$SDDM_CONF_FILE" <<CFG
[Theme]
Current=$THEME_NAME
CFG
fi

if [[ "$ACTIVATE_THEME" == "1" ]]; then
  cat <<MSG
Installed theme: $THEME_NAME
Theme path: $TARGET_DIR
SDDM config: $SDDM_CONF_FILE

Next step:
- Restart SDDM or reboot to apply.
MSG
else
  cat <<MSG
Installed theme files only (not activated): $THEME_NAME
Theme path: $TARGET_DIR

To activate later:
echo -e "[Theme]\\nCurrent=$THEME_NAME" | sudo tee "$SDDM_CONF_FILE"
MSG
fi
