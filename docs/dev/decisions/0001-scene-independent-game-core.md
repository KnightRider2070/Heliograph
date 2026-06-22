# ADR 0001: Scene-independent game core

## Status

Accepted

## Context

Heliograph needs deterministic movement and resource rules before scene production begins.
Putting input, motion, charge, exposure, collision, checkpoints, and presentation in one player
scene would make those rules difficult to test and expensive to extend.

Godot must remain the collision authority. Reimplementing `move_and_slide()` or maintaining a
second position simulation would create disagreement between tests and runtime behavior.

## Decision

Split the player runtime into these parts:

| Part | Kind | Owns |
| --- | --- | --- |
| `PlayerTuning` | `Resource` | Authored movement and economy values |
| `MotionInput` | `RefCounted` value | One physics-tick input snapshot |
| `CharacterMotor2D` | `RefCounted` model | Velocity, facing, jump windows, gravity, dash timer |
| `ChargeModel` | `RefCounted` model | Charge and sunlight overlap count |
| `PlayerCore` | `RefCounted` coordinator | Checkpoint, interaction, death, and respawn lifecycle |
| `PlayerBodyAdapter` | Future `CharacterBody2D` | Input translation, floor facts, collision, teleport application |

Core code may depend on Godot value types such as `Vector2`, but not on the scene tree, input
singleton, or physics server. The body adapter calls `prepare_motion()`, applies the returned
velocity, calls `move_and_slide()` once, and then calls `complete_physics_step()`.

Scenes are composition roots. The player scene will contain narrow nodes for body collision,
input, camera, visuals, audio, and effects. World scenes remain reusable and communicate through
the adapter/core public API and signals. Presentation never decides gameplay outcomes.

## Test boundary

Headless unit tests own calculations and state transitions. Later integration tests own behavior
that requires the physics server: body collision, `Area2D` overlap callbacks, deferred collision
changes, and composed scene wiring.

No gameplay scene is added until the core suite and headless editor import pass.

## Consequences

- Core behavior is fast to test without constructing nodes or scenes.
- Player presentation and controls can change without moving gameplay state.
- Collision correctness still needs a focused integration layer after the core is stable.
- `PlayerCore` is a coordinator, not a general event bus or service locator.
- New capabilities should be separate models only when they own meaningful state or rules; this
  decision does not justify one class per trivial operation.
