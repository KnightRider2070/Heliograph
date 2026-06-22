# Jam Level Design

> **Superseded by the cipher-deduction remix.** This page is the original jam
> planning doc (note the placeholder `ECHO`/`DAWN` ciphers); the shipped game uses
> the SUN → ARC → LUX → RAY → SOLAR progression with persistent glyphs. For how
> the current puzzle mechanics and platform pieces work, and the 10-level roadmap,
> see [Editing Levels](/level-editing). The construction metrics and checkpoint
> rules below still apply.

## Level design goals

The three levels form one short teaching arc:

1. **First Signal:** learn the resource cycle without enemy pressure.
2. **Watcher Hall:** learn that sunlight creates target eligibility.
3. **Last Transmission:** combine movement, exposure, threat, and decoding.

The target first-success run is 10 to 15 minutes. Each level should restart quickly, place checkpoints before combined challenges, and teach through geometry before showing text.

## Construction metrics

Build collision on a `36px` grid inside a `640x360` internal viewport. This preserves the selected Kenney `18x18px` tiles at integer `2x` scale. Art may extend beyond the grid, but critical ledges, sunlight boundaries, sensors, and sightline blockers should not.

| Element | Baseline |
| --- | ---: |
| Player collider | About `20x38px` |
| Standard floor height | `1` tile minimum |
| Comfortable gap | `2-3` tiles (`72-108px`) |
| Precision running jump | `4` tiles (`144px`) |
| Dash-assisted gap | `5-6` tiles (`180-216px`) |
| Comfortable ledge rise | `1-2` tiles (`36-72px`) |
| Shadow refuge | At least `3` tiles (`108px`) wide |
| Charge bay | At least `3` tiles (`108px`) wide or `0.75s` of safe dwell time |
| Sentry warning | `0.35s` before lethal confirmation |

Theoretical movement limits are documented in [Physics and Engine Systems](/physics-and-engine). Level geometry should stay below those limits unless the challenge is intentionally a mastery test.

All checkpoints in the jam levels are placed in shadow. This makes respawn deterministic and avoids having to reconstruct sunlight overlaps immediately after teleportation.

## Encounter language

Use this shorthand in room plans:

| Mark | Meaning |
| --- | --- |
| `S` | Shadow space |
| `L` | Sunlight zone |
| `P` | Player start or checkpoint |
| `+` | Light platform |
| `W` | Watcher and sweep area |
| `C` | Cipher clue |
| `T` | Cipher terminal |
| `X` | Exit |

A route strip shows encounter order, not exact tile geometry.

## Level 1: First Signal

**Purpose:** establish charge, shadow death, dash cost, light platforms, checkpoints, and a safe cipher.

**Target time:** 2 to 3 minutes.  
**Threat budget:** no Watchers.  
**Cipher answer:** `SUN`.

```text
P/S -> L charge bay -> S jump lane -> L dash bay + platform -> P/S -> L clues -> T/S -> X
```

### Room 1A: Waking Cell

- Start at full charge in a three-tile shadow pocket, matching the controller's normal spawn rule.
- Put a visible sunlight shaft one screen-width to the right; no pit or hazard lies between.
- Show movement and jump prompts only after the player moves.
- The charge meter begins draining immediately, then visibly reverses in the beam.
- A low one-tile step confirms jump and collision before any failure gap.

**Pass condition:** the player enters sunlight and sees that it refills charge.

### Room 1B: Measured Crossing

- Alternate one broad sunlight bay with a short shadow lane.
- Place a two-tile gap first, then a four-tile running jump.
- Put a six-tile gap after a charge bay and label dash once the player reaches its edge.
- A light platform supplies the final landing. Its faint anchors are visible from shadow; it becomes solid when the player enters the charge bay.
- Put a shadow checkpoint immediately after the landing.

**Failure lesson:** spending a dash removes `25` charge, so the next shadow lane begins with less survival time.

### Room 1C: Alphabet of Light

- Place three clue plates in separate sunlight shafts around one safe room.
- The terminal sits in a shadow alcove after the clues.
- Opening the terminal pauses charge drain and displays every discovered mapping.
- No clue is missable and no platform challenge separates the terminal from the last clue.

| Glyph ID | Reveals |
| --- | --- |
| `solar_disc` | `S` |
| `open_cup` | `U` |
| `north_needle` | `N` |

Terminal sequence: `solar_disc`, `open_cup`, `north_needle`.

**Completion:** solving `SUN` opens the exit shutters and plays the signal phrase once.

## Level 2: Watcher Hall

**Purpose:** teach sentry sweep timing, immediate concealment in shadow, multi-clue recall, and route planning around exposure.

**Target time:** 3 to 4 minutes.  
**Threat budget:** one Watcher scene reused in two rooms, never two active sightlines at once.  
**Cipher answer:** `ECHO`.

```text
P/S -> L sightline W -> S alcove -> L crossing -> P/S -> L platform W -> S clue route -> T/S -> X
```

### Room 2A: The First Sweep

- Frame a seven-tile sunlight corridor between two shadow walls.
- A fixed Watcher sweeps left to right and back on a `2.4s` cycle.
- A three-tile shadow alcove interrupts the corridor at its midpoint.
- The first sweep cannot kill the player at the entrance; it demonstrates the cone and warning pulse.
- If the player reaches the alcove during acquisition, targeting cancels immediately.

**Pass condition:** cross the corridor using the shadow alcove, not by tanking damage.

### Room 2B: Exposed Bridge

- Place a shadow checkpoint before the room.
- A sunlight bay activates two short light platforms over a pit.
- The Watcher sightline covers the platforms but not the charge bay entrance.
- The route requires waiting for the sweep, charging, then committing to a jump and optional dash.
- The far landing is shadow and wide enough for the player to stop safely.

**Design check:** the platform route must remain visible through faint anchors before it becomes solid.

### Room 2C: Echo Chamber

- Put four clue plates on a loop with two sunlight exposures and one central shadow refuge.
- Reuse the Watcher with a slower `3.0s` sweep so observation, not reaction speed, solves the room.
- Place the terminal in shadow next to the exit.

| Glyph ID | Reveals |
| --- | --- |
| `split_ring` | `E` |
| `relay_fork` | `C` |
| `low_horizon` | `H` |
| `glass_lens` | `O` |

Terminal sequence: `split_ring`, `relay_fork`, `low_horizon`, `glass_lens`.

The repeated sound and circular imagery in the room hint at the word `ECHO`, but the mappings remain sufficient without guessing.

## Level 3: Last Transmission

**Purpose:** require confident use of every core system and deliver the visual payoff.

**Target time:** 4 to 6 minutes.  
**Threat budget:** two Watchers maximum, separated by solid sightline blockers.  
**Cipher answer:** `DAWN`.

```text
P/S -> alternating L/S ascent -> W dash lane -> P/S -> L platform array W -> P/S -> split clues -> T/S -> X/win
```

### Room 3A: Broken Array

- Begin with an alternating ascent of two-tile ledges, light shafts, and three-tile shadow pockets.
- Use two overlapping sunlight zones in one wide beam. This looks ordinary to the player but verifies overlap counting.
- End with a six-tile dash-assisted lane covered by a Watcher sweep.
- A shadow landing and checkpoint follow the lane.

**Intent:** the player now chooses whether to spend charge to beat the sweep or wait in a limited shadow pocket.

### Room 3B: Mirror Chamber

- Show three light platforms as a clear diagonal route across an open chamber.
- The activation sunlight occupies the route itself, keeping the player exposed while platforms are solid.
- A Watcher sweeps the upper half; stone pillars break its sightline at two planned pauses.
- A fall returns the player to the room entrance rather than killing them where possible.
- Put a second shadow checkpoint after the chamber.

**Pass condition:** read anchors, charge, traverse under the sweep, and reach shadow with enough reserve for the clue route.

### Room 3C: Four Bearings

- Split four clues across two short branches from a central shadow hub.
- Each branch contains one sunlight traversal and one mapping pair.
- Do not add a new enemy or movement rule here; the challenge is route order and charge budgeting.
- Return both branches to the same shadow terminal so the player cannot become lost.

| Glyph ID | Reveals |
| --- | --- |
| `prism` | `D` |
| `eastern_arch` | `A` |
| `double_wave` | `W` |
| `north_star` | `N` |

Terminal sequence: `prism`, `eastern_arch`, `double_wave`, `north_star`.

**Completion:** solving `DAWN` rotates the station mirrors, sends one large beam beyond the level, and transitions to the win screen.

## Checkpoint and failure placement

- Never place a checkpoint inside sunlight or a Watcher sightline.
- Checkpoint after a teaching success, not before the player has seen the rule.
- Keep the retry path under five seconds for a single encounter.
- Use pit resets for local movement mistakes and full charge death for resource mistakes.
- Do not force the player to re-enter a solved cipher after death.

## Playtest questions

Record answers, not just completion time:

- Did the player understand why the meter changed direction?
- Did they see inactive platform anchors before committing?
- Did shadow cancel a Watcher quickly enough to feel reliable?
- Did any checkpoint create an unwinnable low-charge restart?
- Could the player reconstruct the cipher without memorizing off-screen clues?
- Which gap was mistaken for dash-required or dash-optional?
- Did terminal pause feel like relief or break the game's rhythm?

## Jam fallback: one vertical slice

If **First Signal** is not complete at the Day 1 gate, build one five-room level:

1. Charge tutorial from Room 1A.
2. Dash and light platform from Room 1B.
3. First sweep from Room 2A.
4. Exposed bridge from Room 2B.
5. A three-letter `SUN` cipher followed by the final signal effect.

This preserves the entire game identity with one Watcher, one checkpoint, three clues, one terminal, and one polished ending.
