# Game Design

## High concept

**Heliograph** is a short 2D platformer about carrying sunlight through hostile ruins to decode a hidden transmission. Sunlight restores charge and reveals the route, but also exposes the player to sentries. Shadow conceals the player, but drains charge until they fade and respawn.

The intended rhythm is **expose, charge, traverse, hide, decode**.

The presentation is **solar noir**: a deserted heliograph relay at the end of its final day, where brass optics, stone machinery, and code markings cut through deep indigo shadow. See [Theme and Art Direction](/theme-and-art-direction).

## Design pillars

1. **No permanent safety.** Light attracts danger; shadow consumes the resource needed to survive.
2. **One resource, several decisions.** Charge is survival time and dash fuel, so every dash shortens the next shadow window.
3. **Information requires exposure.** Cipher clues are readable only while the player is lit.
4. **Small rules, combined deeply.** The MVP uses one enemy and one puzzle type rather than adding disconnected mechanics.

## Player verbs

- Run and jump through a side-view level.
- Dash horizontally by spending charge.
- Enter sunlight to refill and activate light-dependent content.
- Retreat into shadow to become untargetable by light-based sentries.
- Discover glyph-to-letter mappings and enter a decoded answer at a terminal.
- Activate checkpoints that become the next respawn location.

## Core loop

1. Read the next route from a shadowed position.
2. Enter sunlight to refill charge and reveal light platforms or cipher clues.
3. Cross the exposed space before a sentry catches the player.
4. Spend charge on a dash when speed or distance matters.
5. Reach shadow to break enemy targeting, then move again before charge reaches zero.
6. Gather enough mappings to solve the level's terminal and advance.

## Light and shadow rules

| State | Charge | World | Enemies | Information |
| --- | --- | --- | --- | --- |
| Sunlight | Fills at `35/s` up to `100` | Light platforms are active | Player is targetable | Light glyphs are readable |
| Shadow | Drains at `8/s` down to `0` | Light platforms are inactive | Player is concealed | Light glyphs are hidden |

At zero charge, the player dies and respawns at the last checkpoint with full charge. There is no neutral recovery zone in the MVP: every place outside a sunlight zone counts as shadow.

The prototype activates light-dependent content from the **player's exposure state**. When the player is lit, relevant light platforms and clues activate. Local per-object illumination is a possible later refinement, not an MVP requirement.

### Baseline timing

The supplied controller establishes these starting values:

| Parameter | Value | Design effect |
| --- | ---: | --- |
| Maximum charge | `100` | Shared survival and ability budget |
| Sunlight fill | `35/s` | Empty-to-full in about `2.86s` |
| Shadow drain | `8/s` | Full charge lasts `12.5s` in shadow |
| Dash cost | `25` | Four dashes from full charge without refilling |
| Dash speed | `600` | Short burst above the `220` run speed |
| Dash duration | `0.15s` | About `90px` before collision response |
| Jump velocity | `-430` | Initial graybox jump tuning |
| Gravity | `1100` | Initial graybox fall tuning |

These are test values, not balance promises. Tune them only after a complete graybox loop exists.

## Threat model

The MVP has one sentry type. Its only essential rule is binary:

- In sunlight, the player can be detected and killed.
- In shadow, the sentry cannot acquire or retain the player as a target.

Detection presentation may use a sweep beam, warning color, and short reaction window. Combat, health, stealth meters, and multiple enemy archetypes are outside the MVP.

## Cipher puzzle

Use a single substitution-cipher format across the game:

1. A level contains glyph clues that reveal a `glyph -> letter` mapping in sunlight.
2. Discovered mappings remain recorded for the rest of that level.
3. The exit terminal displays a glyph sequence.
4. The player enters the decoded word.
5. A correct answer completes the level; an incorrect answer gives feedback without erasing progress.

Later levels increase difficulty through clue placement, exposure time, and route pressure, not through a new cipher system.

Opening a terminal pauses gameplay and charge drain. Cipher solving is an information test, not a typing-speed or menu-survival test.

## Level progression

| Level | Teaches | Required combination | Answer |
| --- | --- | --- | --- |
| 1. First Signal | Sunlight fills, shadow drains, zero charge respawns | Movement, one dash gap, checkpoint, safe cipher tutorial | `SUN` |
| 2. Watcher Hall | Sentries only threaten a lit player | Timed light crossing, shadow retreat, several mappings | `ECHO` |
| 3. Last Transmission | All rules under pressure | Light platforms, sentry timing, final cipher, win state | `DAWN` |

Each level should prove one idea quickly. If production time slips, combine all three teaching beats into one polished vertical-slice level instead of shipping three incomplete levels.

The complete jam run should take roughly 10 to 15 minutes on a first successful playthrough. Detailed rooms and encounter budgets live in [Jam Level Design](/level-design).

## Scope boundary

### MVP

- Desktop 2D play in Godot 4.7
- Keyboard movement, jump, and horizontal dash
- Zone-based sunlight; all other space is shadow
- Charge HUD, death, checkpoints, and respawn
- Player-state-driven light platforms and clue visibility
- One sentry type
- One substitution-cipher system
- Title, three short levels, and win state

### Deferred

- Dynamic sun movement or physically simulated lighting
- A mechanical day clock
- Light bridges as a player-created ability
- Shadow-only doors and symbols
- Multiple cipher families or logic-gate puzzles
- Combat, health, inventory, progression trees, or persistent saves
- Multiple enemy types and boss encounters

## Experience acceptance criteria

The design is working when a new player can explain, without prompting, that light is needed to recharge and read the route, shadow prevents detection but cannot be occupied forever, and dashing trades future safety for immediate movement.
