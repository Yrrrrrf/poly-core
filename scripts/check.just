# check.just — make it right, in place. This family REWRITES the working
# tree (fmt, --fix). Verify-only twins (`*-check`) exist so `ci.just` never
# rewrites history on a CI checkout.

[group('check')]
fmt:
    cargo fmt --all

[group('check')]
fmt-check:
    cargo fmt --all -- --check

[group('check')]
lint:
    cargo clippy --workspace --all-targets --all-features --fix --allow-dirty --allow-staged -- -D warnings

[group('check')]
lint-check:
    cargo clippy --workspace --all-targets --all-features -- -D warnings

[group('check')]
types:
    cargo check --workspace --all-targets --all-features

[group('check')]
check: fmt lint types  # composition, not a fourth verb

# Slower, network-bound — stays out of the default `check`.
[group('check')]
audit:
    cargo audit
