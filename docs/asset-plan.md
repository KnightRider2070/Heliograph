# Asset Reuse Plan

## Purpose

This document maps the local Kenney collection to Heliograph and identifies what still needs to be authored. It is the source of truth for third-party asset selection.

The audited source is:

```text
/Users/argus/Downloads/kenny
```

That location is an import source only. Godot scenes must never reference `/Users/argus/Downloads`; selected files are copied into `res://assets/vendor/kenney/` with stable semantic names or documented atlas coordinates.

## Audit summary

The folder contains 3,510 filesystem entries and is approximately 16 MB. Eleven Kenney packs are present.

| Pack | Files | Decision | Reason |
| --- | ---: | --- | --- |
| `kenney_pixel-platformer` | 252 | Use selected atlas IDs | Core world props and player seed; biome backgrounds remain excluded |
| `kenney_pixel-platformer-industrial-expansion` | 122 | Use | Best fit for relay machinery, platforms, Watcher, terminal |
| `kenney_pixel-platformer-blocks` | 338 | Use stone subset | Large architectural blocks and engraved stone detail |
| `kenney_ui-pack-pixel-adventure` | 519 | Use small thin subset | HUD frames, buttons, warning banners, mapping cards |
| `kenney_input-prompts-pixel` | 823 | Use keyboard subset | Tutorial and interaction prompts |
| `kenney_kenney-fonts` | 13 | Use three fonts | Display, HUD, and terminal typography |
| `kenney_pixel-platformer-farm-expansion` | 122 | Do not use | Rural crops and tools do not support the relay-station theme |
| `kenney_pixel-platformer-food-expansion` | 122 | Do not use | Thematic mismatch and no required gameplay role |
| `kenney_platformer-art-buildings` | 104 | Do not use | Non-pixel/vector style conflicts with the selected pixel family |
| `kenney_platformer-art-extended-enemies` | 186 | Do not use | Different proportions and no enemy matches the fixed mechanical Watcher |
| `kenney_platformer-art-pixel` | 908 | Do not use | Older palette, density, and character language would create a mixed style |

All audited packs declare Creative Commons Zero (`CC0`). Attribution is not required, but the shipped credits should still include `Kenney - kenney.nl`, and copies of the source license files should remain under `assets/vendor/kenney/licenses/`.

## Scale and import policy

The selected world packs use `18x18px` tiles. Preserve their pixels at integer `2x` scale:

| Source | Native size | Game presentation |
| --- | ---: | --- |
| World and industrial tiles | `18x18px` | `36x36px` world grid |
| Character and background cells | `24x24px` | `48x48px` visual cells |
| Small UI and input prompts | `16x16px` | `32x32px` UI cells |
| Pixel fonts | Vector font file | Integer font sizes; no fractional Control scale |

Godot import rules:

- texture filter: `Nearest`;
- mipmaps: disabled for sprites, tiles, UI, and prompts;
- repeat: disabled unless a specific background texture is intentionally tiled;
- atlas region separation: `0` for every `_packed.png` source;
- visual scaling: integer `2x`; do not resample source PNG files to `32px`;
- collision remains independent from sprite transparency;
- camera visuals should settle on integer pixels even though physics positions may remain fractional.

## Repository layout

Copy a curated set, not the entire Downloads directory:

```text
res://assets/
  vendor/kenney/
    atlases/
      pixel_platformer_world.png
      pixel_platformer_characters.png
      industrial.png
      stone_blocks.png
      ui_small_thin.png
      input_prompts.png
    fonts/
      kenney_pixel_square.ttf
      kenney_mini_square.ttf
      kenney_mini_square_mono.ttf
    licenses/
      pixel_platformer.txt
      industrial.txt
      blocks.txt
      ui_pixel_adventure.txt
      input_prompts.txt
      fonts.txt
  game/
    characters/courier/
    glyphs/
    ui/
    fx/
    audio/
```

The copied atlas names are stable project APIs. Source pack names and numbered tile IDs stay documented here so an atlas can be regenerated or replaced safely.

## Locked atlas sources

| Project target | Exact local source | Region | Columns |
| --- | --- | ---: | ---: |
| `pixel_platformer_world.png` | `kenney_pixel-platformer/Tilemap/tilemap_packed.png` | `18x18` | 20 |
| `pixel_platformer_characters.png` | `kenney_pixel-platformer/Tilemap/tilemap-characters_packed.png` | `24x24` | 9 |
| `industrial.png` | `kenney_pixel-platformer-industrial-expansion/Tilemap/tilemap_packed.png` | `18x18` | 16 |
| `stone_blocks.png` | `kenney_pixel-platformer-blocks/Tilemap/stone_packed.png` | `18x18` | 9 |
| `ui_small_thin.png` | `kenney_ui-pack-pixel-adventure/Tilesheets/Small tiles/Thin outline/tilemap_packed.png` | `16x16` | 23 |
| `input_prompts.png` | `kenney_input-prompts-pixel/Tilemap/tilemap_packed.png` | `16x16` | 34 |

Numbered source IDs are row-major. Convert an ID to atlas coordinates with:

```text
x = id % columns
y = floor(id / columns)
```

## World asset manifest

### Courier seed

| Source ID | Atlas coordinate | Project role | Treatment |
| ---: | ---: | --- | --- |
| Character `tile_0006` | `(6, 0)` | Courier idle seed | Use as the approved silhouette and palette frame |
| Character `tile_0007` | `(7, 0)` | Courier movement seed | Use as the second prototype frame and animation reference |

These two frames are not a complete animation set. They establish the yellow suit, helmet, scale, bottom-center anchor, and facing direction for custom frames.

### Relay architecture and props

IDs in this table refer to `pixel_platformer_world.png`.

| Source ID or range | Atlas coordinate | Heliograph use |
| --- | --- | --- |
| `tile_0064-0066` | `(4-6, 3)` | Three mirror/lever poses for cipher plates and checkpoint movement |
| `tile_0067` | `(7, 3)` | Signal-cell icon and checkpoint core |
| `tile_0069-0070` | `(9-10, 3)` | Small pedestal and mirror mounting pieces |
| `tile_0084-0088` | `(4-8, 4)` | Direction signs and route-language props |
| `tile_0130` | `(10, 6)` | Exit shutter/door base sprite |
| `tile_0151` | `(11, 7)` | Gold charge disc for HUD or checkpoint feedback |
| `tile_0152` | `(12, 7)` | Vertical signal marker for clue and exit feedback |

Do not use the pack's grass, water, cactus, mushroom, snow, or fantasy creature tiles. They conflict with the relay complex.

### Industrial terrain and machinery

IDs in this table refer to `industrial.png`.

| Source ID or range | Atlas coordinate | Heliograph use |
| --- | --- | --- |
| `tile_0000-0003` | `(0-3, 0)` | Primary metal-capped floor edge |
| `tile_0016-0019` | `(0-3, 1)` | Floor and wall transition tiles |
| `tile_0032-0035` | `(0-3, 2)` | Solid wall fill variants |
| `tile_0048-0051` | `(0-3, 3)` | Deeper wall and pillar fill variants |
| `tile_0057` | `(9, 3)` | Cipher clue plate housing |
| `tile_0059` | `(11, 3)` | Pedestal/mast used by checkpoint, terminal, and Watcher |
| `tile_0064-0065` | `(0-1, 4)` | Red alert and blue checkpoint beacon |
| `tile_0073` | `(9, 4)` | Terminal display and status screen |
| `tile_0075-0077` | `(11-13, 4)` | Vertical pipe and machine body pieces |
| `tile_0083` | `(3, 5)` | Watcher rotating mirror-head base |
| `tile_0087-0090` | `(7-10, 5)` | Active light-platform strip and inactive anchor silhouette |
| `tile_0091-0093` | `(11-13, 5)` | Pipe bends and relay conduits |
| `tile_0107-0111` | `(11-15, 6)` | Horizontal pipe run and end caps |
| `tile_0042` | `(10, 2)` | Sentry and lethal-route warning sign |

Exclude the acid-green terrain and tubes from gameplay surfaces. Green is reserved neither for sunlight nor danger and would weaken the solar-noir palette.

### Stone background kit

Use `stone_blocks.png` behind collision terrain, tinted toward `Twilight` and `Shadow`:

| Source range | Heliograph use |
| --- | --- |
| `tile_0000-0026` | Engraved caps, corners, vents, and small wall reliefs |
| `tile_0027-0080` | Multi-tile monoliths, pillars, and distant relay foundations |

Stone blocks are background architecture by default. The industrial atlas remains the authoritative collision edge so players see one consistent floor language.

### Background decision

Do not import `tilemap-backgrounds_packed.png`. Its forest, desert, snow, and cactus silhouettes are technically compatible but thematically wrong for the relay station. Build parallax architecture from tinted stone blocks and industrial pipe silhouettes, then add the small custom mirror-array set listed below.

## Composite gameplay objects

These objects require scenes and transforms, not new raster art:

| Object | Reused parts | Additional Godot presentation |
| --- | --- | --- |
| Watcher | Generated three-state optical sentry sheet | Rotating sensor pivot, additive cone shader, boundary rays, warning lock ray |
| Sunlight aperture | Generated narrow, medium, and wide optical modules | Width-selected source sprite, additive beam shader, hard gameplay edges, drifting motes |
| Checkpoint | Industrial `0059` mast + `0065` beacon + world `0067` cell | Cyan glow, one activation animation, particles |
| Cipher clue | Industrial `0057` frame + world `0064-0066` lever | Custom glyph overlay, lit/unlit shader state |
| Cipher terminal | Industrial `0073` screen + `0059` mast | Custom glyph sequence, interaction prompt, paused UI |
| Light platform | Industrial `0087-0090` strip | Full opacity when active; low-alpha anchors when inactive |
| Exit shutter | World `0130` + industrial pipe/girder pieces | AnimationPlayer opening and final signal glow |

The sight cone, sunlight beams, shadow masks, dash trail, dust, glow, and alert pulse should be made with `Polygon2D`, duplicated sprites, particles, and shaders. They do not need standalone texture files for the jam build.

## UI asset manifest

Use the thin-outline **small** UI atlas at integer `2x`. Do not mix the large `32px` UI tiles into the same screen; their pixel density differs at the chosen scale.

| UI source ID | Atlas coordinate | Heliograph use |
| ---: | ---: | --- |
| `tile_0018` | `(18, 0)` | Dark icon well and inactive slot |
| `tile_0039` | `(16, 1)` | Dark framed mapping card / NinePatch source |
| `tile_0070` | `(1, 3)` | Danger-state button or indicator |
| `tile_0072` | `(3, 3)` | Signal-state button or indicator |
| `tile_0074` | `(5, 3)` | Confirmed/solved indicator |
| `tile_0076` | `(7, 3)` | Charge pip |
| `tile_0077` | `(8, 3)` | Low-charge warning mark |
| `tile_0083-0085` | `(14-16, 3)` | Three-part red Watcher warning banner |

Use Godot `StyleBoxFlat` for the charge bar, terminal, and large plain panel bodies. The selected Kenney tiles provide mapping cards, buttons, warnings, and icon wells without forcing every surface into a tiled texture.

## Input prompt manifest

Use individual regions from `input_prompts.png` for the first keyboard tutorial:

| Source ID | Atlas coordinate | Action |
| ---: | ---: | --- |
| `tile_0017` | `(17, 0)` | Escape / close / pause |
| `tile_0086` | `(18, 2)` | `W` alternate jump |
| `tile_0087` | `(19, 2)` | `E` interact |
| `tile_0120` | `(18, 3)` | `A` move left |
| `tile_0122` | `(20, 3)` | `D` move right |
| `tile_0134` | `(32, 3)` | Enter / submit |
| `tile_0156` | `(20, 4)` | `X` alternate dash prompt |

The pack stores wide keys as multiple small tiles. Build `Space` and `Shift` prompts as UI capsules using the selected font rather than assembling unclear multi-part key art. Physical bindings remain as documented in the InputMap.

## Font manifest

| Exact source | Project role |
| --- | --- |
| `kenney_kenney-fonts/Fonts/Kenney Pixel Square.ttf` | Title, room names, large success text |
| `kenney_kenney-fonts/Fonts/Kenney Mini Square.ttf` | HUD labels and short instructions |
| `kenney_kenney-fonts/Fonts/Kenney Mini Square Mono.ttf` | Cipher mappings, terminal input, debug overlay |

Use short copy. Pixel fonts should not be used for dense paragraphs or scaled fractionally.

## Per-level reuse

| Level | Kenney assets used |
| --- | --- |
| **First Signal** | Industrial terrain, stone background blocks, lever clue frames, blue checkpoint beacon, light-platform strip, terminal screen, exit door, courier |
| **Watcher Hall** | First Signal kit plus Watcher composite, red beacon, warning sign/banner, pipe runs, additional light-platform sections |
| **Last Transmission** | Full kit plus large stone monoliths, dense relay conduits, custom mirror-array silhouette, final shutter assembly |

Levels gain complexity through composition and lighting, not by introducing a new asset style per level.

## Asset production status

### P0: required to ship the game identity

| Asset | Status | Production approach |
| --- | --- | --- |
| Courier animation completion | Complete for vertical slice | Generated 4x3 source sheet; locally removed chroma key; normalized to twelve anchored `64x64` runtime frames |
| Cipher glyph set | Complete | Eleven geometric SVG masks mapped through `GlyphLibrary` |
| Exposure shutter icon | Complete | Open and closed SVG indicators integrated into the HUD |
| Final mirror-array silhouette | Complete | Tintable SVG emblem integrated into title and win screens |
| Relay-station backdrop | Complete | Generated solar-noir panorama integrated behind gameplay and screens |
| Watcher visual states | Complete | Generated neutral, warning, and firing frames normalized to shared `96x96` canvases |
| Sunlight aperture modules | Complete | Three generated source modules normalized to shared `192x96` canvases |
| Game audio | Not started | Two ambient loops and core interaction SFX still require a separate audio pass |

The eleven required glyphs are:

```text
solar_disc, open_cup, north_needle,
split_ring, relay_fork, low_horizon, glass_lens,
prism, eastern_arch, double_wave, north_star
```

### P1: polish after a complete playthrough

- Courier turn frame and additional idle variation.
- Unique title lockup using `Kenney Pixel Square` as the base.
- One landmark silhouette for each level.
- Custom checkpoint flare and final signal beam texture if procedural effects are insufficient.
- Promotional key art and store/jam-page screenshots.

### Audio backlog

No supplied Kenney pack contains audio. The minimum audio list is:

- sunlight and shadow ambient loops;
- jump/land pair;
- dash shutter snap;
- enter-light and low-charge feedback;
- Watcher acquire, warning, and fire;
- checkpoint activation;
- glyph discovery;
- terminal accept, reject, and cipher solved;
- death collapse and final signal.

Music remains optional. State-readable sound effects take priority.

## Sprite production rule

The Courier uses one generated source sheet and a deterministic normalization workflow:

1. Preserve the checked-in chroma and alpha source sheets for provenance.
2. Run `tools/process_courier_sheet.gd` after any approved source-sheet replacement.
3. Preserve the same yellow suit, round helmet, cyan cell, facing direction, and frame order.
4. Normalize every frame to the shared `64x64` bottom-center canvas.
5. Inspect representative idle, run, jump, dash, and death frames before integration.
6. Validate the animated scene against the unchanged `20x38px` gameplay collider.

Do not recolor the Courier per state; light and shadow are communicated through rim tint, the cyan cell, and environment response.

## Integration sequence

1. **Complete:** copy the six locked atlases, three fonts, and six license files into `res://assets/vendor/kenney/`.
2. **Complete for the vertical slice:** use normalized generated frames for the Courier and Watcher, generated aperture modules for sunlight sources, and AtlasTextures for checkpoint, clue, and terminal components.
3. **Complete:** build and visually verify one style-proof route with terrain, checkpoint, platform, Watcher, terminal, and both light states.
4. **Deferred until more terrain content exists:** create reusable Godot `TileSet` atlas sources for world, industrial, and stone at `18x18px` region size.
5. Produce the Courier strips and custom glyph set after movement and encounter playtesting.
6. Add the prompt atlas where first-time tutorial prompts replace the current text labels.
7. Add audio, final signal assets, and shipping screenshots last.

## Acceptance criteria

- No scene references `/Users/argus/Downloads/kenny`.
- All selected textures render with nearest filtering and integer scale.
- Collision aligns with the `36px` world grid despite `18px` source textures.
- Kenney terrain, UI, and character art share one visible pixel density.
- Every imported atlas and tile ID has a documented gameplay role.
- Excluded packs are not mixed into the shipped levels.
- Custom Courier frames match the seed silhouette and anchor.
- License copies and voluntary Kenney credit ship with the game.
