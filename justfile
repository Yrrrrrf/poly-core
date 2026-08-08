# polyglot-core — command runner front door.
# `just` alone prints the grouped menu. `just ci` is the one thing a PR must pass.
set shell := ["nu", "-c"]

import 'scripts/_shared.just'
import 'scripts/dev.just'
import 'scripts/check.just'
import 'scripts/test.just'
import 'scripts/ci.just'
