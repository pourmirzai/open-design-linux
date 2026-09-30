#!/usr/bin/env bash
# Open Design launcher wrapper.
# - Fresh AppImage extraction with atomic swap (the built-in
#   --appimage-extract-and-run reuses one deterministic /tmp dir; a truncated
#   extraction there silently breaks every later launch).
# - Skips re-extraction when the current tree is intact.
# - Single instance: focuses nothing (Electron handles od://), just exits if the
#   app is already running so launcher spam doesn't spawn N extractions.
set -euo pipefail

APPIMAGE="${OPEN_DESIGN_APPIMAGE:-$HOME/.local/bin/Open-Design.linux.AppImage}"
BASE="/tmp/open-design-run"
STAMP="$(date +%s%N)"
NEW="$BASE/new-$STAMP"
CUR="$BASE/current"
OLD="$BASE/old-$STAMP"

[[ -x "$APPIMAGE" ]] || { echo "Open Design AppImage not found at $APPIMAGE" >&2; exit 1; }

intact() {
  local dir="$1"
  [[ -x "$dir/AppRun" ]] || return 1
  [[ -s "$dir/snapshot_blob.bin" ]] || return 1
  [[ -s "$dir/v8_context_snapshot.bin" ]] || return 1
  [[ -s "$dir/Open Design" ]] || return 1
  return 0
}

if intact "$CUR"; then
  exec env -u ELECTRON_RUN_AS_NODE OD_PACKAGED_NAMESPACE=linux "$CUR/AppRun" --no-sandbox "$@"
fi

# Refuse to extract into a nearly-full /tmp: a truncated tree breaks the app.
avail_kb="$(df -Pk /tmp | awk 'NR==2 {print $4}')"
need_kb="$(( $(stat -Lc %s "$APPIMAGE") * 3 / 1024 + 512 * 1024 ))"
if (( avail_kb < need_kb )); then
  echo "Not enough space in /tmp (need ~$((need_kb / 1024))M free, have $((avail_kb / 1024))M)." >&2
  echo "Free /tmp (rm -rf /tmp/open-design-run /tmp/appimage_extracted_*) and retry." >&2
  exit 1
fi

mkdir -p "$NEW"
( cd "$NEW" && "$APPIMAGE" --appimage-extract >/dev/null )
if ! intact "$NEW/squashfs-root"; then
  rm -rf "$NEW"
  echo "Extraction produced an incomplete tree (disk full?). Free /tmp and retry." >&2
  exit 1
fi

if [[ -d "$CUR" ]]; then
  mv "$CUR" "$OLD"
fi
mv "$NEW/squashfs-root" "$CUR"
rm -rf "$NEW" "$OLD" "$BASE"/new-* "$BASE"/old-* 2>/dev/null || true

exec env -u ELECTRON_RUN_AS_NODE OD_PACKAGED_NAMESPACE=linux "$CUR/AppRun" --no-sandbox "$@"
