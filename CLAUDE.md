# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules
- do NOT write comments unless they are extremely meaningful
- do not exceed 70 lines for any function
- any function can be broken up into N singular functions
and an 'orchestrator' function
- always prefer dependency injection
- always prefer idiomatic Zig code
- YOU SHOULD BE TERRIFIED OF MEMORY LEAKS
- favor readability
- always assert preconditions 

## Zig
- this is zig 0.16. make sure you're using documentation from this version!
- particularly, std.Io was reworked to be an interface as well as a struct that's passed around 

## Project

A hobby ray tracer written in Zig. The scaffolding came from `zig init`; the user has indicated they do not plan to distribute this as a library, so the `ray_tracer` library module (`src/root.zig`) and its test step can eventually be removed in favor of putting everything under the executable's `src/main.zig`.

## Commands

- `zig build` — compile the executable to `zig-out/bin/ray_tracer`
- `zig build run` — build and run; pass program args after `--` (e.g. `zig build run -- arg1 arg2`)
- `zig build test` — run all `test` blocks (currently runs both the lib module tests and the exe module tests in parallel)
- `zig build test --fuzz` — run with the fuzzer (see the `fuzz example` test in `src/main.zig`)
- `zig build --help` — list all build flags and top-level steps
