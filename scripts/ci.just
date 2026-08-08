# ci.just — automate + guard. `ci` is the one thing a PR must pass; it never
# rewrites the tree (uses the `*-check` verify-only twins from check.just).

[group('ci')]
ci: fmt-check lint-check types test && (_banner f"✓ ci green — poly-core {{VERSION}}")

# Nuke caches/lockfile and regenerate — the "start fresh" button.
[group('ci')]
prepare:
    fd -u --prune '^target$' | lines | each {|p| rm -rf $p } | ignore
    cargo generate-lockfile

# Only a green ci run reaches the repo.
[group('ci')]
[confirm("commit with a green ci run?")]
commit msg: ci
    git add -A
    git commit -m "{{msg}}"
