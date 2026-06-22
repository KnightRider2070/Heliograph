# Editing Levels

All four levels are now plain Godot scenes you can edit visually in the 2D editor.
Levels 2–4 used to be generated in code; they are now baked into
`scenes/levels/level_02.tscn` … `level_04.tscn` and use the same base controller
as Level 1.

> Do **not** re-run `tools/generate_chapter_scenes.gd` after you start hand-editing
> — it overwrites the chapter scenes from the old layout data. It has done its job.

## Anatomy of a level scene

The root is a `Node2D` with `level_controller.gd`. Its direct children:

| Node | Purpose |
| --- | --- |
| `Background` | Ink fill + a dimmed backdrop image. Purely visual. |
| `RoomTitle` | The corner label (e.g. `02 / PRISM FOUNDRY`). |
| `Player` | The courier (instance of `player.tscn`), placed at the spawn point. |
| `CipherController` | Holds the level's `CipherDefinition` resource (the answer + glyph sequence). |
| `World` | Everything placeable lives here (see below). |
| `HUD` | The charge / exposure / lives / notebook overlay. |

Inspector fields on the root:

- **completion_scene** — the scene to load when the terminal is solved.
- **story_key** — which narration beat plays (`level1`..`level4`). See [Story](/story).

## The `World` pieces

Drag, duplicate, and delete these freely. The controller auto-wires anything in
the right group when the level loads, so new pieces just work.

| Piece | Notes |
| --- | --- |
| `Platform##` (`world_block`) | Floors and platforms. Set **size**; `position` is the centre. Floors at `y=342` give a top surface at `y=306`. |
| `Sunlight##` (`sunlight_zone`) | A light beam. Set **size**. **starts_active** off = dark until a relay lights it; its clue can't be read while dark. |
| `PuzzleMechanism` (the relay) | Set **target_zones** (NodePaths to the zones it lights), **terminal_path** (the terminal it powers), **latching**, and **requires_light** (must the player be standing in light to fire it). |
| `CipherClue##` | Set **glyph_id** and **glyph_mark**. Lives inside a sunlight zone; readable only while that zone is lit, and only by a deliberate **press E** while standing on it — walking over it no longer auto-reveals the letter. |
| `Terminal` | The exit puzzle. **starts_powered** off = dead until a relay powers it. |
| `Checkpoint` | Respawn point. Put it in shadow. |
| `Watcher` (sentry) | Dormant or hostile based on `GameState`; sweeps a vision cone. Set **reveals_glyph** so a *dormant* Watcher teaches the courier that glyph the first time you talk to it (press E in range) — a letter source for the build-up. Lost once the Watchers turn hostile. |
| `Patrol##` (`patrol_drone`) | Moving floor hazard — lethal on contact. Set **patrol_distance** and **patrol_speed**. |
| `MovingPlatform` (`moving_platform`) | A slab that ferries the player. Set **travel** (offset to the far end), **speed**, **pause_at_ends**. Carries the player (AnimatableBody2D). Dock it flush with floor edges so crossing is walking, not a precision jump. |
| `SunbeamPlatform` (`sunbeam_platform`) | Ground that is solid **only while a linked light is active**. Set **light_source** to a `Sunlight##` zone (a relay then raises it) or a `PulseProjector` (a flickering interval bridge). Distinct from `light_platform`, which keys off the player's own exposure. |
| `PulseProjector` (`pulse_projector`) | A "broken sun projector" light source that flips on/off on a timer. Set **on_time**/**off_time**/**jitter** (broken-ness). Point a `SunbeamPlatform`'s **light_source** at it for a timed bridge. Exposes the same `is_active()`/`active_changed` contract as a sun zone. |
| `DeathZone` | A wide kill-plane below the floor. Leave it; it catches pits. |

## Rules of thumb

- **The camera auto-fits the level width** — extend the floor to the right and the
  camera follows to the new exit. No manual camera limits needed.
- **Keep the floor continuous** unless you deliberately want a lethal pit; the
  death zone spans the whole level, so any gap in the floor kills.
- **A platform's collision foot is at its node origin.** Place world blocks and
  the relay at the surface they sit on (floor top `y=306`), not floating above it.
- **Player height is ~38px.** A platform whose vertical span overlaps roughly
  `y=268..306` at the player's lane blocks walking — fine as a "jump onto" ledge,
  but never stack two so close that the player can't stand between them.
- **Clue zones gate progress.** A clue can only be collected while its sunlight
  zone is active, so make sure a relay (or `starts_active`) lights it.

## Wiring a light-relay chain

1. Give the relay's `target_zones` the dark zones it should light.
2. Make those zones `starts_active = false`.
3. Point the *last* relay's `terminal_path` at the `Terminal`, and set the
   terminal `starts_powered = false`.
4. If you want the "carry the light" feel, set `requires_light = true` and place
   the relay inside an already-lit zone.

## Cipher-deduction mechanics

The puzzle is no longer "collect three glyphs, read the word." Letters are
**built up** from mixed sources and **remembered across levels** (the
`GlyphCodex` autoload), so each level hands out very little and leans on what the
player already carries. Press **C** in any level to open the codex journal.

**Letter sources (the build-up).** A glyph's meaning can come from:
1. a **clue plate** (stand on it in the light and press **E** to read — kept
   sparingly, ~1 per level; walking over it does nothing);
2. **talking to a dormant Watcher** (set `reveals_glyph`) — only in early levels,
   before the Watchers turn hostile;
3. **recall** — a glyph already in the codex from an earlier level (drawn smaller
   in the terminal, tagged `REMEMBERED`);
4. a **guess** — no clue at all; the player deduces it from the word, the
   `hint_text` line, and the letters they already know.

The shipped ramp: L1 SUN = S (clue) · U (Watcher) · N (guess); L2 ARC = A (clue) ·
R, C (guess); L3 LUX = L (clue) · U (recall) · X (guess); L4 RAY = R, A (recall) ·
Y (guess); L5 SOLAR = S, L, A, R (recall) · O (guess). Because letters carry
forward, **levels are meant to be played in order** — a later level loaded cold
has little to work from.

- **Persistent alphabet.** Every glyph means one letter for the whole game,
  defined in [`glyph_library.gd`](https://github.com/KnightRider2070/heliograph/blob/main/scripts/puzzles/glyph_library.gd) `CATALOG`.
  A level's cipher `mappings` must match it, or the codex becomes inconsistent.
- **Missing mapping.** To make the player *deduce* a glyph, simply place **no
  clue node** for it. The mapping still lives in the cipher's `mappings` (so the
  answer validates and the deduced glyph is committed to the codex on solve). The
  terminal shows that glyph in the encoded word as un-decoded gold; the player
  infers it from the word, the hint, and remembered glyphs. *(Guessed glyphs: N in
  L1, R+C in L2, X in L3, Y in L4, O in L5.)*
- **Decoy glyph.** Add the glyph to the cipher's `decoy_glyphs` (and give it a
  letter in `mappings`) and place a normal clue for it. It is collectible and
  recorded in the codex, but the terminal flags it **NOT IN SIGNAL** so collecting
  stops being automatic. *(L1 and L3 use `double_wave`; L5 uses `prism`.)*
- **Riddle / hint / ordering.** The `CipherDefinition` resource also carries
  `riddle` (solve-then-encode; hides the encoded word), `hint_text` (a relational
  clue line), and `ordering_note` (display telegraph). These are authored on the
  `.tres` and rendered by the terminal.

On solve, every glyph in the answer sequence — including a deduced/omitted one —
is written to the codex, so it is *remembered* in later levels (shown with a
**REMEMBERED** tag in the terminal key).

## The 10-level remix roadmap

Levels 1–5 ship today; 6–10 are the planned continuation on the same persistent
alphabet. Difficulty climbs by *layering* mechanics, never by adding arbitrary
symbols.

| # | Word | Letter sources | Platform toy |
| --- | --- | --- | --- |
| 1 First Signal | SUN | S clue · U from Watcher · N guess · decoy | moving platform |
| 2 Prism Foundry | ARC | A clue · R, C guess | relay sun-gated platform |
| 3 Lunar Archive | LUX | L clue · U recall · X guess · decoy | projector interval bridge |
| 4 Crown of Dawn | RAY | R, A recall · Y guess | moving ferry + sun-gated landing |
| 5 Solar Yard | SOLAR | S, L, A, R recall · O guess · decoy | all three toys |
| 6–10 (planned) | ORBIT, LUMEN, EMBER… | repeated-unknown glyph, ordering rules, riddle-to-encode, day/night rule flips, a combined finale | new combinations |

Deferred systems (ordering *validation*, contradiction feedback, codex
normal/hard gating modes) are designed to slot into this engine without rework.

## Regenerating from scratch

If you ever want to rebuild the chapter scenes from the layout data (discarding
hand edits), the source layouts live in `chapter_level_controller.gd` and the
generator is:

```bash
godot --headless --path . --script res://tools/generate_chapter_scenes.gd
```

Remember to strip the four `to="Player/Visual"` `[connection]` lines it bakes in.
