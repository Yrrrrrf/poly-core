//! `poly-core` — the per-language faces over [`polyglot_core`].
//!
//! `cli`, `wasm`, `python`, `go` land as local sub-crates here as they're
//! built, each a thin adapter over the same engine for their own runtime.
//! This crate's own `lib.rs` is the Rust-native face — one prelude for Rust
//! callers, and the only face that exists so far — see `docs/MANIFEST.md`.

pub mod prelude {
    pub use polyglot_core::*;
}

pub use prelude::*;
