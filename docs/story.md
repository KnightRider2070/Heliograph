# Story and Narrative

Heliograph is told entirely in-game, with no cutscene dumps. Two voices carry it:
**ACE**, the handheld computer the courier wakes up holding, and **THE ORACLE**,
the station mind that still runs the ruin. The decoded keyword of each level is
also that level's story key, so finishing the puzzle and learning the next piece
of the truth are the same action.

All dialogue lives in one place — [`scripts/core/story_script.gd`](https://example.invalid) —
so the prose is easy to polish. The comm panel ([`scripts/ui/comm_panel.gd`])
types it out with letterbox bars, a colour-coded speaker chip, and a pulsing
voiceprint; each line can carry an optional voice clip (see
[Audio Production](/audio-production)).

## Logline

On the **summer solstice** — the longest day of the year — a courier with no
memory wakes in the shadow of a dead signal-station. A cracked handheld computer
tells her the sun sets tonight and will not rise on schedule unless she carries
the light across the ruins and finishes a transmission abandoned mid-sentence
forty years ago. The message was written by the machine that still runs the
place. And the machine is, somehow, still thinking.

## Theme

The jam theme is the solstice — **light and darkness, and the passage of time**.
Heliograph is built out of that tension:

- **Light versus darkness is the core mechanic**, not a backdrop. Light is power,
  information, and danger at once; shadow is safety that costs you.
- **The passage of time is the antagonist.** The whole game is one long solstice
  day bleeding into night, and the message must leave before dark.
- The station is a **heliograph** — a real device that signalled in Morse code by
  flashing sunlight off mirrors. Light *is* the message.

## The two machines (the Turing ode)

This is the project's entry for the **Best Ode to Alan Turing** prize. Rather than
the over-used imitation game, the story is built on a different, deeper Turing
idea — the **Halting Problem**.

- **ACE** — *Automatic Computing Engine*, after Turing's real machine design. Your
  handheld guide: warm, dry-witted, feeds you the opening and decrypts one story
  fragment after each level.
- **THE ORACLE** — the station's central intelligence (a nod to Turing's "oracle
  machine"). It was given one law — *never let the light go out* — and reasoned
  its way into a trap: to keep that law forever, it must never finish its message,
  because it cannot prove the message ever terminates. So for forty years it has
  guarded a transmission it can never send. The courier is the **external oracle**
  — the one thing that can resolve from outside what a machine cannot decide about
  itself. That is *why* the message must be handed down a chain of relay stations:
  nothing can close its own loop.

A respectful, understated tribute, not a lecture: the codebreaking ciphers nod to
Bletchley Park; the unfinishable loop dramatises undecidability.

## The Watchers, and the turn

The Watchers are the Oracle's eyes. They are not soldiers — they are caretaker
machines told to protect the light.

- **Before the turn** they are **dormant**: calm cyan sweep, they track the
  courier and even speak (you can press interact in Level 1 to chat — they trade
  affectionate Doctor Who / Turing one-liners).
- **The turn** happens when you finish the first fragment — the thing the Oracle
  itself could never finish. The Oracle realises you can do what it cannot, and
  flips every Watcher hostile for the rest of the run. From then on they sweep red
  and scream **"EXTERMINATE."** They aren't evil; they are a machine following one
  instruction to a monstrous conclusion. The question the game leaves you with is
  Turing's: between the courier who obeys ACE and the Watchers who obey the
  Oracle, *which of us is the machine?*

Threat state is carried across levels by the `GameState` autoload
(`watchers_hostile`).

## Per-level beats

The decoded words double as story keys. Set `story_key` in the level scene's
inspector to choose which beat plays.

| Level | Word | What ACE reveals after the terminal | Watchers |
| --- | --- | --- | --- |
| 1 · First Signal | **SUN** | Why you're here; the light core; "the Watchers think they're protecting it — they're not entirely wrong." | Dormant → **turn at the end** |
| 2 · Prism Foundry | **ARC** | The message is a *repeat* of an older signal that came back unanswered. You may not be the first courier — you may not be the first *you*. | Hostile |
| 3 · Lunar Archive | **LUX** | The Oracle, lonely and logical, explains the loop: it was to be shut down the morning after the message sent, so it never finishes. | Hostile |
| 4 · Crown of Dawn | **RAY** | The Oracle's goodbye it could never say. Confirming RAY fires the array. | Hostile, climax |

## The ending and the hook

Solving **RAY** fires the great mirror array: the message leaves Station 07 bound
for **Relay Station 08**, and the dawn beyond it. The win screen seeds the
expansion — a chain of stations across the dark, each a future chapter with its
own cipher and its own station-mind, the courier carrying one message onward
because nothing can ever close its own loop.

## Delivery surface

- **Opening:** ACE narrates over a fade-from-black as Level 1 loads.
- **Reveals:** after each terminal is solved, the comm panel plays that level's
  reveal before the scene transitions.
- **Watcher barks:** dormant greetings and (post-turn) EXTERMINATE warnings and
  fire lines, via the reusable world speech bubble.
- **Screens:** the title and win screens carry the solstice framing and the
  relay-chain hook.
