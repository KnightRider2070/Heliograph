# Visual Asset Generation

## Outputs

The visual overhaul uses the built-in OpenAI image generation tool for two authored raster sources:

| Output | Runtime role |
| --- | --- |
| `assets/game/backgrounds/relay_station_panorama-v1.png` | Title, level, and win backdrop |
| `assets/game/characters/courier/source/courier_sheet_chroma-v1.png` | Retained chroma-key generation source |
| `assets/game/characters/courier/source/courier_sheet_alpha-v1.png` | Locally extracted alpha source |
| `assets/game/characters/courier/frames/*.png` | Twelve normalized runtime frames |
| `assets/game/enemies/watcher/frames/*.png` | Sweep, warning, and firing Watcher states |
| `assets/game/environment/apertures/frames/*.png` | Narrow, medium, and wide sunlight-source machinery |

The generation source directory contains `.gdignore`; Godot imports only the normalized runtime frames.

## Panorama prompt

```text
Use case: stylized-concept
Asset type: production background for a 2D side-scrolling pixel-art game, designed to sit behind gameplay collision
Primary request: a cinematic interior panorama of an abandoned heliograph relay station at the final hour of daylight
Scene/backdrop: immense stone observatory ruins with deep arches, brass mirror arrays, suspended optical machinery, cables, cipher drums, and distant relay towers; a few hard diagonal sun shafts cut through dust and severe indigo shadow
Style/medium: highly polished 2D pixel art, crisp deliberate pixels, 16-bit era density with modern lighting discipline, no painterly blur
Composition/framing: wide 16:9 panorama, strong horizontal side-view layers, distant architecture only, lower 20 percent kept dark and visually quiet for a playable platform silhouette, no foreground character, no enemies
Lighting/mood: solar noir, beautiful but dangerous light, lonely final transmission
Color palette: ink #0B1020, shadow #18233A, twilight #4C3F72, sun #FFD166, heat #FF8C42, signal cyan #7BE0D6, sparse danger red #E84A5F
Constraints: no text, no logos, no UI, no watermark, no characters, no visible floor collision edges, preserve clear contrast and broad readable shapes, tile-friendly left and right edges where practical
Avoid: photorealism, 3D render look, soft airbrush gradients, fantasy vegetation, medieval castle motifs, neon cyberpunk clutter
```

## Courier prompt

```text
Use case: stylized-concept
Asset type: source sprite sheet for a 2D pixel-art game character
Primary request: create one consistent animation sheet for a small solar courier in a yellow pressure suit and round white helmet, carrying a bright cyan signal cell
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for background removal; the background must be completely uniform with no floor, shadow, gradient, texture, reflections, or lighting variation
Subject: the exact same short compact courier in every frame, facing right, large round helmet, dark indigo visor with one pale eye slit, yellow-orange suit, tiny brass fittings, cyan diamond light cell on chest, one short trailing cable
Style/medium: crisp hand-authored 2D pixel art, deliberate square pixels, compact 24x24-game-sprite proportions, matching a polished 16-bit platformer
Composition/framing: strict 4 columns by 3 rows grid of 12 equally sized isolated frames; row 1 two idle poses then two run poses; row 2 two more run poses then jump then fall; row 3 two horizontal dash poses then two death/collapse poses; identical bottom-center anchor and scale in every cell; generous empty chroma-key padding between frames
Color palette: ink #0B1020, shadow #18233A, yellow #FFD166, orange #FF8C42, cyan #7BE0D6, paper #F2E9D8
Constraints: no labels, no numbers, no text, no watermark, no cast shadows, no contact shadows, no anti-aliased painterly edges, no #00ff00 anywhere in the character, every character fully separated from every other character and from image edges
Avoid: multiple character designs, perspective rotation, front-facing poses, photorealism, 3D rendering, oversized weapons, capes, background scenery
```

## Deterministic assets

The eleven glyphs, exposure shutters, and final mirror array are repository-native SVG files. They are geometric, tintable, and stable across scenes. `GlyphLibrary` owns the ID-to-texture mapping.

`tools/process_courier_sheet.gd` divides the generated 4x3 source, trims alpha, applies nearest-neighbor scaling, and places every pose on a shared `64x64` bottom-center canvas.

`tools/process_prop_sheets.gd` performs the equivalent normalization for Watcher states and aperture modules. Both generation-source directories are excluded from Godot imports with `.gdignore`.

## Watcher prompt

```text
Use case: stylized-concept
Asset type: source sprite sheet for a 2D pixel-art game enemy
Input images: Image 1 is the Courier style reference for sprite density and scale language; Image 2 is the relay-station environment reference for brass optical machinery and palette
Primary request: create a fixed mechanical Watcher sentry for Heliograph, an abandoned heliograph relay station; it must look like optical station machinery rather than a soldier
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background, uniform with no shadow, gradient, floor, texture, reflection, or lighting variation
Subject: the exact same compact brass tripod sentry in three states, with a rotating circular mirror-lens head, cyan glass aperture, exposed gears, cable bundle, sturdy pedestal, and one small beacon
Style/medium: crisp hand-authored 2D pixel art matching the referenced Courier, deliberate square pixels, polished 16-bit platformer sprite
Composition/framing: strict 3-column by 1-row sheet with three equally sized isolated full-body frames; frame 1 neutral sweep with amber lens, frame 2 warning with red shutter partially closed, frame 3 firing with bright white-red central aperture; same scale, bottom-center anchor, silhouette, and right-facing orientation in every cell; generous empty chroma padding
Color palette: ink #0B1020, shadow #18233A, twilight #4C3F72, brass #FF8C42, sun #FFD166, signal cyan #7BE0D6, danger #E84A5F, paper #F2E9D8
Constraints: no laser beam or vision cone in the sprite, no text, no labels, no numbers, no watermark, no cast/contact shadow, no #00ff00 in the subject, fully separated frames and image edges
Avoid: humanoid robot, gun turret, military weapon, fantasy creature, photorealism, 3D render, painterly antialiasing
```

## Sunlight-aperture prompt

```text
Use case: stylized-concept
Asset type: source sprite sheet for modular 2D pixel-art environment props
Input images: Image 1 is the relay-station environment style and material reference; Image 2 is the Courier reference for sprite pixel density
Primary request: create three ceiling-mounted heliograph sunlight aperture machines that visually explain the source of authored sunlight zones
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background, completely uniform with no floor, shadow, gradient, reflection, or lighting variation
Subject: three distinct but coherent horizontal brass-and-stone aperture modules: a narrow iris with circular lens, a medium twin-shutter with mirror vanes, and a wide segmented skylight projector with cables and cyan status crystal; each should have a clear downward-facing opening but no painted light beam
Style/medium: crisp hand-authored 2D pixel art, deliberate square pixels, polished 16-bit platformer environment prop, matching the referenced solar-noir observatory
Composition/framing: strict 3-column by 1-row sheet, one isolated front-side-view module per cell, identical top alignment and visual scale, each wider than tall, generous chroma-key padding, no overlap
Color palette: ink #0B1020, shadow #18233A, twilight stone #4C3F72, brass #FF8C42, sun #FFD166, signal cyan #7BE0D6, paper #F2E9D8
Materials/textures: engraved stone housing, riveted brass frame, dark shutter blades, glass lens, short cable tails
Constraints: no light rays or glow extending below the machine, no text, no labels, no watermark, no cast/contact shadow, no #00ff00 in subject, separated from image edges
Avoid: chandeliers, fantasy magic portals, modern lamps, photorealism, 3D render, painterly blur
```
