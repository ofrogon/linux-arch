#!/bin/bash
set -euo pipefail

# --- helpers ---
die() {
  echo "Error: $*" >&2
  exit 1
}

usage() {
  cat >&2 <<'USAGE'
Create a PWA .desktop launcher (CLI or interactive).

Options:
  -n, --name NAME            Nom de l'application (ex: "Notion")
  -u, --url URL              URL à lancer (doit commencer par http:// ou https://)
  -i, --icon PATH_OR_URL     Icône (fichier local ou URL)
  -b, --browser CMD          Binaire du navigateur (ex: google-chrome, brave, firefox)
      --wmclass WMCLASS      Valeur StartupWMClass (sinon générée depuis le nom)
      --categories CATS      Catégories .desktop (ex: "Internet;Productivity;")
      --no-prompt            Ne pose aucune question (échoue si requis manquant)
  -h, --help                 Afficher cette aide

Exemples:
  pwa-desktop.sh -n "Notion" -u https://www.notion.so/ -i ~/pics/notion.png
  pwa-desktop.sh --name Slack --url https://app.slack.com --icon https://.../slack.png --browser brave

USAGE
}

slugify() {
  # lower-case, replace non alnum with '-', trim '-' ends
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

have() { command -v "$1" >/dev/null 2>&1; }

detect_browser() {
  # Prefer Chromium-based for --app=
  local c
  for c in chromium chromium-browser google-chrome-stable google-chrome chrome brave-browser brave microsoft-edge-stable microsoft-edge edge vivaldi; do
    if have "$c"; then
      echo "$c"
      return 0
    fi
  done
  if have firefox; then
    echo "firefox"
    return 0
  fi
  return 1
}

ensure_dirs() {
  mkdir -p "$HOME/.local/share/applications" "$HOME/.local/share/applications/icons"
}

download_icon() {
  local src="$1" dst="$2"
  # Accept URL or local file path
  if [[ "$src" =~ ^https?:// ]]; then
    if have curl; then
      curl -fL "$src" -o "$dst"
    elif have wget; then
      wget -O "$dst" "$src"
    else
      die "Neither curl nor wget found to download icon."
    fi
  else
    # local file path (supports ~)
    src="${src/#\~/$HOME}"
    [[ -f "$src" ]] || die "Icon path does not exist: $src"
    cp "$src" "$dst"
  fi
}

build_exec() {
  local browser="$1" url="$2" wmclass="$3"
  case "$browser" in
  *firefox*)
    # Firefox n'a pas --app ; --kiosk est l'approche la plus proche.
    printf '%s --kiosk "%s"' "$browser" "$url"
    ;;
  *)
    # Chromium/Chrome/Brave/Edge/Vivaldi
    printf '%s --app="%s" --class="%s"' "$browser" "$url" "$wmclass"
    ;;
  esac
}

update_desktop_db_if_possible() {
  if have update-desktop-database; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  fi
}

prompt_if_needed() {
  local varname="$1" prompt="$2" validator="${3:-}"
  if [[ "${NO_PROMPT:-0}" -eq 1 ]]; then
    # no prompt mode: do nothing here
    return 0
  fi
  local cur="${!varname:-}"
  if [[ -z "$cur" ]]; then
    read -rp "$prompt" cur
    printf -v "$varname" '%s' "$cur"
  fi
  if [[ -n "$validator" ]]; then
    eval "$validator" || die "Invalid value for ${varname}"
  fi
}

# --- defaults ---
APP_NAME="${APP_NAME:-}"
APP_URL="${APP_URL:-}"
ICON_SRC="${ICON_SRC:-}"
BROWSER_CMD="${BROWSER_CMD:-}"
WMCLASS="${WMCLASS:-}"
CATEGORIES="${CATEGORIES:-Utility;}"
NO_PROMPT=0

# --- parse args ---
if [[ $# -eq 0 ]]; then
  # interactive fallback later
  :
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -n | --name)
      APP_NAME="${2-}"
      shift 2
      ;;
    -u | --url)
      APP_URL="${2-}"
      shift 2
      ;;
    -i | --icon)
      ICON_SRC="${2-}"
      shift 2
      ;;
    -b | --browser)
      BROWSER_CMD="${2-}"
      shift 2
      ;;
    --wmclass)
      WMCLASS="${2-}"
      shift 2
      ;;
    --categories)
      CATEGORIES="${2-}"
      shift 2
      ;;
    --no-prompt)
      NO_PROMPT=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      die "Unknown option: $1"
      ;;
    esac
  done
fi

# --- interactive fallback (unless --no-prompt) ---
prompt_if_needed APP_NAME "PWA Name (e.g., Notion): " '[ -n "$APP_NAME" ]'
prompt_if_needed APP_URL "PWA URL to launch (e.g., https://www.notion.so/): " '[[ "$APP_URL" =~ ^https?:// ]]'
prompt_if_needed ICON_SRC "Icon URL or local path (PNG recommended): " '[ -n "$ICON_SRC" ]'

if [[ -z "${BROWSER_CMD:-}" ]]; then
  if BROWSER_CMD="$(detect_browser || true)"; then :; else
    if [[ "${NO_PROMPT:-0}" -eq 1 ]]; then
      die "No supported browser detected and --no-prompt is set."
    fi
    read -rp "Enter a browser command to use (must accept --app or --kiosk), or press Enter to abort: " BROWSER_CMD
    [[ -n "${BROWSER_CMD:-}" ]] || die "No browser available."
  fi
fi

# --- build paths & files ---
ensure_dirs

SLUG="$(slugify "$APP_NAME")"
DESKTOP_PATH="$HOME/.local/share/applications/${SLUG}.desktop"

# Decide icon file extension from source; default to .png
ext="png"
if [[ "$ICON_SRC" =~ \.svg($|\?) ]]; then
  ext="svg"
elif [[ "$ICON_SRC" =~ \.ico($|\? ) ]]; then
  ext="ico"
elif [[ "$ICON_SRC" =~ \.jpe?g($|\?) ]]; then
  ext="jpg"
fi

ICON_PATH="$HOME/.local/share/applications/icons/${SLUG}.${ext}"

echo "Fetching icon..."
download_icon "$ICON_SRC" "$ICON_PATH"

# StartupWMClass
if [[ -z "${WMCLASS:-}" ]]; then
  WMCLASS="$(echo "$SLUG" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
fi

EXEC_LINE="$(build_exec "$BROWSER_CMD" "$APP_URL" "$WMCLASS")"

# --- write .desktop ---
cat >"$DESKTOP_PATH" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=Launch $APP_NAME as a PWA
Exec=$EXEC_LINE
Icon=$ICON_PATH
Terminal=false
Categories=$CATEGORIES
StartupWMClass=$WMCLASS
EOF

chmod +x "$DESKTOP_PATH"
update_desktop_db_if_possible

echo "Created: $DESKTOP_PATH"
echo "Icon:    $ICON_PATH"
echo "If it doesn't appear in your launcher immediately, log out/in or run: update-desktop-database ~/.local/share/applications"
