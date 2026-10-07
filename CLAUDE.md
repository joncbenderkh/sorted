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
- Algorithms label what they are doing with `_set_phase(text)`; every
  recorded `SortStep` carries that as `note`, which guided mode shows as the
  goal. `SortStep.describe()` phrases a move for the Hint button.
- `scripts/play/`: `DragMove` maps a drag between cells to a `SortStep`;
  `PlaySession` applies the player's moves (free play, or guided along an
  algorithm's own moves), counts them against par and explains refusals.
  A run ends as soon as the array is sorted, so par can be beaten.
- `scripts/ui/`: `SortBoard` draws a state and handles dragging;
  `visualizer.gd` has Watch, Free play and Guided modes.

Headless Godot drops simulated mouse input before it reaches controls, so
gdUnit4 UI tests feed `SortBoard._gui_input` directly instead of using the
scene runner's mouse simulation.

GUT prints only a warning and exits 0 when a test script fails to parse, so
check that the script count in the run summary matches the files in `tests/gut/`.

## Versioning

`0.1.0` lives in `project.godot` (`config/version`) and `scripts/version.gd`;
keep them in sync. Release = tag `v<version>`; `release.yml` refuses a tag that
does not match `project.godot`.

## Status

Exists: Godot project, CI, desktop release workflow (unsigned; macOS not
notarized), four sorting algorithms (`scripts/sorting/`), a bar visualizer
(`scenes/visualizer.tscn`), and player moves by drag and drop in free play
(score is moves vs par) and guided modes.

Not yet done: Android export preset and signed AAB/APK release (needs a
keystore and secrets from the user, never generated unprompted); levels
(sort type and cache size as difficulty); a merge sort that adapts to a cache
smaller than n/2; undo.
