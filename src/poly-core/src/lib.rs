//! `poly-core` — the per-language faces over [`polyglot_core`].
//!
//! `cli` and `wasm` (and later `python`, `go`) live as local sub-crates here,
//! each a thin adapter over the same engine for their own runtime. This
//! crate's own `lib.rs` is the Rust-native face — one prelude for Rust
//! callers — see `docs/MANIFEST.md`.

pub mod prelude {
    pub use polyglot_core::*;
}

pub use prelude::*;
