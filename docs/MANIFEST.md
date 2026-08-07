# polyglot-core — Manifest

> _One logic. A thousand faces._
> The messenger Nyarlathotep wore many forms but carried a single will.
> That is the whole idea, in one sentence.

This is the **why**. The foundation spec is the how. Read this first; it's faster to
argue with.

---

## The problem

Rust is the right language to write the hard part in — fast, safe, honest about errors.
But on its own it reaches a narrow room: people who already build Rust. The interesting
logic ends up trapped behind a language boundary, or worse, **reimplemented** in Python,
in Go, in TypeScript — three copies that start identical and drift the moment someone
fixes a bug in only one of them.

We've felt this already. `glyph` is a Rust analyzer with a web face. The instinct there
was correct: write the logic once, expose it thinly. polyglot-core is that instinct,
made deliberate and made general.

---

## The idea

**Write the logic once, in Rust. Give every language a thin face over it.**

There is exactly one place logic lives — the core. Everything else is a mechanical
wrapper: take input, hand it to the core, hand the answer back. A wrapper that contains a
decision is a bug, not a feature. This single rule is what keeps four runtimes from ever
disagreeing.

---

## The two faces

The core reaches the world two ways, and they are not the same thing at different polish
levels — they're two answers to two different questions.

- **The floor — a CLI binary.** Ship one compiled executable; any project on earth can
  run it as a subprocess. This is *reach*: Python, Go, a shell script, a CI job, a
  language that doesn't exist yet. It costs a process spawn (milliseconds), which is
  nothing for "analyse this, then tell me."
- **The arms — generated bindings.** When milliseconds matter, idiomatic in-process
  bindings call the same core directly (nanoseconds). These grow *on top of* the floor,
  later, only where speed earns them.

Reach first. Speed where it pays. Never confuse the two.

---

## What we believe

- **The core is the unifier — not a tool.** We don't hunt for one magic generator that
  speaks every language. There isn't one, and chasing it costs idiom for nothing. Each
  language gets the best tool for *that* language; they all point at the same core.
- **The browser is always the exception.** It can't spawn a subprocess, so it always gets
  its own face (WASM). We design around that fact instead of pretending it away.
- **Prove the machine before loading the cargo.** v0.1 carries a deliberately trivial
  core, so that when the four-surface build breaks, it's obviously the build — not the
  logic. The real domain logic moves in only once the delivery machinery is trusted.
- **Identity is proven, not promised.** Because no single tool guarantees the faces match,
  one shared set of input→output vectors is replayed against every surface. These vectors
  are the project's conscience. If they're red, we are lying about "the same logic
  everywhere."
- **Small core, small everything.** A small core means a small test suite, a small
  boundary, a small blast radius when something changes. Keep it lean on purpose.
- **Stateless and total.** The core is a processor, not a service: input in, output out,
  no memory between calls. No database, no session, no surprise.

---

## What this is NOT

- Not a framework, a platform, or a runtime. It's a core and some faces.
- Not an attempt to make one binding tool rule all four languages.
- Not optimized before it's measured — JSON at the boundary until profiling says otherwise.
- Not the glyph rewrite. Glyph's real pipeline arrives later, on purpose; for now it's the
  showcase, not the construction site.
- Not speculative. No abstraction enters before a second real use for it does.

---

## The ten-year bet

If this is right, then in three years adding a new language is a weekend, not a rewrite.
In five, swapping a binding toolchain touches zero logic. In ten, targeting a runtime
nobody has heard of yet means writing one more thin face — and the core, and every other
face, never notices. The value compounds because the logic only ever exists once.

---

## Where it sits

Azathoth understands the work. Yog-Sothoth opens and guards the gate. Glyph reads the
glyphs. polyglot-core is the thing underneath them all that refuses to be rewritten four
times — the one will behind the many faces.
