# Technical Architecture

## Goals

- Deliver the complete light/shadow loop within a two-day prototype scope.
- Keep game rules testable without building a framework around a small game.
- Compose levels from reusable Godot scenes.
- Make exposure changes explicit so platforms, sentries, clues, and UI do not poll the player every frame.

## Runtime and constraints

| Decision | Choice |
| --- | --- |
| Engine | Godot 4.7, matching `project.godot` |
| Language | Typed GDScript |
| Game model | 2D side-view platformer |
| Physics | `CharacterBody2D`, `StaticBody2D`, and `Area2D` |
| Internal view | `640x360` with a `36px` construction grid from `18px` art at integer `2x` scale |
| Light model | Authored `SunlightZone` areas, not rendered-light sampling |
| Level data | Packed scenes plus small custom Resources where shared data is useful |
| Persistence | None for the MVP; checkpoint state is level-local |

## Architecture principles

1. **Scene composition first.** Player, zone, platform, checkpoint, sentry, clue, terminal, and HUD are reusable scenes.
2. **One owner per state.** `ChargeModel` owns charge and exposure, `CharacterMotor2D` owns motion state, `PlayerCore` coordinates lifecycle, the puzzle controller owns discovered mappings, and each level owns its checkpoint lifecycle.
3. **Signals for state changes.** Consumers react to charge, exposure, death, and puzzle progress rather than reaching into unrelated nodes every frame.
4. **No speculative global systems.** Scene changes can remain direct until cross-level state is genuinely required.
5. **Data over duplicated logic.** Cipher answers and mappings live in a per-level resource consumed by clues and terminals.

Detailed movement calculations and code skeletons are specified in [Physics and Engine Systems](/physics-and-engine). Visual nodes follow [Theme and Art Direction](/theme-and-art-direction) but never own gameplay truth.

## System map

```text
InputMap -> PlayerBodyAdapter ----> PlayerCore
CharacterBody2D collision --------> CharacterMotor2D
SunlightZone -> PlayerBodyAdapter -> ChargeModel
PlayerCore -- charge_changed -----> HUD
PlayerCore -- exposure_changed ---> LightPlatform, Sentry, CipherClue, HUD
Checkpoint -> PlayerBodyAdapter --> PlayerCore
CipherClue -- discover -----------> CipherController
CipherTerminal -- submit ---------> CipherController
CipherController -- progress -----> HUD
CipherController -- solved -------> LevelController -- scene change
```

Gameplay scripts own values and transitions. `Sprite2D`, `AnimationPlayer`, particles, audio, and shaders subscribe to those transitions and provide feedback without deciding the result.

## Project layout

```text
res://
  scenes/
    screens/
      title_screen.tscn
      win_screen.tscn
    levels/
      level_01.tscn
      level_02.tscn
      level_03.tscn
    player/
      player.tscn
    world/
      sunlight_zone.tscn
      light_platform.tscn
      checkpoint.tscn
      sentry.tscn
    puzzles/
      cipher_clue.tscn
      cipher_terminal.tscn
    ui/
      hud.tscn
  scripts/
    core/
      config/
        player_tuning.gd
      physics/
        motion_input.gd
        character_motor_2d.gd
      gameplay/
        charge_model.gd
        player_core.gd
    adapters/
      player_body_adapter.gd
      sunlight_zone.gd
      checkpoint.gd
    world/
      light_platform.gd
      sentry.gd
    puzzles/
      cipher_controller.gd
      cipher_clue.gd
      cipher_terminal.gd
    ui/
      hud.gd
    levels/
      level_controller.gd
      level_exit.gd
  tests/
    unit/
    integration/
  resources/
    cipher_definition.gd
    ciphers/
      level_01.tres
      level_02.tres
      level_03.tres
  assets/
    vendor/
      kenney/
        atlases/
        prompts/
        fonts/
        licenses/
    game/
      characters/
      glyphs/
      ui/
      fx/
      audio/
```

Do not create empty directories in advance. Add each path with the first asset or script that needs it.

The curated files and semantic targets are defined in [Asset Reuse Plan](/asset-plan). Runtime resources must never reference the workstation-local Downloads path.

## Scene contracts

### Player

The player scene is a composition root, not the gameplay aggregate. A thin `CharacterBody2D` adapter translates `InputMap` state and collision facts into calls on `PlayerCore`, applies the returned velocity, and performs requested teleports. `PlayerCore` composes `CharacterMotor2D` and `ChargeModel`; presentation nodes only observe signals.

This keeps rule tests independent from the physics server while retaining Godot's `move_and_slide()` as the collision authority. The adapter must not duplicate timers, charge, exposure, or respawn rules.

Required public API:

```gdscript
signal charge_changed(current: float, maximum: float)
signal exposure_changed(in_sunlight: bool)
signal died
signal respawn_requested(spawn_position: Vector2)

func in_sunlight() -> bool
func enter_sunlight() -> void
func exit_sunlight() -> void
func set_spawn_point(position: Vector2) -> void
```

The core contract is implemented and unit-tested before the body adapter or player scene is introduced.

### SunlightZone

`Area2D` owns only overlap detection. On body enter/exit, it calls the player's exposure methods. The player keeps a counter rather than a boolean so overlapping zones do not produce false shadow transitions.

### LightPlatform and Sentry

Both consume `Player.exposure_changed`:

- `LightPlatform` toggles visibility and collision from the exposure state.
- `Sentry` may target the player only while exposure is true and must drop the target when it becomes false.

Neither system changes player charge.

### Checkpoint

`Checkpoint` is an `Area2D` that calls `Player.set_spawn_point(global_position)` once per activation and provides visible feedback. It does not perform respawn itself.

### CipherController

One level-local node owns:

- the `CipherDefinition` resource;
- the set of discovered mapping IDs;
- answer validation;
- `mapping_discovered` and `puzzle_solved` signals.

Clues report discovery to this controller. The terminal reads progress and submits answers through it. This prevents individual clues and UI nodes from duplicating puzzle state.

### HUD

The HUD observes signals and sends no gameplay mutations. It displays charge, discovered mappings, terminal feedback, and optional exposure feedback.

### LevelController

Each level has one `LevelController` that wires the player, HUD, cipher controller, and completion target. It connects all nodes in the `light_reactive` group to `Player.exposure_changed`, applies the initial exposure state, and owns the transition to the next packed scene.

It does not own player charge, sentry timers, or clue state. Those remain with their domain nodes.

## State flow

### Exposure

1. `SunlightZone.body_entered` calls `Player.enter_sunlight()`.
2. The player increments its overlap count.
3. A `0 -> 1` transition emits `exposure_changed(true)`.
4. Platforms, sentries, clues, and HUD update once.
5. The inverse occurs only on the `1 -> 0` transition.

### Charge and dash

1. The player integrates gravity, jump, and horizontal movement in `_physics_process`.
2. A valid dash subtracts `dash_cost`, emits `charge_changed`, and locks horizontal dash velocity for `dash_time`.
3. After movement, charge fills or drains from the current exposure state.
4. Reaching zero in shadow enters the respawn flow.

Only emit `charge_changed` when the value actually changes. This avoids unnecessary HUD work and makes the signal meaningful.

### Respawn

Respawn is a single guarded operation:

1. Emit `died` for effects and telemetry.
2. Move to the active checkpoint.
3. Clear velocity, dash state, timers, and exposure overlap state.
4. Restore full charge.
5. Emit the resulting exposure and charge state once.

Clearing the exposure counter is important when a hazard kills the player in sunlight; teleporting can otherwise leave a stale overlap count.

### Puzzle completion

1. A lit clue reports its mapping ID to `CipherController`.
2. The controller records it idempotently and emits progress.
3. The terminal submits a normalized answer.
4. A correct answer emits `puzzle_solved` and enables the level exit or changes scene.

While the terminal UI is open, the scene tree is paused. The terminal UI uses `PROCESS_MODE_WHEN_PAUSED`; closing or completing the terminal must always restore the previous pause state.

## Collision policy

| Layer | Name | Used by |
| ---: | --- | --- |
| 1 | World | Ground and active light platforms |
| 2 | Player | Player body |
| 3 | Hazard | Sentry hitboxes or projectiles |
| 4 | Sensor | Sunlight, checkpoints, clues, and terminals |

Sensors monitor the player layer. The player collides with world and hazard layers. Keep detection areas separate from damaging hitboxes even if the first sentry scene contains both.

## Error and edge-case policy

- Clamp charge to `[0, max_charge]` and exposure count to `>= 0`.
- Ignore repeated checkpoint and mapping activation.
- Prevent a second death while respawn is already running.
- Disable a light platform collision shape with `set_deferred` during physics callbacks.
- Normalize terminal input by trimming whitespace and comparing a single documented case.
- Bind signal consumers in `_ready` and fail visibly when required exported references are missing.

## Verification strategy

The scene-independent rules run through the repository's headless test harness:

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

After these tests pass, add a repeatable integration test room containing two overlapping light zones, a platform, checkpoint, sentry, clue, terminal, charge HUD, and a shadow stretch. Integration tests own physics-server and signal-wiring behavior; unit tests continue to own rule calculations and state transitions.

Required checks:

- Crossing overlapping light zones emits only one enter and one final exit transition.
- Full charge survives `12.5s` in uninterrupted shadow with default tuning.
- A dash spends exactly `25` charge and cannot start below its cost.
- Zero charge respawns at the latest checkpoint with full charge.
- Death in sunlight does not leave the player marked as lit at a shadow checkpoint.
- Platforms cannot strand the player because collision changed mid-physics callback.
- Sentries immediately lose eligibility when the player enters shadow.
- Re-reading a cipher clue does not duplicate progress.
- Wrong answers preserve mappings; the correct answer completes the level once.

Run Godot's headless parse check after scenes and scripts exist:

```bash
godot --headless --path . --editor --quit
```
