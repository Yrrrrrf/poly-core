//! `core-macros` — proc-macros for polyglot-core.
//!
//! Kept in their own crate on purpose: proc-macros compile as a separate
//! crate type and must never carry domain logic — that stays in `core`.

use proc_macro::TokenStream;
use quote::quote;
use syn::{ItemFn, parse_macro_input};

/// Marks a `core` function as a port a surface can call.
///
/// Currently a passthrough — the seed for future surface codegen
/// (see `docs/CORE_SPEC_V01.md` §3), not a working generator yet.
#[proc_macro_attribute]
pub fn port(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let input = parse_macro_input!(item as ItemFn);
    quote! { #input }.into()
}
