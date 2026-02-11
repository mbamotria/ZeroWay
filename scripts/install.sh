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
STRICT_DEP_CHECK="${STRICT_DEP_CHECK:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$THEME_DIR/$THEME_NAME"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
FONT_SOURCE_DIR="$REPO_ROOT/fonts"
SYSTEM_FONT_DIR="${SYSTEM_FONT_DIR:-/usr/local/share/fonts/ForZeroWay}"
INSTALL_SYSTEM_FONTS="${INSTALL_SYSTEM_FONTS:-1}"

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

has_any_qml_module_path() {
  local root
  local module_path
  while IFS= read -r root; do
    for module_path in "$@"; do
      if [[ -d "$root/$module_path" ]]; then
        return 0
      fi
    done
  done < <(collect_qml_roots)
  return 1
}

has_qml_module() {
  local module_name="$1"
  shift
  if has_any_qml_module_path "$@"; then
    return 0
  fi
  if [[ "$DEBUG_DEP_CHECK" == "1" ]]; then
    echo "Missing QML module: $module_name"
  fi
  return 1
}

detect_missing_modules() {
  local missing=()
  if ! has_qml_module "QtQuick" "QtQuick" "QtQuick.2"; then
    missing+=("QtQuick")
  fi
  if ! has_qml_module "QtQuick.Controls" "QtQuick/Controls" "QtQuick/Controls.2"; then
    missing+=("QtQuick.Controls")
  fi
  if ! has_qml_module "QtGraphicalEffects" "QtGraphicalEffects"; then
    missing+=("QtGraphicalEffects")
  fi
  if ! has_qml_module "SddmComponents" "SddmComponents"; then
    missing+=("SddmComponents")
  fi
  if [[ "${#missing[@]}" -gt 0 ]]; then
    printf '%s\n' "${missing[@]}"
  fi
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

collect_theme_fonts() {
  if [[ ! -d "$FONT_SOURCE_DIR" ]]; then
    return 0
  fi

  find "$FONT_SOURCE_DIR" -type f \
    \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \)
}

install_fonts_systemwide() {
  if [[ "$INSTALL_SYSTEM_FONTS" != "1" ]]; then
    return 0
  fi

  if [[ ! -d "$FONT_SOURCE_DIR" ]]; then
    echo "No fonts directory found at: $FONT_SOURCE_DIR"
    return 0
  fi

  mapfile -t font_files < <(collect_theme_fonts)
  if [[ "${#font_files[@]}" -eq 0 ]]; then
    echo "No installable font files found in: $FONT_SOURCE_DIR"
    return 0
  fi

  install -d -m 755 "$SYSTEM_FONT_DIR"

  local src rel dest_dir dest_file
  local files_installed=0

  for src in "${font_files[@]}"; do
    rel="${src#$FONT_SOURCE_DIR/}"
    dest_dir="$SYSTEM_FONT_DIR/$(dirname "$rel")"
    dest_file="$SYSTEM_FONT_DIR/$rel"
    install -d -m 755 "$dest_dir"
    install -m 644 "$src" "$dest_file"
    files_installed=$((files_installed + 1))
  done

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$SYSTEM_FONT_DIR" >/dev/null 2>&1 || true
  fi

  echo "Installed $files_installed font file(s) to: $SYSTEM_FONT_DIR"
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "This installer must run as root."
  echo "Run: sudo ./scripts/install.sh"
  exit 1
fi

if [[ "$SKIP_DEP_CHECK" != "1" ]]; then
  mapfile -t missing_modules < <(detect_missing_modules)
  filtered_missing=()
  for m in "${missing_modules[@]}"; do
    if [[ -n "$m" ]]; then
      filtered_missing+=("$m")
    fi
  done
  missing_modules=("${filtered_missing[@]}")
  if [[ "${#missing_modules[@]}" -gt 0 ]]; then
    echo "Missing QML modules detected:"
    printf -- '- %s\n' "${missing_modules[@]}"

    attempted_auto_install=0
    if try_install_dependencies; then
      attempted_auto_install=1
      mapfile -t missing_modules < <(detect_missing_modules)
      filtered_missing=()
      for m in "${missing_modules[@]}"; do
        if [[ -n "$m" ]]; then
          filtered_missing+=("$m")
        fi
      done
      missing_modules=("${filtered_missing[@]}")
    fi

    if [[ "${#missing_modules[@]}" -gt 0 ]]; then
      if [[ "$STRICT_DEP_CHECK" == "1" ]]; then
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

      cat <<MSG
Warning: some QML modules still appear missing:
$(printf -- '- %s\n' "${missing_modules[@]}")

Continuing installation because STRICT_DEP_CHECK=0.
Set STRICT_DEP_CHECK=1 to enforce hard-fail behavior.
MSG
    fi
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

install_fonts_systemwide

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
