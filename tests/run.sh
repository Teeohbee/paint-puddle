#!/usr/bin/env bash
# Runs the gdUnit4 suites headless, failing fast: gdUnit stops at the first failing test.
#   tests/run.sh          fast suites, then the slow Hills playthroughs if those passed
#   tests/run.sh fast     just tests/fast
#   tests/run.sh slow     just tests/slow
#   tests/run.sh res://tests/fast/test_mixing.gd   one suite (or folder)
# Set CONTINUE=1 to run everything and see every failure instead of stopping at the first.
# Each run gets a throwaway HOME, which on macOS and Linux moves Godot's user://, so tests never touch the
# real save.json. --fixed-fps 60 makes every frame 1/60s of game time however fast the machine is.
cd "$(dirname "$0")/.." || exit 1
if [ ! -d addons/gdUnit4 ]; then
	echo "gdUnit4 isn't installed. Run: godot --headless -s plug.gd install" >&2
	exit 1
fi

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
# HOME moves user:// but also the editor settings, so import with the real HOME: it only reads res://
godot --headless --path . --import >/dev/null 2>&1

run() {  # $1 suite or folder
	echo "== $1"
	HOME="$home" godot --headless --fixed-fps 60 --path . -s -d --remote-debug tcp://127.0.0.1:0 \
		res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a "$1" ${CONTINUE:+-c} --ignoreHeadlessMode -rc 1
}

case "${1:-all}" in
	all) run res://tests/fast && { ls tests/slow/*.gd >/dev/null 2>&1 || exit 0; run res://tests/slow; } ;;
	fast) run res://tests/fast ;;
	slow) run res://tests/slow ;;
	*) run "$1" ;;
esac
