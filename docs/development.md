# Development Guide

## Current repository state

The repository contains a playable Godot 4.7 vertical slice. Scene-independent player, cipher, and sentry models are covered by headless unit tests. Reusable player, world, puzzle, HUD, title, level, and win scenes compose the runtime without an autoload or monolithic level script.

## Requirements

- Godot 4.7, as declared by `config/features` in `project.godot`
- Node.js 18 or newer only when editing or building this VitePress documentation
- Keyboard for the initial desktop control scheme

## Run the game

Open the repository root in Godot or run:

```bash
godot --path .
```

For a non-interactive parse and import check:

```bash
godot --headless --path . --editor --quit
```

## Input map

These actions are committed to `project.godot` so a fresh checkout is playable:

| Action       | Primary | Alternate       |
| ------------ | ------- | --------------- |
| `move_left`  | `A`     | Left arrow      |
| `move_right` | `D`     | Right arrow     |
| `jump`       | Space   | `W` or Up arrow |
| `dash`       | Shift   | `X`             |
| `interact`   | `E`     | Enter           |
| `pause`      | Escape  | None            |

Gameplay code must query actions, never physical keys directly.

## Player composition

`PlayerBodyAdapter` is the only `CharacterBody2D` owner. It translates `InputMap` state and collision facts into `PlayerCore`, calls `move_and_slide()` once, and synchronizes the resulting velocity. `PlayerCore` composes the motion and charge models; the visual child observes motion/exposure signals and owns no gameplay decisions.

Do not move charge, exposure, dash, checkpoint, or death rules back into the scene script. Add integration behavior through narrow adapters and keep deterministic rules in the tested core.

## Tests

Run the scene-independent rules and composed-scene contracts separately:

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --script res://tests/integration/scene_test_runner.gd
```

The integration suite covers scene binding, local collision resources, platform activation, checkpoint routing, clue discovery, terminal pause restoration, cipher completion, and the win transition.

## GDScript conventions

- Use typed parameters, returns, properties, and signals.
- Use `snake_case` for files, functions, variables, and input actions.
- Use `PascalCase` for `class_name` declarations.
- Connect state changes with signals; do not add per-frame polling to every consumer.
- Export scene references that level designers must assign and validate them in `_ready`.
- Use groups for discovery such as `player` only when an exported reference is impractical.
- Call `set_deferred("disabled", value)` when changing collision shapes from physics callbacks.
- Keep one script responsible for one scene contract.

## Tuning workflow

1. Build a test room that contains one example of every core interaction.
2. Record completion time, shadow deaths, missed jumps, dashes used, and cipher retries.
3. Change one family of values at a time: movement, charge, sentry timing, then level geometry.
4. Re-run from a clean start after every checkpoint or scene-transition change.

Do not balance around the developer's fastest route. The initial target is readability and a recoverable first playthrough.

## Documentation site

Install dependencies and start the local site from `docs/`:

```bash
cd docs
npm install
npm run dev
```

Validate production output with:

```bash
npm run build
```

Generated `node_modules`, `.vitepress/cache`, and `.vitepress/dist` directories are not source files and should not be committed.

## Documentation rules

- Update `game-design.md` when player-facing rules or scope change.
- Update `theme-and-art-direction.md` when visual, audio, UI, or asset rules change.
- Update `asset-plan.md` when a source file is accepted, renamed, replaced, or removed.
- Update `level-design.md` when room geometry, encounters, clue placement, or level cuts change.
- Update `architecture.md` when scene contracts, state ownership, or signal flow change.
- Update `physics-and-engine.md` when movement math, project settings, or code contracts change.
- Keep speculative ideas in the deferred scope, not mixed into MVP requirements.
- Prefer measured values and acceptance criteria over aspirational prose.
