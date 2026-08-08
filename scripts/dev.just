# dev.just — the human, tight loop. Reads and rebuilds; never rewrites history.

[group('dev')]
build:
    cargo build --workspace --all-features

# Rebuild + retest on every save (bacon drives cargo under the hood).
[group('dev')]
watch:
    bacon

[group('dev')]
doc:
    cargo doc --workspace --no-deps --all-features --open

[group('dev')]
clean:
    cargo clean
