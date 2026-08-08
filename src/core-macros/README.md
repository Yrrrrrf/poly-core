# core-macros

Proc-macros for the [polyglot-core](https://github.com/Yrrrrrf/poly-core) framework.

[![GitHub: poly-core](https://img.shields.io/badge/GitHub-poly--core-181717?logo=github)](https://github.com/Yrrrrrf/poly-core/tree/main/crates/core-macros)

**Note: Kept in its own crate on purpose.** Proc-macros compile as a distinct crate type (`proc-macro = true`) and must never carry domain logic themselves — that stays in [`core`](../core). Splitting them out keeps that boundary impossible to blur by accident.

## Overview

`core-macros` is responsible for:

* **Codegen helpers**: attribute/derive macros that reduce boilerplate when wiring a `core` function into one of `poly-core`'s per-language faces (`cli`, `wasm`, and later `python`, `go`).

## Current

* `#[port]` — marks a function as a port a face can call. Currently a passthrough; the seed for real face codegen, not a working generator yet (see [`docs/CORE_SPEC_V01.md`](../../docs/CORE_SPEC_V01.md) §3).

Not depended on by anything yet — wired in only once a second real use for the codegen appears, per the project's "not speculative" rule in [`docs/MANIFEST.md`](../../docs/MANIFEST.md).
