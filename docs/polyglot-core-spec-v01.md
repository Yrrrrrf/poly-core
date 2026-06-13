# polyglot-core — Foundation Spec (v0.1)

> Working name: `polyglot-core` / `polycore`.
> Codename candidate to sit beside Azathoth and Yog-Sothoth: **Nyarlathotep** —
> the messenger with a thousand forms who carries one will into many places.
> One core, many language faces. _[ASSUMPTION — placeholder, override freely.]_

> This document is the output of a recorded alignment loop. The decisions in
> §1 and §5 _are_ that record — they were agreed before a line of this was written.
> It contains **zero code by design**: interfaces and contracts are described in
> prose so a contributor can implement against them without inheriting premature
> choices.

---

## 0. Executive Summary

`polyglot-core` is a single Rust core delivered to many runtimes. All domain logic
lives in one pure crate; every language gets a thin adapter over it. v0.1 deliberately
ships a *minimal-but-real* core and proves the **delivery machinery** end to end through
two surfaces — a `clap` CLI binary (the universal subprocess floor, usable from any host
language) and a `wasm-bindgen` build (consumed by the existing `glyph` project in the
browser) — with one shared parity test-vector suite proving the surfaces are logically
identical. v0.2 adds in-process bindings (Python + Go via UniFFI) as "arms" on top. This
is a good long-term bet because the core is the only place logic lives: surfaces are
mechanical, replaceable wrappers, so adding, swapping, or retiring a target runtime never
touches the logic — and never risks the four faces drifting apart.

---

## 1. Context & Constraints

### Project context
- **Greenfield, standalone Cargo workspace** (`polyglot-core`), new repo.
- Part of a personal ecosystem of Lovecraft-named tools: **Azathoth** (Python AI/MCP agent framework, `uv`+`ruff`+`ty`), **Yog-Sothoth** (Go infra/lifecycle CLI, ships a cross-compiled binary inside a wheel), and **Glyph** (Rust lexer/parser/semantic-analyzer with a SvelteKit + WASM frontend). Glyph is the proof case: it already does the exact split this spec generalizes — a pure `analyze_full_program_struct` core and a thin `#[wasm_bindgen] analyze_full_program` wrapper that only serializes.

### Main goals
- **Scope 1 — ship the artifact.** A language-agnostic CLI binary that any project runs as a subprocess. The "run rust from anywhere" floor.
- **Scope 2 — generate bindings.** Idiomatic in-process bindings (Python, Go) so callers invoke the *same* logic without subprocess overhead — the "arms."
- **Done (v0.1)** = the minimal core runs through the CLI *and* through the WASM build inside glyph, and the parity vectors confirm both produce byte-identical results to raw Rust.

### Team & scale _[ASSUMPTION]_
- Solo developer. Optimize for correctness, maintainability, and a clean contract — not throughput. Two latency tiers are in play and must stay conscious: subprocess (~ms) vs in-process FFI (~ns–µs).

### Architectural rules (from the established stack — mandated, not chosen here)
- **Rust**: edition 2024, MSRV pinned (`rustc` 1.94+), `rust-analyzer`, `rustfmt`, `bacon` for live errors, `mprocs` for multi-process, `clap` derive for the CLI.
- **Web**: `wasm-bindgen` + `wasm-pack` for the Rust→WASM build; `serde-wasm-bindgen` at the boundary. `deno` + `biome` for any *new* JS/TS tooling owned by this repo (glyph itself stays on its existing SvelteKit toolchain — not in scope to change).
- **Python (v0.2)**: `uv`, `ruff`, `ty`. Never `pip`/`poetry`/`mypy`/`black`. `maturin` as the build backend for the wheel.
- **Go (v0.2)**: `uniffi-bindgen-go`. Preserve `CGO_ENABLED=0` cross-compilation wherever the CLI floor is used.
- **Bindings (v0.2)**: UniFFI via **proc-macros** (`#[uniffi::export]` + `setup_scaffolding!()`), not UDL.
- **Nix**: `flake.nix` dev shell, `direnv` + `nix-direnv` via `.envrc`; `alejandra` formatter, `nil` LSP, `statix` + `deadnix` lint, `flake-checker --no-telemetry`.
- **Tasks**: `just` with `set shell := ["nu", "-c"]`. Helper scripts in nushell (type signatures on every function, pipeline-first, records over tuples, tiny helpers, cross-script utilities in `_shared.nu`). Never `make`, never bash.
- **Code style**: functional/iterator over imperative; small composable helpers; named fields over positional tuples; comments explain *why*; no dead code; `SCREAMING_CASE` constants, `snake_case` fns/vars, `kebab-case` CLI flags.
- **Licensing/docs**: MIT, English-only _[ASSUMPTION, matches existing repos]_.

### Out of scope (v0.1)
- UniFFI / Python / Go bindings — **v0.2**.
- Glyph's real lexer/parser/semantics — **milestone 3**. v0.1 core is a minimal stand-in.
- A published raw C-ABI (`capi`) surface — folded into v0.2 when in-process native linking lands.
- Kotlin / Swift / Ruby — these come *free* from UniFFI later; not a goal now.
- CI — deferred (local gate only); see §8.
- Auth, persistence, networking — N/A; the core is a stateless processor.

### Assumptions (flagged)
- _[ASSUMPTION]_ Solo maintainer; no multi-team coordination.
- _[ASSUMPTION]_ v0.1 wire format is **JSON** (human-debuggable, universal). Revisitable — see §5.
- _[ASSUMPTION]_ The domain fits a single `request → response` shape for v0.1 (no streaming/incremental). Flagged for a spike before the glyph port (§9).
- _[ASSUMPTION]_ Codename is a placeholder.

---

## 2. Architecture Overview

Three layers, one law.

```
                          CONSUMERS
   glyph (browser) ─┐     scripts / CI ─┐     (v0.2) python & go apps ─┐
                    │                   │                              │
              ┌─────▼─────┐       ┌─────▼─────┐                 ┌──────▼──────┐
              │   wasm    │       │    cli    │                 │   uniffi    │   SURFACES
              │  surface  │       │  surface  │                 │   surface   │   (thin adapters:
              │  (v0.1)   │       │  (v0.1)   │                 │   (v0.2)    │    deserialize →
              └─────┬─────┘       └─────┬─────┘                 └──────┬──────┘    call → serialize)
                    │                   │                              │
                    └─────────┬─────────┴───────────────┬──────────────┘
                              │
                       ┌──────▼───────────────────────┐
                       │            core               │   CORE
                       │  pure Rust logic              │   single source of truth
                       │  no IO · no FFI · no state     │
                       └──────────────┬────────────────┘
                                      │ replayed against, identical results
                              ┌───────▼────────┐
                              │ parity vectors  │   VERIFICATION
                              │ input → output  │
                              └────────────────┘
```

- **Core domain**: the language-processing logic (a minimal pipeline in v0.1; glyph's full lex→parse→analyze→encode pipeline by milestone 3).
- **Supporting domains**: the surface adapters, the parity harness, the build/dev tooling.
- **The law** (one invariant the whole design rests on): *logic exists only in `core`.* Every surface is a mechanical wrapper — receive input, deserialize, call one core function, serialize the result, hand it back. A surface that contains a branch of business logic is a bug.

---

## 3. Design Patterns & Code Standards

### Core — Ports & Adapters (Hexagonal)
- **Pattern**: the core is the hexagon's interior; each surface is an adapter plugged into the same port.
- **Why this, not speculation**: there are already *three concrete adapters* (CLI, WASM, UniFFI) plus a fourth implicit one (raw Rust tests). The multiplicity is real today, not hypothetical — which is exactly when Ports & Adapters earns its keep. At year 3 you add a Go consumer without touching logic; at year 5 you swap a WASM toolchain; at year 10 you target a runtime that doesn't exist yet, and the core is untouched.
- **How**: `core` exposes a *small* set of pure functions over `serde`-derivable value types. No I/O, no FFI types, no globals, no `unwrap` in library paths — fallible operations return `Result`.
- **Standards**: functional/iterator style; named-field structs and enums over positional tuples; `why`-only comments; no dead code.

### Serialization boundary — single Wire Contract (DTO)
- **Pattern**: one request type in, one response type out, both `serde`-derived and owned by `core`. This is the *contract* every surface shares.
- **Why**: one shape everywhere makes "identical logic" *provable* rather than aspirational. It is the structural defense against per-surface drift — the risk we accepted when we chose best-tool-per-target over a single generator (§5).
- **How**: surfaces only ever (de)serialize this contract. The CLI uses `serde_json`; the WASM surface uses `serde-wasm-bindgen`; UniFFI (v0.2) uses generated records. **No shared-pointer ownership crosses any boundary** — values are copied/serialized, never lent. Complex values cross as serialized data so each surface is ~20 mechanical lines.

### CLI surface — Adapter (`clap` derive)
- **How (contract, in prose)**: accept input from an argument, a file, or stdin; produce serialized output on stdout; signal failure with a non-zero exit code and a diagnostic on stderr. Human-readable output by default, machine-readable behind a `--json` flag (mirrors Azathoth's `--json` convention).
- **Standards**: `kebab-case` flags; `main` dispatches by subcommand; no logic beyond I/O plumbing and a single core call.

### WASM surface — Adapter (`wasm-bindgen`)
- **How**: a single (or few) `#[wasm_bindgen]` entry that takes the input, calls the *same* core function the CLI calls, and returns the result via `serde-wasm-bindgen`. This is glyph's existing `analyze_full_program` (thin wrapper) / `analyze_full_program_struct` (pure) split — generalized. **Batch the boundary**: one call returns everything; never cross per-item (the polyglot map's own WASM risk note).

### UniFFI surface — Adapter via proc-macros _(v0.2)_
- **How**: annotate the same core functions/types with `#[uniffi::export]` / `#[derive(uniffi::Record)]`; call `setup_scaffolding!()` (no UDL, no `build.rs`). Python ships as a `maturin` wheel; Go is generated by `uniffi-bindgen-go`, **pinned to the exact `uniffi-rs` version**. `[REVISIT]` on every UniFFI upgrade — it is pre-1.0.

### Parity harness — Golden Vectors (table-driven)
- **Pattern**: a directory of `input → expected-output` cases as *language-agnostic data*; each surface has a tiny replay runner that feeds input through it and diffs against expected.
- **Why**: with no single generator enforcing cross-language identity, **the vectors are the contract**. They are the load-bearing wall, not a nicety.
- **How**: vectors live in the core repo and are the source of truth for all surfaces, including raw Rust.

### Dependency-direction rule (enforced, see §8)
Surfaces depend on `core`; `core` depends on none of them; no surface imports another surface; `core` carries **zero** FFI/IO/CLI dependencies.

---

## 4. Component Map & Directory Structure

| Component | Responsibility (one sentence) | Location | Exposes | Consumes | Must NOT do |
|---|---|---|---|---|---|
| `core` | Hold all domain logic as pure functions over the wire contract. | `crates/core` | The request/response value types + a small set of pure functions. | Nothing in this repo; only pure crates (`serde`, domain libs). | Touch I/O, FFI types, env, globals, or any surface. |
| `cli` | Expose `core` as a subprocess-invokable binary (scope 1 floor). | `crates/cli` | A command-line interface; serialized stdout. | `core`, `clap`, `serde_json`. | Contain logic; import `wasm`/`uniffi`. |
| `wasm` | Expose `core` to the browser for glyph (scope web). | `crates/wasm` | One/few `#[wasm_bindgen]` entries. | `core`, `wasm-bindgen`, `serde-wasm-bindgen`. | Contain logic; import `cli`/`uniffi`. |
| `vectors` | Define the canonical input→output cases. | `vectors/` | Data files (inputs + expected outputs). | — | Contain language-specific code. |
| dev tooling | Reproducible env + task automation. | `flake.nix`, `.envrc`, `justfile`, `scripts/` | A dev shell and task recipes. | nix, just, nushell. | Encode logic that belongs in `core`. |
| `ffi` (uniffi) | Native in-process bindings (scope 2 arms). | `crates/ffi` _(v0.2)_ | `#[uniffi::export]` surface. | `core`, `uniffi`. | Contain logic. |
| `bindings/*` | Per-language packages over `ffi`. | `bindings/python`, `bindings/go` _(v0.2)_ | A wheel; a Go module. | `ffi`, `maturin` / `uniffi-bindgen-go`. | Diverge from the contract. |

### Proposed tree (v0.1 solid; v0.2 additions marked)

```
polyglot-core/
├── Cargo.toml                 # workspace manifest
├── flake.nix                  # dev shell: rust toolchain, wasm-pack, just, nushell, nix lints
├── .envrc                     # use flake (direnv + nix-direnv)
├── justfile                   # set shell := ["nu","-c"]; recipes: build, check, parity, wasm
├── LICENSE                    # MIT
├── README.md
├── crates/
│   ├── core/                  # pure logic — the single source of truth
│   ├── cli/                   # clap binary  (scope 1, v0.1)
│   ├── wasm/                  # wasm-bindgen (web,     v0.1)
│   └── ffi/                   # uniffi arms  (scope 2, v0.2)        ← later
├── bindings/                                                       # ← v0.2
│   ├── python/                # maturin wheel over crates/ffi
│   └── go/                    # uniffi-bindgen-go output over crates/ffi
├── vectors/
│   ├── input/                 # canonical inputs
│   └── expected/              # expected outputs (one per input)
└── scripts/
    ├── _shared.nu             # cross-script nushell utilities
    └── parity.nu              # replay vectors against each built surface
```

Glyph migrates to depend on the published `wasm` package as its analysis engine — the showcase consumer, and the proof that the generalization holds.

---

## 5. Trade-off Analysis

```
DECISION: How to reach four runtimes from one Rust core.
OPTIONS CONSIDERED:
  A. Single unifying generator (UniFFI for all) — pro: one interface; con: UniFFI
     cannot target the browser, so Web is excluded regardless.
  B. Best tool per target, core is the unification point — pro: idiomatic per
     language, reuses glyph's WASM path; con: no generator enforces identity (mitigated
     by parity vectors).
  C. Hand-rolled C-ABI + per-language adapters — pro: max control; con: max boilerplate.
CHOSEN: B.
REASON: The core, not a binding tool, is where "write once" actually lives. The browser
     forces a second mechanism (wasm-bindgen) no matter what, so a single generator buys
     nothing while costing idiom. Parity vectors carry the identity guarantee instead.
REVISIT IF: a single generator gains idiomatic Python + Go + browser support at once.
```
```
DECISION: Scope-1 delivery mechanism (run from any language).
OPTIONS CONSIDERED:
  A. CLI binary via subprocess — pro: zero FFI, CGO_ENABLED=0 stays intact, matches the
     Yog-Sothoth ship-a-binary pattern; con: ~ms process-spawn latency.
  B. cdylib + purego (no-cgo dlopen) — pro: in-process, no C compiler; con: beta, glibc
     %fs TLS footgun, hand-registered symbols.
  C. cgo + cbindgen — pro: well-understood; con: breaks simple GOOS/GOARCH cross-compile.
CHOSEN: A for the v0.1 floor.
REASON: The domain (analyse a source on demand) does not need hot-loop latency. Subprocess
     removes all FFI complexity, keeps Go's cross-compile story, and is a pattern already
     in production in this ecosystem. In-process is exactly what v0.2's arms are for.
REVISIT IF: a consumer needs sub-ms repeated calls → reach for v0.2 UniFFI, with purego
     (B) as a documented escape hatch.
```
```
DECISION: Web delivery.
OPTIONS CONSIDERED:
  A. wasm-bindgen — pro: glyph already uses it, canonical browser path; con: none material.
  B. Diplomat — pro: one tool for C/C++/JS-WASM; con: weak Python/Go, abandons glyph's path.
  C. WASM Component Model / wit-bindgen — pro: future-facing; con: overkill for DOM-adjacent work.
CHOSEN: A.
REASON: Reuses working code, and UniFFI can't do the browser anyway.
REVISIT IF: bundle size or multi-language WASM components become a real goal.
```
```
DECISION: What the v0.1 core actually contains.
OPTIONS CONSIDERED:
  A. Minimal-but-real core (a few pure functions, non-trivial types) — pro: proves the
     toolchain end to end; a failure is obviously a toolchain failure.
  B. Port glyph's pipeline now — pro: real value immediately; con: toolchain + logic risk land together.
CHOSEN: A.
REASON: De-risk the unfamiliar 3-surface build before investing in domain logic.
REVISIT IF: never — the glyph port is milestone 3, on purpose.
```
```
DECISION: Wire format at the boundary.
OPTIONS CONSIDERED:
  A. JSON — pro: debuggable, universal, trivial in every surface; con: not the fastest.
  B. Compact binary (bincode / msgpack) — pro: fast/small; con: opaque, premature.
  C. Native types per surface — pro: zero serialization; con: no single contract, drift.
CHOSEN: A for v0.1.  [REVISIT]
REASON: One readable contract beats speed we have no evidence we need.
REVISIT IF: profiling shows the boundary is hot (e.g. per-keystroke analysis in glyph).
```
```
DECISION: Repo topology.
OPTIONS CONSIDERED:
  A. New standalone repo, glyph migrates onto it — pro: clean foundation; con: a migration step.
  B. Extract out of glyph in place — pro: no new repo; con: construction inside the proof case.
CHOSEN: A.
REASON: Keep the foundation clean; let glyph be the validation, not the building site.
```
```
DECISION: State management & storage.
CHOSEN: none — the core is pure and stateless.
REASON: A processor, not a service. Recording this explicitly so no one adds a database,
     cache, or session layer by reflex. Each call is total: input in, output out.
```
```
DECISION: Distribution model per surface.
CHOSEN: CLI cross-compiled and shipped per-ecosystem (a binary-in-wheel à la Yog-Sothoth,
     npm, and/or cargo-binstall); WASM as an npm-consumable package; (v0.2) Python wheel
     via maturin, Go module via uniffi-bindgen-go.
REASON: Meets each ecosystem where it lives without a logic fork.
REVISIT IF: a registry/publishing strategy is needed at scale → Phase 4.
```

---

## 6. Phased Implementation Plan

### Phase 1 — Foundation (v0.1)
- **Goal**: prove one core reaches the browser (glyph) and the shell (CLI) with provably identical results.
- **Components**: `core` (minimal), `cli`, `wasm`, `vectors`, dev tooling (`flake.nix`, `.envrc`, `justfile`, `scripts/`).
- **Dependencies**: none — this is the floor.
- **Steps → verify**:
  1. Workspace + dev shell → verify: a fresh `direnv allow` yields a shell with the full toolchain.
  2. `core` contract + minimal pure functions → verify: `core` unit tests pass; `core` has no FFI/IO deps (fitness check).
  3. `cli` adapter → verify: a known input through the binary emits the expected `--json` output.
  4. `wasm` adapter → verify: `wasm-pack` builds; a node/deno harness replays the vectors green.
  5. Parity runner (`scripts/parity.nu`) → verify: CLI, WASM, and raw Rust all match `vectors/expected/` for every case.
  6. Glyph integration → verify: glyph loads the WASM package and analyzes a sample identically to the CLI.
- **Exit criteria**: every vector passes on every v0.1 surface; glyph runs on the shared core.
- **Risk flags**: `[HIGH RISK]` the wire contract — changing it later ripples to every surface and every vector. Lock its *shape* (not its contents) early.

### Phase 2 — Native arms (v0.2)
- **Goal**: in-process Python + Go bindings calling the same core.
- **Components**: `crates/ffi` (UniFFI proc-macros), `bindings/python` (maturin wheel), `bindings/go` (uniffi-bindgen-go).
- **Dependencies**: Phase 1 contract frozen.
- **Steps → verify**: annotate core for UniFFI → verify Python wheel builds via maturin and imports; generate Go bindings pinned to the `uniffi-rs` version → verify Go module builds; extend the parity runner to replay vectors through Python and Go.
- **Exit criteria**: parity vectors pass on Python and Go too — four+ surfaces, one result set.
- **Risk flags**: `[HIGH RISK]` UniFFI pre-1.0 churn and the Go-generator version lockstep; `[REVISIT]` on every UniFFI bump.

### Phase 3 — Domain port (milestone)
- **Goal**: replace the minimal core with glyph's real lex→parse→analyze→encode pipeline; glyph becomes a thin web consumer of the shared core.
- **Dependencies**: Phases 1–2 stable; the streaming/incremental spike resolved (§9).
- **Exit criteria**: glyph's behavior is unchanged from the user's view, but its analysis engine now lives in `polyglot-core` and is reachable from the CLI and bindings too.
- **Risk flags**: `[REVISIT]` whether a single request→response contract fits incremental editor analysis.

### Phase 4 — Scale & hardening
- **Goal**: CI, per-ecosystem publishing, optional compact wire format, "free" extra languages (Kotlin/Swift/Ruby from UniFFI).
- **Exit criteria**: a fresh checkout builds and passes parity in CI; releases are reproducible.

---

## 7. Implementation Management

- **Sequencing (dependency graph)**: `core` contract → (`cli` ∥ `wasm`) → `parity` → glyph integration → `ffi`/bindings. The contract gates everything.
- **Ownership** (conceptual, even solo): `core`/`cli`/`wasm` = Rust; `bindings/python` = uv+maturin; `bindings/go` = uniffi-bindgen-go; glyph = the web consumer.
- **Critical path**: the request/response value contract in `core`. Every surface and every vector hangs off it.
- **Integration points (coordinate closely)**: the serialization boundary (core ↔ each surface) and glyph ↔ the WASM package.
- **Breaking changes (flagged)**: `[HIGH RISK]` the wire contract; `[HIGH RISK]` the `uniffi-rs` version pin in v0.2 (a `cargo update` can silently break Go generation).

---

## 8. Validation & Testing Strategy

| Layer | Test type | What it verifies |
|---|---|---|
| Core logic | Unit tests | Domain rules in isolation, no surfaces involved. |
| Wire contract | Round-trip + golden vectors | (De)serialization is lossless; output matches expected. |
| CLI surface | Contract test | Input → exact `--json` stdout; exit codes on failure. |
| WASM surface | Vector replay (node/deno harness) | Browser-built core matches expected outputs. |
| Glyph integration | E2E | Load WASM, analyze a sample, assert against the CLI. |
| Bindings (v0.2) | Vector replay (Python, Go) | In-process surfaces match the same vectors. |
| Architecture | Fitness functions | Boundaries and dependency direction hold. |

### Architecture fitness functions (automated, the architecture's own tests)
- `core` must not depend on `clap`, `wasm-bindgen`, `uniffi`, or any I/O crate — a manifest check fails the build if it does.
- No surface imports another surface.
- A fresh-checkout build from a clean tree succeeds (the Yog-Sothoth "works on my machine" guard).
- Parity vectors must pass on **every** built surface — a red vector on any surface fails the gate.

### Local dev validation (the pre-commit gate)
`just check` (a nushell recipe) runs, in order: `rustfmt` + `clippy`; `ty` + `ruff` (Python, v0.2); `biome` (any hand-written TS); then the parity runner. `bacon` gives live Rust errors during iteration; `mprocs` orchestrates multi-surface watch builds. Green `just check` is the bar before any commit.

### Observability
Minimal by intent — this is a library/CLI, not a service. Structured, machine-readable error output (`--json`) is the baseline. Defer `tracing`-style instrumentation until a long-running consumer exists; recorded here so it's a conscious deferral, not an oversight.

---

## 9. Open Questions & Risks

- **Wire format shelf life** `[REVISIT]`: JSON is right until it isn't. The trigger to spike a compact format is evidence the boundary is hot — most likely glyph doing per-keystroke analysis. Measure before switching.
- **UniFFI pre-1.0 + Go lockstep** `[HIGH RISK, v0.2]`: external generators must track the exact `uniffi-rs` version. Pin it, document it, and treat every UniFFI upgrade as a coordinated change.
- **purego escape hatch** `[REVISIT]`: if the in-process Go path ever bypasses UniFFI, the glibc `%fs` TLS interaction under `CGO_ENABLED=0` needs explicit testing.
- **Request→response vs incremental** (spike before Phase 3): glyph's editor analysis may want incremental/streaming rather than a single total call. Resolve before porting the real pipeline, since it could reshape the contract — the one thing that's expensive to change.
- **Distribution strategy** (decide at Phase 4): who publishes the CLI per-ecosystem (wheel-with-binary, npm, `cargo-binstall`)?
- **Codename**: `Nyarlathotep` is a candidate, not a commitment.

---

### Appendix — Alignment record (the receipt)

This spec was produced after an explicit alignment loop. The load-bearing decisions and
their reversals are preserved in §5 — notably: the binding strategy moved from "UniFFI
unifies everything" → "drop UniFFI" → "best tool per target, core is the unifier, UniFFI
returns as the v0.2 native arms," and scope 1 settled on a **CLI subprocess floor** rather
than an FFI bridge, which removed the purego/cgo complexity entirely. The parity-vector
suite is the agreed price of best-of-breed bindings, and is therefore non-optional.
