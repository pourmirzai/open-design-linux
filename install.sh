#!/usr/bin/env bash
# Install/update the Open Design Linux AppImage built by this repository's
# GitHub Actions workflow (rolling release tag "linux-latest").
#
# Usage:
#   install.sh            install or update to the latest published build
#   install.sh uninstall  remove the installed app
#
# Layout (matches the upstream `tools-pack linux install` namespace "linux"):
#   ~/.local/bin/Open-Design.linux.AppImage
#   ~/.local/share/applications/open-design-linux.desktop
#   ~/.local/share/icons/hicolor/512x512/apps/open-design-linux.png
set -Eeuo pipefail

REPO="${OPEN_DESIGN_LINUX_REPO:-pourmirzai/open-design-linux}"
RELEASE_TAG="linux-latest"
NAMESPACE="linux"
APPIMAGE_NAME="Open-Design.${NAMESPACE}.AppImage"
ASSET_APPIMAGE="Open-Design-linux-x64.AppImage"
ASSET_ICON="open-design-icon.png"

BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"
APPIMAGE_PATH="${BIN_DIR}/${APPIMAGE_NAME}"
DESKTOP_PATH="${DESKTOP_DIR}/open-design-${NAMESPACE}.desktop"
ICON_PATH="${ICON_DIR}/open-design-${NAMESPACE}.png"

info() { printf '\033[1;34m[OpenDesign]\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m[OpenDesign]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[OpenDesign]\033[0m %s\n' "$*" >&2; exit 1; }

require() { command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"; }

uninstall() {
  local removed=0
  for f in "$APPIMAGE_PATH" "$DESKTOP_PATH" "$ICON_PATH"; do
    if [[ -e "$f" ]]; then
      rm -f -- "$f"
      info "Removed $f"
      removed=1
    fi
  done
  ((removed)) || info "Nothing installed."
  command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
  ok "Uninstall complete."
}

[[ "${1:-install}" != "uninstall" ]] || { uninstall; exit 0; }
[[ $# -le 0 || "$1" == "install" ]] || fail "Unknown command: $1 (use: install|uninstall)"

require curl
require install

[[ "$(uname -m)" == "x86_64" ]] || fail "This build is x86_64 only (found: $(uname -m))."

base_url="https://github.com/${REPO}/releases/${RELEASE_TAG}/download"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

info "Downloading latest build from github.com/${REPO} (${RELEASE_TAG})..."
curl -fL --retry 3 --retry-delay 2 -o "${work_dir}/${ASSET_APPIMAGE}" \
  "${base_url}/${ASSET_APPIMAGE}" || fail "Download failed. Has the first Actions build finished?"
curl -fL --retry 3 --retry-delay 2 -o "${work_dir}/${ASSET_ICON}" \
  "${base_url}/${ASSET_ICON}" || fail "Icon download failed."

chmod +x "${work_dir}/${ASSET_APPIMAGE}"

mkdir -p "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR"

info "Installing AppImage to ${APPIMAGE_PATH}..."
mv -f "${work_dir}/${ASSET_APPIMAGE}" "$APPIMAGE_PATH"

info "Installing icon and menu entry..."
mv -f "${work_dir}/${ASSET_ICON}" "$ICON_PATH"

cat > "${DESKTOP_PATH}.tmp" <<EOF
[Desktop Entry]
Type=Application
Name=Open Design
GenericName=Open Design
Comment=Open Design packaged build
Exec=env -u ELECTRON_RUN_AS_NODE OD_PACKAGED_NAMESPACE=${NAMESPACE} ${APPIMAGE_PATH} --appimage-extract-and-run %U
Icon=open-design-${NAMESPACE}
Categories=Development;Utility;
StartupWMClass=Open Design
StartupNotify=true
Terminal=false
MimeType=x-scheme-handler/od;
EOF
mv -f "${DESKTOP_PATH}.tmp" "$DESKTOP_PATH"

# Best-effort desktop integration hooks (absent tools are harmless).
command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && \
  gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
command -v xdg-mime >/dev/null 2>&1 && \
  xdg-mime default "open-design-${NAMESPACE}.desktop" x-scheme-handler/od >/dev/null 2>&1 || true

ok "Installed. 'Open Design' now appears in your app launcher."
ok "Re-run this script any time to update; your data is not touched."
ok "First launch can take ~10s (AppImage self-extracts to /tmp)."
