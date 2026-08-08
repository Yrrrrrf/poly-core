# poly-core

The per-language faces of the [polyglot-core](https://github.com/Yrrrrrf/poly-core) framework.

[![GitHub: poly-core](https://img.shields.io/badge/GitHub-poly--core-181717?logo=github)](https://github.com/Yrrrrrf/poly-core/tree/main/src/poly-core)

Where [`core`](../core) is the single, language-agnostic engine, `poly-core` is where each language actually gets implemented — one local sub-crate per face, each a thin, mechanical adapter over the same `core` logic.

## Local sub-crates

| Sub-crate | Language / runtime | Bridge | Status |
|---|---|---|---|
| this crate's own `src/lib.rs` | Rust | direct `prelude` | built |
| `cli` | Any language, via subprocess | plain stdin/stdout | planned |
| `wasm` | Web / browser | `wasm-bindgen` | planned |
| `python` | Python | PyO3 / Maturin | planned |
| `go` | Go | UniFFI / CGo | planned |

This crate's own `src/lib.rs` is the Rust-native face: a `prelude` a Rust consumer depends on directly. It's the only face that exists right now — the others land as local sub-crates here as they're built.

## Usage

```rust
use poly_core::prelude::*;
```

## Overview

`poly-core` is responsible for:

* **The public prelude**: one `use` statement that surfaces everything a Rust caller needs from `core`.
* **Housing the per-language faces** as local sub-crates, so a new language is one folder added here, never a change to `core`.
* **Nothing else.** No logic of its own — see [`docs/MANIFEST.md`](../../docs/MANIFEST.md): "a wrapper that contains a decision is a bug, not a feature."

[`core-macros`](../core-macros) stays independent and is not pulled in here yet — it gets wired in behind a feature flag only once codegen across these faces is real, not speculative.
