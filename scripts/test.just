# test.just — prove it. Reads only, never rewrites the tree.

[group('test')]
test:
    cargo test --workspace --all-features

# Run a single test by name substring, e.g. `just test-name my_test`.
[group('test')]
test-name name:
    cargo test --workspace --all-features {{name}}

[group('test')]
test-doc:
    cargo test --workspace --all-features --doc
