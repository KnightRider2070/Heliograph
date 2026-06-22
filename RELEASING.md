# Releasing Heliograph

This repo builds and publishes itself via two GitHub Actions workflows:

- [`.github/workflows/release.yml`](.github/workflows/release.yml) — on a
  `vX.Y.Z` tag push, exports Linux, Windows, and macOS (universal) builds,
  generates release notes, and publishes a GitHub release with all three
  zips attached.
- [`.github/workflows/pages.yml`](.github/workflows/pages.yml) — builds the
  VitePress docs and the marketing landing page and deploys both to GitHub
  Pages, on every push to `main` that touches `docs/` or `marketing/`, and
  again whenever a release is published.

Neither workflow exists on GitHub until this repo is actually pushed there.

## One-time setup

1. Add the remote and push the current history:
   ```
   git remote add origin git@github.com:KnightRider2070/heliograph.git
   git push -u origin main
   ```
2. In the GitHub repo settings, go to **Settings → Pages** and set **Source**
   to **GitHub Actions**. This can't be done from a workflow file — it's a
   one-time manual flip.
3. Nothing else needs a secret: both workflows only use the default
   `GITHUB_TOKEN`, which already has the required permissions declared in the
   workflow files.

## Cutting a release

1. Move the `## [Unreleased]` section in [`CHANGELOG.md`](CHANGELOG.md) under
   a new `## [vX.Y.Z]` heading (matching the tag you're about to push exactly,
   including the `v`), and leave a fresh empty `## [Unreleased]` above it.
   The release workflow pulls this section verbatim into the GitHub release
   body, with the raw commit log appended underneath as a fallback/appendix.
2. Commit and push that to `main`.
3. Tag and push the tag:
   ```
   git tag v0.1.0
   git push origin v0.1.0
   ```
4. Watch the **Actions** tab. `release.yml` will export all three platform
   builds and publish them as a GitHub release at
   `https://github.com/KnightRider2070/heliograph/releases/tag/v0.1.0`.

You can also trigger `release.yml` manually from the Actions tab
(`workflow_dispatch`) against an existing tag if a run failed partway and you
want to retry without re-tagging.

## Known constraints

- **Godot version is pinned** in `release.yml` (`GODOT_VERSION`) and must
  match `config/features` in [`project.godot`](project.godot) (currently
  `4.7`). Bump both together if you upgrade the engine.
- **macOS build is ad-hoc signed, not notarized** (no paid Apple Developer
  account in this setup — `codesign/codesign=1`, Godot's built-in signer,
  which works cross-platform). It's a single universal binary covering Intel
  and Apple Silicon. Gatekeeper will still flag the app as being from an
  unidentified developer on first launch — players need to right-click the
  app and choose **Open**, or allow it via **System Settings → Privacy &
  Security**, once. If you ever reconfigure this preset from the Godot
  editor on a Mac with Xcode installed, it will likely default the codesign
  option back to **Xcode codesign**, which only works on a real macOS host —
  switch it back to **Built-in (ad-hoc only)** before committing, otherwise
  the CI export (which runs on `ubuntu-latest`) will fail.
- **`export_presets.cfg` paths are fixed** (`builds/linux/...`,
  `builds/windows/...`, `builds/macos/...`). If you rename or add presets,
  update the packaging step in `release.yml` to match.
