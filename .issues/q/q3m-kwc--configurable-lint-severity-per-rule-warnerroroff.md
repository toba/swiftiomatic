---
# q3m-kwc
title: Configurable lint severity per rule (warn/error/off)
status: completed
type: feature
priority: high
created_at: 2026-04-17T23:19:18Z
updated_at: 2026-04-17T23:41:56Z
---

## Problem

All lint findings are hardcoded to warning severity. `DiagnosticsEngine.consumeFinding()` always emits `.warning` — there's no way to make a rule produce an error. This means Xcode always shows yellow triangles for lint issues, never red errors that block compilation.

The `rules` dict in `swiftiomatic.json` is `[String: Bool]` — on or off, no severity control.

## Goal

First-class severity levels so Xcode natively flags findings as warnings or errors based on per-rule configuration in \`swiftiomatic.json\`.

## Config Design

Change the \`rules\` dictionary value type from \`Bool\` to \`String | Bool | Object\`:

\`\`\`jsonc
{
  "format": {
    "NoSemicolons": "error",          // string form
    "RedundantSelf": "warn",          // string form  
    "CapitalizeAcronyms": "off",      // string form (replaces false)
    "FileScopedDeclarationPrivacy": {  // object form (has options)
      "severity": "error",            // replaces "enabled"
      "accessLevel": "private"
    },
    // Backward compat: true → "warn", false → "off"
    "SomeRule": true,
    "SomeOtherRule": false
  },
  "lint": {
    "ASCIIIdentifiers": "error",
    "DocCommentSummary": "off"
  }
}
\`\`\`

Valid values: \`"warn"\`, \`"error"\`, \`"off"\` (plus \`true\`/\`false\` for backward compat).

## Implementation

### Library layer (Sources/Swiftiomatic/)

- [ ] Add \`Finding.Severity\` enum (\`.warning\`, \`.error\`) to \`Finding.swift\`
- [ ] Add optional \`severity\` property to \`Finding\`
- [ ] Change \`Configuration.rules\` from \`[String: Bool]\` to \`[String: RuleSeverity]\` where \`RuleSeverity\` is an enum (\`.warning\`, \`.error\`, \`.off\`)
- [ ] Update \`Configuration\` JSON decoding to parse \`"warn"\`/\`"error"\`/\`"off"\`/\`true\`/\`false\` and object forms with \`"severity"\` key
- [ ] Update \`Configuration+Dump\` to emit the new format
- [ ] Update \`Context.shouldFormat()\` — \`.off\` → skip, \`.warning\`/\`.error\` → run
- [ ] Thread severity from config into \`FindingEmitter\` so emitted findings carry the configured severity
- [ ] Update \`RuleRegistry+Generated.swift\` generator to use \`RuleSeverity\` defaults
- [ ] Update JSON schema (\`swiftiomatic.schema.json\`)

### CLI layer (Sources/sm/)

- [ ] Update \`DiagnosticsEngine.consumeFinding()\` to read \`finding.severity\` instead of hardcoding \`.warning\`
- [ ] Verify Xcode output format: \`file:line:column: error: [Rule] message\` vs \`warning:\`

### Tests

- [ ] Test config round-trip: decode → encode with new severity values
- [ ] Test backward compat: \`true\` → warn, \`false\` → off
- [ ] Test that error-severity findings produce \`error:\` in diagnostic output
- [ ] Test that \`Context.shouldFormat\` respects \`.off\`

## Key Files

- \`Sources/Swiftiomatic/API/Finding.swift\` — add Severity enum
- \`Sources/Swiftiomatic/API/Configuration.swift\` — rules type change, decoding
- \`Sources/Swiftiomatic/API/Configuration+Dump.swift\` — encoding
- \`Sources/Swiftiomatic/Core/Context.swift\` — shouldFormat() check
- \`Sources/Swiftiomatic/Core/FindingEmitter.swift\` — thread severity
- \`Sources/Swiftiomatic/Core/RuleRegistry+Generated.swift\` — defaults
- \`Sources/_GenerateSwiftiomatic/RuleRegistryGenerator.swift\` — codegen
- \`Sources/_GenerateSwiftiomatic/ConfigurationSchemaGenerator.swift\` — schema
- \`Sources/sm/Utilities/DiagnosticsEngine.swift\` — consumeFinding severity
- \`Sources/sm/Utilities/Diagnostic.swift\` — already has Severity enum
- \`swiftiomatic.schema.json\` — schema update
- \`Tests/SwiftiomaticTests/API/ConfigurationTests.swift\` — tests

## Notes

- The CLI already has \`Diagnostic.Severity\` and \`treatWarningsAsErrors\` — the plumbing exists, it just needs to be connected
- Xcode parses \`file:line:column: error:\` vs \`warning:\` from stderr to show red vs yellow markers — this is the key integration point
- \`StderrDiagnosticPrinter\` already formats with severity — it will Just Work once \`consumeFinding\` uses the right severity


## Summary of Changes

Added first-class severity levels (warn, error, off) for lint and format rules.

- New `RuleSeverity` enum in `Sources/Swiftiomatic/API/RuleSeverity.swift`
- `Configuration.rules` changed from `[String: Bool]` to `[String: RuleSeverity]`
- `Finding` now carries a `severity` property threaded from config through `FindingEmitter` and `Rule.diagnose()`
- `DiagnosticsEngine.consumeFinding()` maps finding severity to Xcode-native `error:` / `warning:` output
- Config JSON uses `"warn"` / `"error"` / `"off"` strings; object forms use `"severity"` key
- Schema file renamed from `swiftiomatic.schema.json` to `schema.json`
- All 2347 tests pass
