---
# tea-3ch
title: Handle schema.json output location
status: completed
type: task
priority: normal
created_at: 2026-04-19T17:32:03Z
updated_at: 2026-04-19T18:14:55Z
parent: rcc-z52
---

`schema.json` outputs to the package root, outside any target's source directory. Decide how to handle this in the plugin context.

Options:
- A: Generate alongside Swift files, add a post-build copy step
- B: Keep schema generation as a separate `.command` plugin (run manually)
- C: Move schema.json into `Sources/SwiftiomaticKit/Generated/` and reference from there

- [x] Choose approach (option B: keep as separate manual step)
- [x] Implement chosen approach
- [x] Verify schema.json is generated correctly


## Summary of Changes

Chose option B: schema generation stays as a separate manual step via `swift run Generator` (without `--skip-schema`). The build tool plugin passes `--skip-schema` so schema.json is not regenerated on every build. Updated CLAUDE.md to document the two invocation modes.
