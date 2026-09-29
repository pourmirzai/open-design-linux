#!/usr/bin/env bash
# Open Design launcher wrapper.
# The AppImage's built-in --appimage-extract-and-run always extracts to the same
# deterministic /tmp/appimage_extracted_<hash> directory. If a run is killed
# mid-extraction (or two launches race), the corrupt tree is silently reused on
# the next launch and the web sidecar dies on missing chunks (blank window).
# This wrapper extracts to a fresh directory and atomically swaps it in, then
# runs the inner AppRun directly. Keeps exactly one previous extraction as
# fallback and prunes stale ones.
set -euo pipefail

APPIMAGE="${OPEN_DESIGN_APPIMAGE:-$HOME/.local/bin/Open-Design.linux.AppImage}"
BASE="/tmp/open-design-run"
STAMP="$(date +%s%N)"
NEW="$BASE/new-$STAMP"
CUR="$BASE/current"
OLD="$BASE/old-$STAMP"

[[ -x "$APPIMAGE" ]] || { echo "Open Design AppImage not found at $APPIMAGE" >&2; exit 1; }

mkdir -p "$NEW"
( cd "$NEW" && "$APPIMAGE" --appimage-extract >/dev/null )

if [[ -d "$CUR" ]]; then
  mv "$CUR" "$OLD"
fi
mv "$NEW/squashfs-root" "$CUR"
rm -rf "$NEW" "$OLD" "$BASE"/new-* "$BASE"/old-* 2>/dev/null || true

exec env -u ELECTRON_RUN_AS_NODE OD_PACKAGED_NAMESPACE=linux "$CUR/AppRun" "$@"
