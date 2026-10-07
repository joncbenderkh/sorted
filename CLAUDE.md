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

Godot 4.4.1 (pinned in `ci.yml` and `release.yml`); gdtoolkit 4.x for lint.

- Import / parse check: `godot --headless --import`
- Smoke run: `godot --headless --quit-after 5`
- Lint: `gdlint scripts`
- Format check: `gdformat --check scripts`
- Tests: none yet; add GUT or gdUnit4 with the first algorithm and wire it into CI.

## Versioning

`0.1.0` lives in `project.godot` (`config/version`) and `scripts/version.gd`;
keep them in sync. Release = tag `v<version>`; `release.yml` refuses a tag that
does not match `project.godot`.

## Status

Scaffolded: Godot project, placeholder main scene, CI, desktop release
workflow (unsigned; macOS not notarized). Not yet done: Android export preset
and signed AAB/APK release, which need a keystore and secrets from the user
(never generated unprompted); tests; any sorting logic.
