# Glossary

Words the code and the planning use, so they mean one thing each.

## Meadow

**Card**: one Meadow task, such as "Spell CAT" or "Make orange". Easy's are in `data/tasks.json`, Medium's in `data/tasks_medium.json`. Avoid: level.

**Meadow deck**: the shuffled cards still to come this round, one per difficulty. Every card comes up once before any comes round again.

**Flying letter**: in Medium, a letter stone carried by a butterfly round a figure of eight (its *loop*). Numbers and drops never fly.

**Evening Meadow**: Medium's look and tune. Avoid: night mode.

**Open Medium**: a grown-up setting that opens Medium in both the Hills and the Meadow. Saved as `open_hills_medium`, its name from before the Meadow had a Medium.

## Clock mode

**Rung**: one step of the Clock mode ladder, such as "quarter past". It has its own deck of tasks and its own step size. Not to be confused with a Hills *level*.

**Deck**: the shuffled tasks for one rung, eight to a session. Finishing it doesn't open the next rung; the *first-try run* does.

**Set task**: a card gives a time and the player winds the hands on to match it. Its *target* is the next time the face shows that time.

**Read task**: the clock shows a time and the player picks the matching answer.

**Target**: the 24-hour time a card is about: the next time, winding forward, that the face shows the card's time. The house's moment and the card's words come from it.

**Step**: how far one press winds the clock on the current rung (an hour, half an hour, a quarter or five minutes).

**Hour hand** (on screen "little hour hand" on rungs 1-3): the short hand. It always creeps with the minute hand. Avoid: "little hand" on its own.

**Minute hand** (on screen "big minute hand" on rungs 1-3): the long hand. It isn't drawn on rungs 1-2. Avoid: "big hand" on its own.

**Moment**: what the blobs in the house are doing at a given time, named at anchor times through all 24 hours (breakfast at half past 7 in the morning, an owl at 9 pm). A moment can start on the hour or part way through it. Avoid: scene, event.

**Free play** (on screen "Play with the clock"): the Clock menu's big tile. No cards and nothing wrong; winding moves the house's day on. Uses the climbing rung's hands and step. Avoid: sandbox, practice.

**Number-line intro**: free play's opening, every visit: a 1-12 number line whose numbers hop round into the face, then the hour hand ticks to 7 in the morning. Any button skips it. Then the wind ring, a cheer, a chime and "Your turn - wind the clock!" (gone on the first wind).

**Rung intro**: the first time a rung opens, the blob shows its idea ("Watch!") and then the player copies it ("Your turn") with ghost hands. Saved as `clock_rung_intros_seen`; the copy never counts towards moving up.

**Help steps**: one per miss on the same card: the number glows, then ghost hands (see-through hands at the target, set cards only), then the explanation in words.

**First-try run**: cards right with no miss in a row on the climbing rung. A run of 5 on one day, then another on a later day, clears the rung. Saved as `clock_first_try_run` and `clock_run_day`. Avoid: streak, score.

**Star**: one per card right first time in a session, on the banner. Stars aren't saved.

**Coming soon**: a rung not rebuilt yet: locked, faded, no padlock.

**Tricky face** (parked: no Tricky tile for now): one of eight harder faces (four numbers, kitchen clock, square, puddle, marks only, twin hands, wristwatch, bare). Each rung cleared unlocks the next one. Avoid: tricky clock, tricky level.

**Tricky replay**: replaying a cleared rung where each card deals a random unlocked tricky face. Only the face changes. Avoid: tricky rung, hard mode.

**House**: the blob household's home beside the clock. Its sky, light and blobs show the moment the clock is set to. Avoid: "day scene", "scene".

**Day**: the house's full 24 hours. The clock winds continuously through it, so one lap of the face is half a day.

**Part of the day**: morning (6 am to 12), afternoon (12-5), evening (5-8) or night (8 pm to 6 am). The big word under the clock, following the hands. No card asks about it and am/pm isn't shown (it's Year 3).

**Rungs cleared**: how far the player has climbed the ladder, as a count. It decides which rungs and tricky faces are open. Avoid: level, progress.

**Climbing rung**: the lowest rung not yet cleared, the only one whose deck keeps its place between visits.

**Open everything**: a grown-up setting that opens every Clock rung and tricky face, and every Write letter, while it's on, without changing rungs cleared or letters traced. Saved as `open_all_clock_rungs`, its name from before Write.

## Write (tracing)

Write is the mode's name on the menus; the code calls it tracing.

**Stroke**: one continuous line of a letter, pen down to pen up, painted dot by dot from its start. Most letters are one stroke; t, i, j, f and x are two.

**Pen lift**: the move between two strokes. Nothing to paint; the next stroke's start dot shows once the last stroke is done.

**Reach**: how close the blob has to come to a dot to paint it.

**Rhyme**: the school phrase that goes with a letter, such as "Maisie, mountain, mountain" for m (Read Write Inc. Set 1).
