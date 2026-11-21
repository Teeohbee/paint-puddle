# Paint Puddle

A gentle game for a young player who loves letters, numbers, rainbows and
colour mixing, and is still getting the hang of a controller. Drive a paint
blob around a meadow, mix colours, spell words and hop through the hills.

Everything you see and hear is drawn or generated in code. Built with Godot 4.7.

## Controls

| | Controller | Keyboard |
|---|---|---|
| Move | D-pad or left stick | Arrow keys or WASD |
| Jump / pick | Any face button | Space or Enter |
| Pause | Menu (Start) | Escape |

## Rainbow Hills difficulty

Hills asks Easy or Medium first. Medium opens once all 40 Easy levels are
finished (or early with "Open Medium" in the grown-up settings: hold all four
face buttons, or G, on the Options screen). Each difficulty keeps its own
progress.

Medium uses the same 40 layouts, made harder:

- Gaps are a quarter wider, so the widest needs a held jump from near the edge.
- Every other letter floats above the paint pots and needs a held jump.
  Swaying letters need a hop in levels 1-20, and a held jump from level 21.
  The first letter is always walked through.
- Rocks, logs and snowballs stand in the way and bump you back.

A level can set an optional `word_medium` in `hills/hills_levels.gd`, for
example `"word": "SUN", "word_medium": "SUNSHINE"`. Without one, Medium spells
the Easy word. Pots and paint are shared.

## Clock mode

Clock mode teaches reading and setting an analogue clock, to five minutes,
with single minutes as a stretch. The clock is on the left and the blob
household's doll's house is on the right, and the house shows what's
happening at that time of a real 24-hour day.

- **Set cards** ("Bath time - make it half past 6 in the evening"): wind the hands
  with left and right (hold to speed up), then press A. The half of the day
  counts. A wrong time plays its own moment, then the card asks again.
- **Read cards** ("What time is it?"): the clock winds itself to a time;
  pick one of three answers under it.
- **Eight rungs**, in the order schools teach them: o'clock, half past, both
  hands, quarter past, quarter to, 5 past, 5 to, minutes. Getting through a
  rung's deck once opens the next rung and a tricky clock face. Rung 8 is
  tap for a minute, hold for fives.
- **Tricky clocks**: once a rung is cleared, the Tricky tile on the Clock
  menu replays cleared rungs with a random unlocked face on every card.

"Open everything" in the grown-up settings opens every rung and face without
changing how far the player has climbed. The Clock part of Reset clears the
climb and never the setting. Moments of the day live in
`data/clock_moments.json`; the words for Clock mode are in `GLOSSARY.md`.

## Write

Write teaches letter formation the way school does (Read Write Inc. Set 1):
one big dotted lowercase letter on the meadow grass, with its rhyme on a card
("Maisie, mountain, mountain"). Drive the blob along the dots to paint them,
in order, from the green start dot. t, i, j, f and x have a pen lift: the
next stroke's start dot shows once the first is done. Steering round curves
is the point - good practice for the stick - but every letter can be done on
the D-pad (a slow test proves it).

- Letters come in school order: m a s d t i n p g o c k u b f e l h r j v y w z x q.
  Each opens once the one before it is traced, or all of them with "Open
  everything" in the grown-up settings.
- Reset has a Write part. Letters live in `tracing/tracing_letters.gd`.

Splat is archived: it has no tile, but its code and tests stay, to be
reworked.

## Tests

Tests use [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4), installed by
[gd-plug](https://github.com/imjp94/gd-plug) from `plug.gd`. Addons aren't
committed, so after cloning:

```sh
godot --headless -s plug.gd install
tests/run.sh          # fast suites, then the slow Hills playthroughs
tests/run.sh fast     # or slow, or one suite: res://tests/fast/test_mixing.gd
```

It stops at the first failure; `CONTINUE=1 tests/run.sh` runs everything.
`tests/fast/` is for anything quick; whole-level playthroughs go in
`tests/slow/`. Suites that touch the autoloads or screens extend `GameSuite`
(`tests/game_suite.gd`), which gives every test a fresh save and session.
Reports go to `reports/`.
