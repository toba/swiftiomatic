---
# twe-mxp
title: Unify rule toggles and rule options into single rules dict
status: completed
type: feature
priority: normal
created_at: 2026-04-15T01:22:10Z
updated_at: 2026-04-17T22:15:50Z
sync:
    github:
        issue_number: "323"
        synced_at: "2026-04-17T22:17:16Z"
---

Currently rule enable/disable is in `rules: { "URLMacro": true }` while rule-specific config is at the top level (`urlMacro: { "macroName": "#URL" }`). This splits related config across two locations.

### Proposed format

Each rule value is either a `bool` (simple toggle) or an `object` (toggle + options):

```json
{
  "rules": {
    "URLMacro": { "enabled": true, "macroName": "#URL", "moduleName": "URLFoundation" },
    "SortImports": { "enabled": true, "includeConditionalImports": false },
    "CapitalizeAcronyms": false
  }
}
```

### Rules with options

- `URLMacro` — `macroName`, `moduleName`
- `FileHeader` — `text`
- `FileScopedDeclarationPrivacy` — `accessLevel`
- `NoAssignmentInExpressions` — `allowedFunctions`
- `SortImports` — `includeConditionalImports`, `shouldGroupImports`
- `CapitalizeAcronyms` — `words`
- `NoExtensionAccessLevel` — `placement` (from `extensionAccessControl`)
- `PatternLetPlacement` — `placement` (from `patternLet`)

### Scope

- [x] Update `Configuration` decoding to accept both bool and object for each rule entry
- [x] Move rule option lookups from top-level config to per-rule config
- [x] Keep backward compatibility: still accept old top-level keys during decoding
- [x] Update `dump-configuration` to emit the new format
- [x] Update JSON schema
- [x] Bump config version


## Summary of Changes

- `Configuration.init(from:)` now decodes unified rules dict: each value is either `Bool` or `{ "enabled": Bool, ...options }`
- All 8 rule config structs got custom `init(from:)` with `decodeIfPresent` for missing-key tolerance
- Old top-level config keys still accepted (backward compat), rules dict takes precedence
- `asJsonString()` post-processes to merge config into rules dict and remove top-level keys
- Schema generator emits `oneOf: [boolean, object]` for rules with options
- Config version bumped to 2
- 10 new tests covering new format, backward compat, precedence, round-trip
