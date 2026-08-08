# _shared.just — vars, private helpers, and the front door. Shared into every
# layer via `import`; settings and variables live here once.

PROJECT := "poly-core"
VERSION := `git describe --tags --always --dirty`

[default]
[group('meta')]
list:
    @just --list --unsorted

# Interactive autocomplete over every public recipe — type to fuzzy-filter.
[group('meta')]
menu:
    #!/usr/bin/env nu
    let recipes = (just --summary | str trim | split row ' ')
    let choice = ($recipes | str join "\n" | ^gum filter --placeholder "poly-core recipe...") | str trim
    if ($choice | is-not-empty) { just $choice }

[private]
[group('meta')]
_banner msg:
    #!/usr/bin/env nu
    ^gum style --foreground 212 --border rounded --padding "0 2" "{{msg}}"
