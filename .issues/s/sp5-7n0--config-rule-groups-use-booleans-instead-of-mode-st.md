---
# sp5-7n0
title: Config rule groups use booleans instead of mode strings for individual rules
status: completed
type: bug
priority: normal
created_at: 2026-04-18T01:36:32Z
updated_at: 2026-04-18T02:16:54Z
sync:
    github:
        issue_number: "335"
        synced_at: "2026-04-23T05:30:24Z"
---

## Problem

All config rule groups emit boolean values for individual rules instead of mode strings. For example, the `sort` group:

```json
"sort": {
  "declarations": true,
  "imports": true,
  "mode": "fix",
  "switchCases": false,
  "typealiases": true
}
```

Should be:

```json
"sort": {
  "declarations": "fix",
  "imports": "fix",
  "mode": "fix",
  "switchCases": "off",
  "typealiases": "fix"
}
```

Every rule group has this same issue — individual rules use `Bool` (true/false) but should use the group's mode type (e.g. "fix", "lint", "off").

## TODO

- [x] Find where rule group config structs are defined
- [x] Change individual rule properties from `Bool` to mode strings
- [x] Update encoding/decoding to handle mode strings
- [x] Verify all rule groups are updated


## Summary of Changes

- Configuration encoding: rules within groups now emit mode strings (`"fix"`, `"warn"`, `"off"`) instead of booleans
- Configuration decoding: expects mode strings, no longer falls back to booleans
- Removed derived "group mode" concept — each rule has its own mode
- Schema generator: group rule properties are now mode enums, not booleans
- Created `ConfigRepresentable` protocol — rule configs and `ConfigGroup` describe their own properties
- Schema generator reads from `ConfigRepresentable` conformances and `RuleRegistry` — no magic strings
- Replaced `ruleConfigDecoders`/`ruleConfigEncodable` magic string tables with `RuleConfigEntry` driven by `ConfigRepresentable.ruleName`
- Exposed `Configuration.ruleConfigSchemas` via `@_spi(Internal)` for the schema generator
- Build passes with tests
