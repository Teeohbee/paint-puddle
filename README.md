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

Medium uses the same 40 layouts. A level can set an optional `word_medium` in
`hills/hills_levels.gd`, for example `"word": "SUN", "word_medium": "SUNSHINE"`.
Without one, Medium spells the Easy word. Pots and paint are shared.

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
