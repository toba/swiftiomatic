---
# tea-3ch
title: Handle schema.json output location
status: ready
type: task
created_at: 2026-04-19T17:32:03Z
updated_at: 2026-04-19T17:32:03Z
parent: rcc-z52
---

`schema.json` outputs to the package root, outside any target's source directory. Decide how to handle this in the plugin context.

Options:
- A: Generate alongside Swift files, add a post-build copy step
- B: Keep schema generation as a separate `.command` plugin (run manually)
- C: Move schema.json into `Sources/SwiftiomaticKit/Generated/` and reference from there

- [ ] Choose approach
- [ ] Implement chosen approach
- [ ] Verify schema.json is generated correctly
