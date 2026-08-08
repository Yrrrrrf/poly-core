# Core (polyglot-core)

The engine at the center of the [polyglot-core](https://github.com/Yrrrrrf/poly-core) framework.

[![GitHub: poly-core](https://img.shields.io/badge/GitHub-poly--core-181717?logo=github)](https://github.com/Yrrrrrf/poly-core/tree/main/crates/core)

**Note: This crate is the hexagon's interior.** It is a simple, language-agnostic engine — deliberately not specialized toward any single output — so it can adapt to whatever code generation a `poly-core` face needs, whether that's a PyO3 extension, a CGo boundary, or a `wasm-bindgen` module (see [`docs/polyglot-lang-map.html`](../../docs/polyglot-lang-map.html) for the interop map this generalizes). It is not meant to be consumed directly by end users; the faces in [`poly-core`](../poly-core) are.

## Overview

`core` is responsible for:

* **Domain logic**: the actual request → response computation, and nothing else.
* **The wire contract**: `serde`-derivable request/response value types shared by every face.

## Rules

* No I/O, no FFI types, no globals, no `unwrap` in library paths.
* No dependency on any face crate (`poly-core`, `poly-core/cli`, `poly-core/wasm`, and later `python`/`go`).
* Stateless and total: input in, output out, every call.

See [`docs/CORE_SPEC_V01.md`](../../docs/CORE_SPEC_V01.md) for the full design rationale.
