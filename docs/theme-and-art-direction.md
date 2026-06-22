# Theme and Art Direction

## Creative north star

**Solar noir at a dying signal station.** The world is built from warm analog instruments and severe architectural shadows. Light is beautiful, useful, and dangerous. Darkness is quiet, protective, and temporary.

Every presentation decision should reinforce one of three ideas:

- sunlight carries power and information;
- exposure attracts mechanical attention;
- the player is reconstructing one final transmission.

## Setting

Heliograph takes place inside a remote relay complex built to transmit messages through mirrors and coded flashes. The network has fallen silent. Its lenses are cracked, its cipher drums are incomplete, and autonomous Watchers still guard the illuminated routes.

The player is a small signal courier carrying a light cell. They cross the station, recover glyph mappings from exposed relay plates, and decode the last message before leaving the array.

Keep narrative delivery environmental and short. The jam build needs a title card, one opening line, room names, terminal text, and a final decoded message. It does not need dialogue scenes or lore collectibles.

## Visual language

The style combines three source families without reproducing a specific historical machine:

| Source | Shapes and materials | Use |
| --- | --- | --- |
| Heliograph optics | Circular mirrors, shutters, tripods, hard beams | Sunlight zones, checkpoints, sentries |
| Cryptographic machinery | Rotors, punched marks, segmented labels, cable paths | Terminals, glyph panels, level decoration |
| Solar observatory | Stone arches, long windows, brass rails, dust | Environment silhouette and scale |

Use large readable shapes. Fine mechanical detail belongs in backgrounds and terminal close-ups, not on collision-critical edges.

## Palette

| Token | Hex | Role |
| --- | --- | --- |
| Ink | `#0B1020` | Deepest background and silhouette |
| Shadow | `#18233A` | Playable shadow space |
| Twilight | `#4C3F72` | Distant architecture and depth |
| Sun | `#FFD166` | Safe-to-read sunlight and charge |
| Heat | `#FF8C42` | Intense exposure and active machinery |
| Signal | `#7BE0D6` | Decoded information and checkpoint confirmation |
| Danger | `#E84A5F` | Sentry warning and lethal state |
| Paper | `#F2E9D8` | Text, glyph labels, and high-contrast UI |

Sunlight should shift from `Sun` at the beam edge to `Heat` near its source. Shadow remains blue-violet rather than black so hazards and terrain are still readable.

Do not communicate state with hue alone:

- sunlight has drifting dust and a sharp diagonal edge;
- shadow has still air and low-contrast vertical texture;
- an active platform gains a solid outline and upward particles;
- sentry warning adds a pulse, sound, and expanding sight marker;
- depleted charge increases meter pulse frequency and player flicker.

## Lighting grammar

Gameplay light uses authored `Area2D` zones. The artwork may soften beam edges, but the playable boundary must remain legible within roughly `8px`.

| State | Presentation |
| --- | --- |
| Enter sunlight | Gold rim light on player, cell brightens, warm layer fades in over `0.12s` |
| Remain in sunlight | Dust travels along beam; charge meter fills steadily |
| Enter shadow | Rim light closes like a shutter; ambience becomes quieter |
| Low charge | Cell and HUD pulse below `25%`; heartbeat/tick interval shortens |
| Light platform inactive | Faint engraved anchors remain visible; surface and collision are absent |
| Light platform active | Anchors connect into a solid gold-white surface |

Inactive platform anchors are important. The player must be able to plan a route before exposing themselves.

## Character language

### The Courier

- Use the generated yellow Courier sheet normalized to anchored `64x64px` runtime frames with nearest filtering.
- Keep the gameplay collider near `20x38px`; transparent sprite padding and the helmet may extend beyond it.
- Bright circular light cell at the sternum or backpack.
- One trailing cable and cyan speed streaks communicate run and dash direction.
- No facial animation requirement; pose and cell state carry feedback.
- Sunlight adds a warm edge; shadow leaves only the cell and pale eye slit readable.

### The Watcher

- Use the generated three-state optical machine at `96x96px`: amber sweep, red shutter warning, white-red firing aperture.
- Fixed brass tripod with a rotating mirror head.
- Triangular sight wedge, never a vague radial detection field.
- Neutral sweep uses `Sun`; acquisition shifts to `Danger` and accelerates its pulse.
- The head snaps back to patrol when the player enters shadow.

The Watcher should read as station machinery, not a soldier. This keeps the game focused on systems and signals rather than combat.

## Environment kit

Build the jam environments from a small reusable kit:

- industrial and stone modules built from `18px` Kenney tiles at integer `2x`, producing a `36px` world grid;
- one arch/window module that can contain a sunlight zone;
- brass rail and cable background strips;
- inactive and active light-platform states;
- checkpoint mirror pedestal;
- cipher plate and terminal console;
- one foreground shadow mask and two distant background layers.

Use silhouettes and color blocking first. Decorative cracks, cables, screws, and dust are a final pass.

## Interface direction

The HUD is low-chrome and always readable against both states:

- **Charge:** a horizontal or shallow arc meter in the upper-left, labeled with a cell icon rather than a number by default.
- **Exposure:** a small open/closed shutter icon next to charge. This duplicates the world lighting cue.
- **Cipher notebook:** discovered mappings appear as compact `glyph -> letter` cards along the lower edge and collapse when not changing.
- **Terminal:** centered dark panel with a segmented brass frame, full glyph sequence, discovered mappings, text entry, and explicit submit/cancel prompts.

Use a clean humanist sans-serif for instructions and a monospaced face for terminal output. Avoid distressed fonts for body text.

When the terminal opens, gameplay pauses. The background darkens but remains visible so the puzzle still feels located in the level.

## Motion and effects

Prioritize five effects in this order:

1. Light-entry rim and dust response.
2. Short dash trail using two or three fading silhouettes.
3. Sentry warning pulse and beam contraction.
4. Death as the light cell collapsing to a point before respawn.
5. Cipher success as shutters opening and a signal beam leaving the station.

Avoid continuous full-screen bloom, camera shake on ordinary movement, and dense particles that obscure platform edges.

## Audio direction

| Event or layer | Sound language |
| --- | --- |
| Sunlight ambience | Warm electrical hum, glass resonance, sparse wind |
| Shadow ambience | Low room tone, distant relay clicks, reduced high frequencies |
| Charge fill | Quiet rising harmonic, never a constant alarm |
| Low charge | Slow mechanical tick that accelerates below `15%` |
| Dash | Shutter snap plus short air cut |
| Sentry acquisition | Two-stage relay click followed by a `0.35s` warning tone |
| Glyph discovered | Single tuned telegraph key click |
| Cipher solved | Four-note signal phrase reused in the win state |

Music is optional. If time is limited, strong ambience and state feedback are more valuable than a looping score.

## Asset budget

| Domain | Jam target |
| --- | ---: |
| Player | 1 sprite set: idle, run, jump/fall, dash, death |
| Enemy | 1 Watcher with sweep and alert states |
| Environment | 8-12 modular pieces plus 3 background layers |
| Interactables | Platform, checkpoint, clue plate, terminal |
| UI | Charge, exposure, mapping card, terminal panel |
| Effects | Light dust, dash trail, warning pulse, death collapse, success beam |
| Audio | 8-12 one-shots plus 2 ambient loops |

If custom art falls behind, ship flat silhouettes with this palette. Do not mix unrelated asset packs merely to add detail.

The exact reusable files, excluded packs, tint rules, and custom backlog are defined in [Asset Reuse Plan](/asset-plan).

## Theme acceptance criteria

- A still screenshot clearly separates sunlight, shadow, solid terrain, and inactive light platforms.
- The player and Watcher remain identifiable at game scale.
- Exposure and sentry warning are readable without relying on color.
- Cipher UI looks related to machinery already present in the level.
- The final signal uses the same visual and audio motifs introduced by checkpoints and clue discovery.
