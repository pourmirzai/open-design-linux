# Open Design Linux

Automated, updatable Linux builds of [nexu-io/open-design](https://github.com/nexu-io/open-design).

A GitHub Actions workflow fetches the upstream source (latest release tag by
default, or any tag/branch you pick), builds the official packaged AppImage
with the upstream release-lane recipe (`tools-pack linux build --portable
--to appimage --containerized --require-vela-cli`), and publishes it on a
rolling [`linux-latest` release](https://github.com/pourmirzai/open-design-linux/releases/tag/linux-latest).

The Vela CLI is bundled in the AppImage (`--require-vela-cli` makes it a hard
requirement), so cloud login works out of the box — no system-wide `vela`
install needed.

## Install / update

```bash
curl -fsSL https://raw.githubusercontent.com/pourmirzai/open-design-linux/main/install.sh | bash
```

Or clone and run `./install.sh`. Re-running the script updates the app in
place; user data lives under the app's XDG config/data roots and is never
touched.

This installs:

- `~/.local/bin/Open-Design.linux.AppImage`
- `~/.local/share/applications/open-design-linux.desktop` (launcher entry,
  registers the `od://` scheme)
- `~/.local/share/icons/hicolor/512x512/apps/open-design-linux.png`

First launch takes ~10 seconds because the AppImage self-extracts to `/tmp`
(`--appimage-extract-and-run`; direct FUSE mounts make the daemon time out —
see upstream `tools/pack/README.md`).

## Uninstall

```bash
./install.sh uninstall
```

## Build triggers

- **Scheduled**: daily at 04:00 UTC — picks up the newest upstream release.
- **Manual**: *Actions → Build Open Design Linux → Run workflow*, with an
  optional upstream tag or branch in `upstream_ref` (empty = latest release
  tag).

Requirements for the local install: x86_64 Linux. `desktop-file-utils` and
`gtk-update-icon-cache` are optional (only refresh caches).
