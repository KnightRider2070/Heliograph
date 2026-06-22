# Heliograph — Audio Production Guide

Everything you need to generate the game's audio in ElevenLabs (voices + sound
effects) and drop it straight into the project. Filenames here are the exact
paths the game will load from, so naming them correctly means zero rework when
we wire them up.

> Voice rule (per design): **the machines only *speak* when hostile.** Dormant
> Watchers and the funny "talk to me" lines stay text-only. ACE and THE ORACLE
> are story narration (optional voice). The Watchers' hostile barks + their
> chatter are the priority.

---

## 0. Conventions

| Thing | Choice |
| --- | --- |
| Short SFX / one-shots | `.wav`, 44.1 kHz, mono |
| Voice lines | `.ogg` (Vorbis), 44.1 kHz, mono |
| Ambience / music loops | `.ogg`, 44.1 kHz, stereo, seamless loop |
| Loudness | normalize voice/SFX to ~ -16 LUFS, ambience ~ -23 LUFS |
| Folder root | `assets/game/audio/` |

ElevenLabs exports MP3. Convert with ffmpeg:

```bash
# voice / ambience -> ogg
ffmpeg -i in.mp3 -ac 1 -ar 44100 -q:a 5 out.ogg
# short sfx -> wav
ffmpeg -i in.mp3 -ac 1 -ar 44100 out.wav
```

Folder layout to create as you fill it:

```
assets/game/audio/
  voice/
    watcher/      # hostile barks + chatter (PRIORITY)
    oracle/       # optional narration voice
    ace/          # optional narration voice
  sfx/            # one-shots
  ambience/       # loops
```

---

## 1. Voices

### 1.1 THE WATCHER — hostile sentries (PRIORITY)

**ElevenLabs → Voice Design** (Text to Voice). Prompt:

> A cold, emotionless autonomous war-machine. Genderless, metallic, ring-modulated
> robotic voice with a harsh electronic timbre, transmitted through a slightly
> damaged speaker. Flat, clipped, staccato military cadence. Menacing, mechanical,
> no warmth. Mid-low pitch.

Preview text to lock the voice: **"Intruder detected. Exterminate. Exterminate."**

Recommended TTS settings: **Stability 75–90%** (keeps the robotic monotone
consistent), **Similarity 80%**, **Style 0–15%**, **Speaker Boost on**, model
`eleven_multilingual_v2`. Generate **2 takes per line** for variety where noted.
Optional post: light bit-crush / ring-mod / short slap-delay for extra "machine".

#### A. Detection barks — played when a Watcher acquires you (warning → fire)

| Line | File | Delivery |
| --- | --- | --- |
| "EXTERMINATE…" | `voice/watcher/bark_exterminate_warn_01.ogg` | drawn-out, rising, charging up |
| "EXTERMINATE!!" | `voice/watcher/bark_exterminate_fire_01.ogg` | sharp, final, on the shot |
| "EXTERMINATE!! EXTERMINATE!!" | `voice/watcher/bark_exterminate_fire_02.ogg` | double, frenzied |
| "Intruder detected." | `voice/watcher/bark_intruder_01.ogg` | flat, certain |
| "Target exposed." | `voice/watcher/bark_target_exposed_01.ogg` | clipped |
| "Courier located." | `voice/watcher/bark_located_01.ogg` | flat |
| "You are in the light. You are seen." | `voice/watcher/bark_seen_01.ogg` | slow, ominous |
| "Signal severed." | `voice/watcher/bark_severed_01.ogg` | cold, on a kill |

#### B. Search / lost-target lines — played when you escape into shadow

| Line | File | Delivery |
| --- | --- | --- |
| "Target lost. Initiate search." | `voice/watcher/search_initiate_01.ogg` | brisk, procedural |
| "Find them. Find the light." | `voice/watcher/search_find_01.ogg` | insistent |
| "It fled to shadow. Shadow is temporary." | `voice/watcher/search_shadow_01.ogg` | patient menace |
| "Where is the courier? Where is the light?" | `voice/watcher/search_where_01.ogg` | scanning |
| "It cannot hide in the dark forever." | `voice/watcher/search_forever_01.ogg` | low, certain |

#### C. Watcher-to-Watcher chatter — ambient, hostile

Render each exchange as **one file** containing both units (put a line break / a
beat between them; if you can, nudge pitch or pan slightly so they read as two
machines). These play occasionally between active Watchers.

| Exchange | File |
| --- | --- |
| — "Unit Six, report." / — "Sweeping. The light has moved again." | `voice/watcher/chatter_report_01.ogg` |
| — "Do you see it?" / — "I see only shadow. Shadow hides the crime." | `voice/watcher/chatter_shadow_01.ogg` |
| — "The Oracle is awake." / — "Then we do not sleep." | `voice/watcher/chatter_oracle_01.ogg` |
| — "It carries our light away." / — "It must not reach the crown." | `voice/watcher/chatter_crown_01.ogg` |
| — "Why does it run?" / — "They always run. They never arrive." | `voice/watcher/chatter_run_01.ogg` |
| — "Exterminate on contact." / — "Confirmed. Exterminate on contact." | `voice/watcher/chatter_confirm_01.ogg` |

#### D. Idle hostile mutters — single Watcher, ambient

| Line | File |
| --- | --- |
| "The light must not move." | `voice/watcher/idle_light_01.ogg` |
| "All apertures: hold the line." | `voice/watcher/idle_hold_01.ogg` |
| "Forty years. We do not tire." | `voice/watcher/idle_tire_01.ogg` |

### 1.2 THE ORACLE — station mind (optional narration voice)

**Voice Design** prompt:

> An ancient, vast machine intelligence speaking as if from everywhere at once.
> Deep, calm, resonant synthetic voice with long reverb tails and a faint detuned
> chorus, as though many voices speak as one. Genderless, melancholic, patient,
> sorrowful. Very slow.

Settings: **Stability 85%**, **Similarity 80%**, **Style 0%**, slow. Record the
Oracle lines from `scripts/core/story_script.gd` (the `THE ORACLE` lines in each
reveal). Suggested files: `voice/oracle/reveal1_*.ogg` … `reveal4_*.ogg`, plus
`voice/oracle/turn_exterminate.ogg` for "EXTERMINATE. EXTERMINATE!"

### 1.3 ACE — handheld companion (optional narration voice)

**Voice Design** prompt:

> A small handheld computer companion. Warm but synthetic, mid-range, clear
> diction with a dry, understated wit and faint digital artifacts on the
> consonants. Calm, reassuring, a little weary.

Settings: **Stability 50–65%**, **Style 20%** (for personality), Speaker Boost
on. Record ACE's lines from `story_script.gd` (intro + the four reveals) as
`voice/ace/intro_01.ogg` … and `voice/ace/reveal1.ogg` …

---

## 2. Sound effects (ElevenLabs → Sound Effects)

Prompt + duration + whether it loops. Keep **Prompt Influence high** for the
mechanical ones.

| Event | File | Prompt | Dur | Loop |
| --- | --- | --- | --- | --- |
| Relay activate | `sfx/relay_activate.wav` | "heavy brass switch thunk followed by a bright electrical surge and a beam of light igniting, sci-fi" | 1.5s | no |
| Sun beam ignites | `sfx/beam_ignite.wav` | "a shaft of sunlight powering on, warm glassy hum swelling up, magical but mechanical" | 1.2s | no |
| Terminal powers on | `sfx/terminal_online.wav` | "old computer terminal booting, rising power hum and a soft confirmation chime" | 1.5s | no |
| Glyph discovered | `sfx/glyph_found.wav` | "single tuned telegraph key click with a short bright resonant ping" | 0.5s | no |
| Cipher solved | `sfx/cipher_solved.wav` | "four-note ascending telegraph signal phrase, hopeful, resolving" | 2s | no |
| Charge fill (in light) | `sfx/charge_fill.wav` | "quiet rising electrical harmonic, energy refilling, gentle" | 1.5s | no |
| Low charge tick | `sfx/low_charge_tick.wav` | "single hollow mechanical tick, warning, sparse" | 0.3s | no |
| Dash | `sfx/dash.wav` | "fast camera-shutter snap with a short whoosh of cut air" | 0.4s | no |
| Jump | `sfx/jump.wav` | "soft mechanical servo hop, light" | 0.3s | no |
| Land | `sfx/land.wav` | "soft metallic footstep landing on stone" | 0.3s | no |
| Checkpoint | `sfx/checkpoint.wav` | "calm two-note confirmation chime, mirror resonance, safe" | 1s | no |
| Watcher acquire | `sfx/watcher_acquire.wav` | "two-stage relay click then a rising 0.3 second alarm tone, threatening" | 1s | no |
| Watcher fire | `sfx/watcher_fire.wav` | "sharp electric beam discharge zap, sci-fi laser, aggressive" | 0.5s | no |
| **The turn** (Watchers go hostile) | `sfx/watchers_hostile_stinger.wav` | "ominous mechanical klaxon snap, power surging through a whole facility, dread stinger" | 2.5s | no |
| Death (cell collapse) | `sfx/death.wav` | "light collapsing inward to a point with a descending power-down whine" | 1.2s | no |
| Win beam fires | `sfx/win_beam.wav` | "an enormous beam of light launching skyward, triumphant whoosh and resonant boom" | 3s | no |
| Dialogue letter blip | `sfx/text_blip.wav` | "very short soft digital typewriter blip, neutral" | 0.08s | no |
| Dialogue advance | `sfx/text_advance.wav` | "soft UI click confirm, digital" | 0.2s | no |
| Menu select | `sfx/ui_select.wav` | "subtle UI tick, brass" | 0.15s | no |
| Menu confirm | `sfx/ui_confirm.wav` | "warm UI confirm chime" | 0.3s | no |

---

## 3. Ambience / music loops

ElevenLabs Sound Effects can make ~10–20s loopable beds (set a longer duration
and ask for "seamless loop").

| Bed | File | Prompt |
| --- | --- | --- |
| Sunlight ambience | `ambience/amb_sunlight.ogg` | "seamless loop, warm electrical hum, distant glass resonance, sparse wind, peaceful but charged" |
| Shadow ambience | `ambience/amb_shadow.ogg` | "seamless loop, low dark room tone, distant relay clicks, muffled, tense, reduced highs" |
| Hostile tension bed | `ambience/amb_hostile.ogg` | "seamless loop, low pulsing menace, mechanical heartbeat, hunting, after the alarm" |
| Title / win theme (optional) | `ambience/music_theme.ogg` | "slow melancholic solar-noir synth theme, brass-like pads, hopeful end, loopable" |

---

## 4. How it plugs into the game (counts & behaviour)

When you have the files, here's how they get used (so you know what's essential):

- **Watcher barks (A):** played on the Watcher's `WARNING` (warn line) and `fired`
  (fire line) states, and on the turn (`watchers_turned_hostile`). Picked at
  random from the pool for variety. → minimum: 1 warn + 1 fire file.
- **Search lines (B):** played when a Watcher drops its target (player reaches
  shadow) and returns to sweeping.
- **Chatter (C) + mutters (D):** an ambient timer on hostile levels plays one
  every ~12–20s from an on-screen Watcher.
- **SFX (2):** hooked to the existing signals — relay activate, beam ignite,
  glyph discovered, cipher solved, dash, death, checkpoint, the turn stinger,
  win beam. These map 1:1 onto code that already emits those events.
- **Ambience (3):** sunlight bed crossfades up with exposure; shadow bed under
  it; hostile bed replaces shadow bed after the turn.

I'll add a small `AudioDirector` autoload + an audio bus layout that loads these
paths and no-ops gracefully for any file not yet present, so you can add audio
incrementally.

---

## 5. Minimum viable set (if you're short on time before the deadline)

Generate these **12** first — they cover 90% of the impact:

1. `bark_exterminate_warn_01.ogg`
2. `bark_exterminate_fire_01.ogg`
3. `bark_intruder_01.ogg`
4. `search_find_01.ogg`
5. `chatter_run_01.ogg`
6. `sfx/relay_activate.wav`
7. `sfx/watchers_hostile_stinger.wav`
8. `sfx/watcher_fire.wav`
9. `sfx/cipher_solved.wav`
10. `sfx/death.wav`
11. `ambience/amb_shadow.ogg`
12. `ambience/amb_hostile.ogg`
