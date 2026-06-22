# Changelog

All notable changes to Heliograph are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Version headers use
the `v`-prefixed tag name (e.g. `[v0.1.0]`) so `.github/scripts/build_release_notes.sh`
can pull the matching section straight into the GitHub release body — when you
cut a release, rename `[Unreleased]` to `[vX.Y.Z]` (and start a fresh empty
`[Unreleased]` above it) rather than leaving both.

## [Unreleased]

## [v0.1.0]

_Development started June 19, 2026, for the June Solstice Game Jam._

### Added

- Five-level light-relay platformer built for the June Solstice Game Jam 2026,
  entering the **Best Ode to Alan Turing** category.
- Core mechanic: standing in active sunlight charges the player and relays
  light forward through a station; shadow hides the player but drains charge.
- Substitution-cipher puzzles with a persistent glyph alphabet carried across
  levels; decoded keywords double as story keys (`SUN → ARC → LUX → RAY → SOLAR`).
- ACE (handheld guide) and the station's Oracle, telling the halting-problem
  story beat through in-game dialogue instead of cutscenes.
- Watcher sentries that start dormant/curious and turn hostile after the first
  level's fragment is completed.
- Headless GDScript test suite: rule-model unit tests plus level/chapter scene
  integration tests.
- Marketing landing page (`marketing/index.html`) and VitePress documentation
  site (`docs/`), both deployable to GitHub Pages.
- Cross-platform release pipeline: Linux, Windows, and macOS (Intel + Apple
  Silicon, ad-hoc signed) builds exported and attached to tagged GitHub
  releases automatically.
