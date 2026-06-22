---
layout: home

hero:
  name: Heliograph
  text: Bank the light. Break the code.
  tagline: A compact 2D platformer where sunlight is fuel, exposure is danger, and every shadow is running out of time.
  actions:
    - theme: brand
      text: Read the game design
      link: /game-design
    - theme: alt
      text: Review the architecture
      link: /architecture

features:
  - title: Light is fuel
    details: Sunlight refills the same charge meter that powers the dash and keeps the player alive.
  - title: Light is exposure
    details: Bright areas reveal routes and clues, but make the player visible to active sentries.
  - title: Code is progression
    details: Light-only glyph mappings feed a substitution cipher solved at the final terminal.
---

## Project status

Heliograph is a **complete jam build**. A fresh launch opens the title screen and
plays end to end through **four levels** — First Signal, Prism Foundry, Lunar
Archive, Crown of Dawn — to the win screen and the relay-chain hook.

On top of the original light/shadow/charge/cipher loop, the build now adds:

- a **narrative layer** — ACE and THE ORACLE, told through a cinematic comm panel,
  with a Turing/halting-problem spine (see [Story](/story));
- the **light-relay** mechanic — carry the light forward through prisms to wake
  dark sun zones and power the exit;
- Watchers that begin **dormant** and turn hostile (screaming *EXTERMINATE*) after
  the first fragment is finished;
- a full **audio system** — SFX, Watcher voices, and crossfading ambience
  (see [Audio Production](/audio-production));
- **editable level scenes** — levels 2–4 are now hand-authorable in the 2D editor
  (see [Editing Levels](/level-editing)).

## Source of truth

| Document                                            | Owns                                                                             |
| --------------------------------------------------- | -------------------------------------------------------------------------------- |
| [Game Design](/game-design)                         | Player experience, rules, tuning baseline, progression, and scope                |
| [Story and Narrative](/story)                       | ACE, the Oracle, the Watchers' turn, the Turing hook, per-level beats            |
| [Editing Levels](/level-editing)                    | The level scene anatomy and how to author new rooms                              |
| [Audio Production](/audio-production)               | Voice lines, SFX/ambience prompts, file paths, and event hooks                   |
| [Theme and Art Direction](/theme-and-art-direction) | Setting, visual language, palette, UI, audio, and asset budget                   |
| [Asset Reuse Plan](/asset-plan)                     | Exact Kenney sources, atlas IDs, project targets, exclusions, and missing assets |
| [Jam Level Design](/level-design)                   | Spatial metrics, room beats, encounters, cipher content, and level cuts          |
| [Technical Architecture](/architecture)             | Scene boundaries, state ownership, signals, data flow, and tests                 |
| [Physics and Engine Systems](/physics-and-engine)   | Movement math, project settings, player states, and required GDScript            |
| [Development Guide](/development)                   | Local setup, input map, conventions, and validation commands                     |

When documents conflict, player-facing rules belong in **Game Design**, spatial encounters belong in **Jam Level Design**, asset selection belongs in **Asset Reuse Plan**, and implementation contracts belong in **Technical Architecture** or **Physics and Engine Systems**.
