<h1 align="center">
  <div align="center">polyglot-core</div>
</h1>

<div align="center">

[![GitHub: Repo](https://img.shields.io/badge/github-Yrrrrrf%2Fpoly--core-58A6FF?&logo=github)](https://github.com/Yrrrrrf/poly-core)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](./LICENSE)

</div>

> One logic. A thousand faces.

`polyglot-core` writes the hard logic once, in Rust, and gives every language a thin face over it. There is exactly one place logic lives — the core. Everything else is a mechanical wrapper: take input, hand it to the core, hand the answer back. A wrapper that contains a decision is a bug, not a feature.

## 🚦 Getting Started

### Build the workspace

```bash
cargo build
```

### Run the CLI floor

```bash
cargo run --bin polycore
```

### Use it as a Rust library

```rust
use poly_core::prelude::*;
```

## Three pieces

- **[`core`](./crates/core)** — the engine. A simple, language-agnostic core that adapts to whatever code generation a face needs (see [`docs/polyglot-lang-map.html`](./docs/polyglot-lang-map.html) for the interop map this generalizes). No I/O, no FFI, no state.
- **[`poly-core`](./crates/poly-core)** — the faces. Each language's implementation lives here as a local sub-crate (`cli` for any subprocess-capable language, `wasm` for the browser, `python`/`go` later) — plus its own `lib.rs` as the Rust-native face.
- **[`core-macros`](./crates/core-macros)** — the macros. Proc-macro codegen helpers, kept in their own crate so they can never smuggle domain logic in with them.

## Directory Structure

```
poly-core/
├── README.md
├── LICENSE
├── Cargo.toml               # workspace manifest
├── docs/
│   ├── MANIFEST.md          # the why
│   ├── CORE_SPEC_V01.md     # the how (full design + phased plan)
│   └── polyglot-lang-map.html
└── crates/
    ├── core/                 # the engine — language-agnostic, adapts to any codegen
    │   ├── README.md
    │   ├── Cargo.toml
    │   └── src/
    │       └── lib.rs
    ├── core-macros/          # proc-macros — kept separate from domain logic on purpose
    │   ├── README.md
    │   ├── Cargo.toml
    │   └── src/
    │       └── lib.rs
    └── poly-core/            # the faces — one local sub-crate per language
        ├── README.md
        ├── Cargo.toml
        ├── src/
        │   └── lib.rs        # the Rust-native face (prelude)
        ├── cli/               # any language, via subprocess
        │   ├── README.md
        │   ├── Cargo.toml
        │   └── src/
        │       └── main.rs
        └── wasm/              # the web/browser face
            ├── README.md
            ├── Cargo.toml
            └── src/
                └── lib.rs
```

## Crates

| Crate | Responsibility | Consumes |
|---|---|---|
| [`core`](./crates/core) | The engine — all domain logic, as pure functions over a shared wire contract. | Nothing in this repo. |
| [`poly-core`](./crates/poly-core) | The Rust-native face (prelude) + the home for every other language's face. | `core` |
| [`poly-core/cli`](./crates/poly-core/cli) | Expose `core` as a subprocess-invokable binary, for any language. | `core` |
| [`poly-core/wasm`](./crates/poly-core/wasm) | Expose `core` to the browser via `wasm-bindgen`. | `core` |
| [`core-macros`](./crates/core-macros) | Proc-macro codegen helpers, kept separate from logic. | Nothing yet — not wired into any face. |

## Features

### Current
- [x] Workspace scaffold: `core`, `core-macros`, `poly-core` (with `cli` and `wasm` as local faces)
- [x] A minimal, deliberately trivial core (proves the delivery machinery first)
- [x] Macros kept in their own crate, unused until a real codegen need appears

### Planned
- [ ] Wire contract (shared `serde` request/response types)
- [ ] `clap`-based CLI adapter (`--json` output)
- [ ] `wasm-bindgen` adapter consumed by [`glyph`](https://github.com/Yrrrrrf)
- [ ] Parity vectors (`vectors/`) replayed against every face
- [ ] `poly-core/python` (PyO3) and `poly-core/go` (UniFFI/CGo) faces
- [ ] Port glyph's real lex → parse → analyze → encode pipeline into `core`

See [`docs/MANIFEST.md`](./docs/MANIFEST.md) for the why, and [`docs/CORE_SPEC_V01.md`](./docs/CORE_SPEC_V01.md) for the full design and phased plan.

## 📄 License

This project is licensed under the [**MIT License**](./LICENSE).
