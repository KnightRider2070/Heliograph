# Headless core tests

Run the scene-independent game core tests with the Godot executable:

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

Use the platform-specific Godot executable path when `godot` is not on `PATH`.

Run the composed scene integration tests with:

```bash
godot --headless --path . --script res://tests/integration/scene_test_runner.gd
```

Run the generated chapter, HUD, sunlight, patrol, and puzzle integration checks with:

```bash
godot --headless --path . --script res://tests/integration/chapter_scene_test_runner.gd
```

These tests intentionally do not instantiate scenes. Integration tests for body collision,
areas, deferred collision changes, and scene wiring belong in the next layer after the core
contracts are stable.
