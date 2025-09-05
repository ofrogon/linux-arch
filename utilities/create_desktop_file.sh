#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---
die() { echo "Error: $*" >&2; exit 1; }

slugify() {
  # lower-case, replace non alnum with '-', trim '-' ends
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

have() { command -v "$1" >/dev/null 2>&1; }

detect_browser() {
  # Prefer Chromium-based for --app=
  for c in chromium chromium-browser google-chrome-stable google-chrome chrome brave-browser brave microsoft-edge-stable microsoft-edge edge vivaldi; do
    if have "$c"; then echo "$c"; return 0; fi
  done
  if have firefox; then echo "firefox"; return 0; fi
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
      # Firefox doesn't support --app; use kiosk as closest approximation.
      echo "$browser --kiosk \"$url\""
      ;;
    *)
      # Chromium/Chrome/Brave/Edge/Vivaldi
      echo "$browser --app=\"$url\" --class=\"$wmclass\""
      ;;
  esac
}

update_desktop_db_if_possible() {
  if have update-desktop-database; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  fi
}

# --- prompts ---
read -rp "PWA Name (e.g., Notion): " APP_NAME
[[ -n "${APP_NAME:-}" ]] || die "Name is required."

read -rp "PWA URL to launch (e.g., https://www.notion.so/): " APP_URL
[[ -n "${APP_URL:-}" ]] || die "URL is required."
if ! [[ "$APP_URL" =~ ^https?:// ]]; then
  die "URL must start with http:// or https://"
fi

read -rp "Icon URL or local path (PNG recommended): " ICON_SRC
[[ -n "${ICON_SRC:-}" ]] || die "Icon URL/path is required."

BROWSER_CMD="$(detect_browser || true)"
if [[ -z "${BROWSER_CMD:-}" ]]; then
  echo "No supported browser detected."
  read -rp "Enter a browser command to use (must accept --app or --kiosk), or press Enter to abort: " BROWSER_CMD
  [[ -n "${BROWSER_CMD:-}" ]] || die "No browser available."
fi

ensure_dirs

SLUG="$(slugify "$APP_NAME")"
DESKTOP_PATH="$HOME/.local/share/applications/${SLUG}.desktop"

# Decide icon file extension from source; default to .png
ext="png"
if [[ "$ICON_SRC" =~ \.svg($|\?) ]]; then ext="svg"; fi
if [[ "$ICON_SRC" =~ \.ico($|\?) ]]; then ext="ico"; fi
if [[ "$ICON_SRC" =~ \.jpg($|\?) || "$ICON_SRC" =~ \.jpeg($|\?) ]]; then ext="jpg"; fi
ICON_PATH="$HOME/.local/share/icons/applications/${SLUG}.${ext}"

echo "Fetching icon..."
download_icon "$ICON_SRC" "$ICON_PATH"

# Try to generate a WMCLASS that's stable
WMCLASS="$(echo "$SLUG" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"

EXEC_LINE="$(build_exec "$BROWSER_CMD" "$APP_URL" "$WMCLASS")"

# desktop entry
cat > "$DESKTOP_PATH" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=Launch $APP_NAME as a PWA
Exec=$EXEC_LINE
Icon=$ICON_PATH
Terminal=false
Categories=Utility;
StartupWMClass=$WMCLASS
EOF

chmod +x "$DESKTOP_PATH"
update_desktop_db_if_possible

echo "Created: $DESKTOP_PATH"
echo "Icon:    $ICON_PATH"
echo "If it doesn't appear in your launcher immediately, log out/in or run: update-desktop-database ~/.local/share/applications"
