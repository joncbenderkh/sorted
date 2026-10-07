# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Sorted** is a puzzle game built around sorting algorithms. Early versions
provide visualizations similar to https://sortvisualizer.com/heapsort/; the
game layer is built on top of them later.

Core mechanic: a **cache** area where the player temporarily stores elements
during a sort. Level difficulty is determined by the **cache size** and the
**sort type** (e.g. heapsort, quicksort, merge sort).

## Decisions

- **Engine:** Godot 4
- **Language:** GDScript
- **License:** GPL-3.0 (`LICENSE`)
- **Platforms:** Android and desktop (Linux/Windows/macOS); UI must work with touch and mouse
- **Repo:** github.com/joncbenderkh/sorted (public; `main` is protected, work lands via PR)

## Architecture intent

- Keep sorting algorithms as pure logic, separate from rendering: each algorithm
  emits a sequence of steps (compare, swap, cache store/load) that the
  visualizer and the game layer both consume. This makes algorithms testable
  without the engine and lets a human player replace the algorithm's own moves.
- The cache is a first-class part of the step model, not a UI-only feature.

## Commands

Godot 4.7.2 (pinned in `ci.yml` and `release.yml`); gdtoolkit 4.x for lint.

- Import / parse check: `godot --headless --import`
- Smoke run: `godot --headless --quit-after 5`
- Lint: `gdlint scripts tests`
- Format check: `gdformat --check scripts tests`
- GUT tests (`tests/gut/`): `godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`
- gdUnit4 tests (`tests/gdunit/`): `godot --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/gdunit --ignoreHeadlessMode`

Both frameworks are vendored under `addons/` (GUT 9.7.1, gdUnit4 6.2.1) and
are never linted or formatted. Pure algorithm logic goes in GUT; scene and
input (touch/mouse) tests go in gdUnit4, whose scene runner simulates input.

## Code layout

- `scripts/sorting/`: pure logic. `SortStep` (compare/swap/store/load/move on
  locations; negative = cache slot), `SortState` (validates every step,
  including cache limits), `SortAlgorithm` base class and its subclasses.
  An algorithm runs against a `SortState` and returns its recorded steps.
- `scripts/ui/`: `SortBoard` draws a state; `visualizer.gd` replays steps.

GUT prints only a warning and exits 0 when a test script fails to parse, so
check that the script count in the run summary matches the files in `tests/gut/`.

## Versioning

`0.1.0` lives in `project.godot` (`config/version`) and `scripts/version.gd`;
keep them in sync. Release = tag `v<version>`; `release.yml` refuses a tag that
does not match `project.godot`.

## Status

Scaffolded: Godot project, placeholder main scene, CI, desktop release
workflow (unsigned; macOS not notarized). Not yet done: Android export preset
and signed AAB/APK release, which need a keystore and secrets from the user
(never generated unprompted); heapsort and insertion sort exist (`scripts/sorting/`) with a bar visualizer (`scenes/visualizer.tscn`); the game layer, more algorithms (merge sort, quicksort) and player-driven cache moves do not.
