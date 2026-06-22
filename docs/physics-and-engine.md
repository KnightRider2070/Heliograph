# Physics and Engine Systems

## Purpose

This document turns the game rules into measurable Godot behavior. It describes the required code and contracts; it is not a claim that these files already exist.

## Coordinate and timing model

| Setting           |                                         Value | Reason                                                   |
| ----------------- | --------------------------------------------: | -------------------------------------------------------- |
| Internal viewport |                                     `640x360` | Small, readable jam canvas with 16:9 output              |
| Construction grid |                                        `36px` | Kenney `18px` world tiles rendered at integer `2x` scale |
| Physics tick      |                                        `60Hz` | Stable platforming and timer behavior                    |
| World scale       |                            `1 unit = 1 pixel` | Matches Godot 2D defaults                                |
| Positive axis     |                         `+x` right, `+y` down | Godot canvas convention                                  |
| Camera            | Side view, horizontal lead, bounded per level | Keeps upcoming light and sightlines visible              |

Add these settings to `project.godot` when the first scene is created:

```ini
[display]
window/size/viewport_width=640
window/size/viewport_height=360
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[physics]
common/physics_ticks_per_second=60
```

The existing project already declares `canvas_items` and `expand`. Forward Plus is acceptable for desktop. Switch to Compatibility only if the jam requires a web export or older GPU support; the game design does not depend on a renderer feature.

## Baseline movement math

The supplied controller uses:

```text
run speed       = 220 px/s
jump velocity   = -430 px/s
gravity         = 1100 px/s^2
dash speed      = 600 px/s
dash duration   = 0.15 s
```

Ignoring collision, input changes, and discrete tick rounding:

| Measure                               | Calculation          |                               Result |
| ------------------------------------- | -------------------- | -----------------------------------: |
| Time to jump apex                     | `430 / 1100`         |                              `0.39s` |
| Jump height                           | `430^2 / (2 * 1100)` |              `84px`, or `2.33` tiles |
| Return to takeoff height              | `2 * 430 / 1100`     |                              `0.78s` |
| Flat running-jump travel              | `220 * 0.78`         | `172px`, or `4.78` tiles theoretical |
| Dash travel                           | `600 * 0.15`         |              `90px`, or `2.50` tiles |
| Extra travel over running during dash | `(600 - 220) * 0.15` |                               `57px` |
| Jump with one ideal dash              | `172 + 57`           | `229px`, or `6.36` tiles theoretical |

Use margins below theoretical limits. A comfortable running gap is at most four tiles; a deliberate dash-assisted gap is five to six tiles.

## Charge economy math

| Measure                 | Calculation |   Result |
| ----------------------- | ----------- | -------: |
| Full shadow survival    | `100 / 8`   |  `12.5s` |
| Empty-to-full sunlight  | `100 / 35`  |  `2.86s` |
| One dash as shadow time | `25 / 8`    | `3.125s` |
| Refill one dash         | `25 / 35`   |  `0.71s` |

This is the central economy: one dash spends one quarter of the meter and removes more than three seconds of potential shadow time.

## Player physics rules

### Required behavior

- Horizontal movement is immediate and deterministic at `220px/s` in the MVP.
- Jump starts only from the floor or within a `0.10s` coyote window.
- A jump press is buffered for `0.12s` before landing.
- Releasing jump while rising may cut vertical speed by `50%`; this is a feel-pass feature, not a level requirement.
- Dash is horizontal, preserves vertical velocity, and does not disable gravity.
- Dash can start on ground or in air when charge is at least `25` and no dash is active.
- Multiple air dashes are allowed if the player has charge; charge, not an air-dash counter, is the limiter.
- Fall speed is clamped to `900px/s` to keep collision and camera motion readable.
- Slopes, moving platforms, wall jumps, and one-way drop-through are outside the jam MVP.

### Player state

Lifecycle and motion have separate owners. `PlayerCore` uses a small lifecycle enum:

```gdscript
enum State { ACTIVE, RESPAWNING, INTERACTING }
```

- `ACTIVE` accepts movement, jump, and dash input.
- `RESPAWNING` rejects input and damage during reset.
- `INTERACTING` rejects gameplay input while a terminal owns focus.

`CharacterMotor2D` owns the dash timer and reports `is_dashing()`. Grounded and airborne remain collision facts supplied by the future body adapter rather than duplicated states.

### Physics update order

Use this order in `_physics_process(delta)`:

1. Tick coyote, jump-buffer, dash, and invulnerability timers.
2. Read action input if the state permits it.
3. Start a buffered jump or paid dash.
4. Apply horizontal movement when not dashing.
5. Apply gravity and clamp fall speed.
6. Call `move_and_slide()` once.
7. Update floor-derived timers for the next tick.
8. Fill or drain charge if gameplay is active.
9. Enter guarded respawn if charge reached zero.

Movement and charge both use physics `delta`; visual animation uses `_process` or `AnimationPlayer` and does not change gameplay values.

## Required engine modules

| Script                   | Godot root        | Responsibility                                                 |
| ------------------------ | ----------------- | -------------------------------------------------------------- |
| `player_tuning.gd`       | `Resource`        | Authored movement, dash, and charge values                     |
| `motion_input.gd`        | `RefCounted`      | One immutable-by-convention input snapshot                     |
| `character_motor_2d.gd`  | `RefCounted`      | Velocity, jump windows, gravity, facing, and dash timing       |
| `charge_model.gd`        | `RefCounted`      | Charge economy and sunlight overlap count                      |
| `player_core.gd`         | `RefCounted`      | Compose motor and charge; coordinate lifecycle and checkpoints |
| `player_body_adapter.gd` | `CharacterBody2D` | Input/collision adapter and `move_and_slide()` owner           |
| `sunlight_zone.gd`       | `Area2D`          | Report player overlap enter/exit                               |
| `light_platform.gd`      | `StaticBody2D`    | Toggle surface and collision from exposure                     |
| `checkpoint.gd`          | `Area2D`          | Set spawn point once and play feedback                         |
| `sentry.gd`              | `Node2D`          | Sweep, acquire lit player, warn, damage, reset                 |
| `cipher_definition.gd`   | `Resource`        | Store answer, glyph sequence, and mappings                     |
| `cipher_controller.gd`   | `Node`            | Track discoveries and validate answer                          |
| `cipher_clue.gd`         | `Area2D`          | Reveal one mapping while lit                                   |
| `cipher_terminal.gd`     | `Area2D`          | Open paused UI and submit answer                               |
| `hud.gd`                 | `CanvasLayer`     | Render charge, exposure, and cipher progress                   |
| `level_controller.gd`    | `Node2D`          | Wire the scene and change level on completion                  |

## Player contract

`PlayerCore` supplies the gameplay contract. The future body adapter may expose a narrow façade for areas and hazards, but it does not reimplement these rules:

```gdscript
class_name HeliographPlayerCore
extends RefCounted

signal charge_changed(current: float, maximum: float)
signal exposure_changed(in_sunlight: bool)
signal died
signal respawn_requested(spawn_position: Vector2)

func prepare_motion(input: HeliographMotionInput, delta: float, is_on_floor: bool) -> Vector2
func complete_physics_step(delta: float) -> void
func enter_sunlight() -> void
func exit_sunlight() -> void
func set_spawn_point(value: Vector2) -> void
func request_death() -> bool
func complete_respawn() -> void
```

`request_death()` gives hazards one stable entry point without exposing respawn details.

### Exposure transitions

An overlap counter supports adjacent or overlapping beams. Emit only when the semantic state changes:

```gdscript
func enter_sunlight() -> void:
    var was_in_sunlight := in_sunlight()
    sunlight_sources += 1
    if not was_in_sunlight:
        exposure_changed.emit(true)

func exit_sunlight() -> void:
    var was_in_sunlight := in_sunlight()
    sunlight_sources = maxi(0, sunlight_sources - 1)
    if was_in_sunlight and not in_sunlight():
        exposure_changed.emit(false)
```

### Charge update

Avoid emitting every physics frame when the value did not change:

```gdscript
func _update_charge(delta: float) -> void:
    var previous := charge

    if in_sunlight():
        charge = minf(max_charge, charge + charge_fill_rate * delta)
    else:
        charge = maxf(0.0, charge - charge_drain_rate * delta)

    if not is_equal_approx(previous, charge):
        charge_changed.emit(charge, max_charge)

    if charge <= 0.0:
        _die()
```

### Respawn invariants

`_die()` must be guarded against re-entry and restore all gameplay state:

- set state to `RESPAWNING` before emitting effects;
- clear velocity, dash timer, and pending jump input;
- clear `sunlight_sources` and emit `exposure_changed(false)` if needed;
- move to the shadow checkpoint;
- restore full charge and emit once;
- return to `NORMAL` after any short death effect.

All jam checkpoints are in shadow. If sunlight checkpoints are added later, replace the simple counter reset with an explicit overlap rescan after teleportation.

## Sunlight and reactive systems

### SunlightZone

```gdscript
func _on_body_entered(body: Node2D) -> void:
    if body is Player:
        body.enter_sunlight()

func _on_body_exited(body: Node2D) -> void:
    if body is Player:
        body.exit_sunlight()
```

The zone never fills charge directly. This keeps overlapping zones from multiplying the fill rate.

### Level wiring

Put platforms, sentries, clues, and exposure UI in the `light_reactive` group. `LevelController` connects them once:

```gdscript
func _bind_light_reactions(player: Player) -> void:
    for node in get_tree().get_nodes_in_group("light_reactive"):
        if node.has_method("set_player_in_sunlight"):
            player.exposure_changed.connect(node.set_player_in_sunlight)
            node.set_player_in_sunlight(player.in_sunlight())
```

This is level composition, not a global event bus. Keep `LevelController` inside each level scene.

### LightPlatform

`set_player_in_sunlight(active)` updates art immediately and collision deferred:

```gdscript
func set_player_in_sunlight(active: bool) -> void:
    active_visual.visible = active
    inactive_anchors.visible = not active
    collision_shape.set_deferred("disabled", not active)
```

Never hide the inactive anchors; they communicate the planned route.

## Sentry model

The Watcher is fixed in place. An `AnimationPlayer` or Tween rotates its vision `Area2D` between two authored angles. No navigation code is required.

Use three states:

```gdscript
enum State { SWEEPING, WARNING, COOLDOWN }
```

Rules:

1. `SWEEPING`: follow the authored sweep. If an overlapping player is lit, begin a `0.35s` warning.
2. `WARNING`: if the player leaves the cone or enters shadow, return to sweeping immediately. If the timer completes, call `player.request_death()`.
3. `COOLDOWN`: optional `0.75s` visual reset after firing; do not reacquire until complete.

The vision cone determines detection. A separate small hazard shape may kill on physical contact. Keep those collision responsibilities separate.

## Cipher model

Use one custom Resource per level:

```gdscript
class_name CipherDefinition
extends Resource

@export var answer: String
@export var sequence: Array[StringName]
@export var mappings: Dictionary[StringName, String]
```

`CipherController` stores discovered glyph IDs in a dictionary or set-like structure. Discovery is idempotent. Answer comparison should use:

```gdscript
var normalized := submitted.strip_edges().to_upper()
var solved := normalized == definition.answer.to_upper()
```

The terminal pauses the tree while open. Set the terminal UI root to `PROCESS_MODE_WHEN_PAUSED`, restore pause state on cancel and solve, and never leave the tree paused during scene change.

## Collision layers

| Layer | Name   | Collision use                                       |
| ----: | ------ | --------------------------------------------------- |
|     1 | World  | Ground and enabled light platforms                  |
|     2 | Player | Player body                                         |
|     3 | Hazard | Sentry contact or projectile damage                 |
|     4 | Sensor | Light, checkpoint, clue, terminal, and vision areas |

Recommended masks:

- Player body: layers `1` and `3`.
- Sensor areas: monitor layer `2` only.
- Sentry vision: monitor layer `2`; perform a world ray check only if level walls must block the cone.
- Light platforms: layer `1`, collision disabled while inactive.

## Camera

Use `Camera2D` as a child of the player with:

- position smoothing enabled around `6-8` speed;
- a small horizontal look-ahead based on facing;
- no vertical look-ahead during ordinary jumps;
- limits authored per level so void outside the room is never shown;
- reduced smoothing or an immediate snap after respawn.

Do not add camera shake to normal landings. Reserve a subtle impulse for death, checkpoint activation, and final transmission.

## Debug and test code

Add a debug overlay toggled by a non-shipping input action. It should show:

- current player state and velocity;
- charge and sunlight overlap count;
- coyote, jump buffer, and dash timers;
- active checkpoint position;
- sentry state and warning time;
- discovered cipher mapping IDs.

The headless unit suite must pass before scene work. It covers charge timing, overlap semantics, dash cost and duration, coyote time, jump buffering, fall clamping, interaction locking, and guarded respawn.

Then test these engine cases in one integration room:

- adjacent and overlapping sunlight zones;
- death in light followed by a shadow respawn;
- dash started on the last valid charge threshold;
- a platform disabling during a physics callback;
- sentry warning canceled by entering shadow on the last warning tick;
- terminal cancel, wrong answer, correct answer, and scene change;
- pause state restored after every terminal exit path.

## Implementation order

1. Project settings, tuning Resource, pure motion/charge models, player core, and headless unit tests.
2. Thin `CharacterBody2D` and input adapters plus physics integration tests.
3. Composed graybox player scene, sunlight areas, exposure signals, and HUD observer.
4. Guarded death, shadow checkpoints, and camera reset.
5. Light platform and the full **First Signal** route.
6. Watcher sweep, warning, cancel, and damage.
7. Cipher Resource, controller, clues, paused terminal, and completion.
8. Level controller, title/win flow, remaining jam levels, then presentation.

Do not start shaders, custom editor tools, save data, or a general ability system before this sequence is playable end to end.
