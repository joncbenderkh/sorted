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

## Status

Not yet scaffolded: no Godot project, CI, or export presets exist. Scaffolding
follows the `new-project` skill, in a session opened in this directory.
