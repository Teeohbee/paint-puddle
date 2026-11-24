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

## Meadow difficulty

The Meadow asks Easy or Medium first, like the Hills. Medium opens once Easy
has dealt every card once (`tasks_completed` reaches the Easy pack's size), or
early with "Open Medium", which opens both places' Medium.

Medium has its own cards in `data/tasks_medium.json`, not the Easy ones made
harder. Each difficulty keeps its own shuffled deck and next card in the save
(`task_deck` and `next_task_index`, `medium_task_deck` and
`next_task_index_medium`). The red paint then wash lesson is Easy's first two
cards only. Resetting the Meadow resets both.

Medium's pack: harder words, mostly without a picture (a few new pictures as
treats, which join the Book after Easy's), bigger sums with close choices,
colour riddles with no recipe ("Make the colour of a frog"), and fewer
rainbows. A rainbow card with `"in_order": true` is painted red first: a pot
out of turn wobbles and stays empty.

Medium has no magnet: letting go near a puddle, pot or the fountain leaves the
blob where it stopped (`MeadowBlob.uses_magnet`).

In Medium every letter rides a butterfly, flying a figure of eight round where
it was put down (`LetterFlight`, speed 0.5). Numbers and paint drops stay put.
Letters start on `TaskRunner.FLYING_SPOTS`, ten spots found by search
(`.tmp_test/probe_flying_spots.gd`) where a loop keeps clear of the rainbow's
arch, its pots and their names, the puddles, the fountain and the bushes. The
meadow is crowded, so loops are 30 to 75 rather than the prototype's 90; a loop
is fitted to its spot, lying down or upright, and shrinks rather than cross
anything. If the layout changes, rerun the probe: a test checks every flying
spot still has room.

## Clock mode

Clock mode teaches reading and setting an analogue clock the way UK Year 1
does: o'clock, then half past, with the hour hand on its own, before the
minute hand joins. The clock is on the left and the blob household's doll's
house is on the right, showing what's happening at that time of a real
24-hour day. A word under the clock says the part of the day (morning,
afternoon, evening, night); there's no am/pm anywhere.

Time only goes forward: right winds on (hold to speed up), and left does
nothing.

- **Play with the clock**: the big tile on the Clock menu. No cards, no
  wrong: right or A winds the day on and the house acts it out. It opens
  every time with a short intro (skippable with any button) where a 0-12
  number line's numbers hop round into the face.
- **Rungs**: o'clock, half past, then both hands. Only rung 1 is built so
  far; the rest say "Coming soon". The first time a rung opens, the blob
  shows its idea and then he copies it with ghost hands showing.
- **Set cards** ("Wind it to 8 o'clock", with the moment - "Breakfast" - underneath; orange ring and arrow round the clock) ask for the next time the
  face shows that time. **Read cards** ("Look! What time is it?", blue ring) wind the clock
  on by themselves and offer three answers.
- **Wrong is gentle but clear**: a soft boing, the clock's blob shakes its
  head, a wrong answer greys out where it is, and the house stays put. Help
  comes one step per miss: the number glows, then ghost hands, then the
  words. Right gets a chime, a cheer and, first time, a star.
- **Moving up** takes 5 cards right first time in a row, on two different
  days. A miss, or an answer after help, breaks the run.

"Open everything" in the grown-up settings opens every built rung without
changing how far the player has climbed. The Clock part of Reset clears the
climb, the run and the intros seen, never the setting. Tricky clock faces
and rungs 4-8 are kept in the code but parked. Moments of the day live in
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

## Birthdays

The title screen throws a party on a birthday. The name and date of birth
live in `user://birthday.json` on the machine that plays the game (on Linux,
`~/.local/share/godot/app_userdata/Paint Puddle/birthday.json`), never in
this repo:

```json
{"name": "Sam", "born": "2021-03-14"}
```

On the day: "Happy 6th birthday, Sam!", party hats, bunting, balloons with
the age on and confetti. For the six days after: "Sam's birthday week!", with
hats, bunting and the odd balloon. No file means no party.

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
