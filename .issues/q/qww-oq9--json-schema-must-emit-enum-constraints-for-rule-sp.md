---
# qww-oq9
title: JSON schema must emit enum constraints for rule-specific properties
status: completed
type: bug
priority: high
created_at: 2026-04-24T00:26:18Z
updated_at: 2026-04-24T00:33:52Z
sync:
    github:
        issue_number: "362"
        synced_at: "2026-04-24T00:35:02Z"
---

The JSON schema validates swiftiomatic.json but only enforces the base rule shape (rewrite: bool, lint: enum). Rule-specific enum properties like mode, style, placement, and accessLevel have no validation — a typo like "mode": "w" passes silently.

## Rules needing enum validation

- `singleLineBodies.mode`: wrap, inline
- `switchCases.style`: flush, indented
- `caseLet.placement`: eachBinding, outerPattern
- `extensionAccessControl.placement`: onDeclarations, onExtension
- `fileScopedDeclarationPrivacy.accessLevel`: private, fileprivate
- `imports.sortOrder`: alphabetical, length

## Rules needing other property schemas

- `uppercaseAcronyms.words`: [String]
- `fileHeader.text`: String?
- `noAssignmentInExpressions.allowedFunctions`: [String]
- `uRLMacro.macroName`, `moduleName`: String?

## Root cause

`ConfigurationSchemaGenerator.ruleSchemaNode()` only emits an allOf ref to ruleBase. `RuleCollector.DetectedSyntaxRule` doesn't collect custom config properties. The generator needs to scan configuration types for enum/string/array properties and emit them.

## Tasks

- [x] Extend DetectedSyntaxRule with custom properties
- [x] Extract enum cases and other properties from config types in RuleCollector
- [x] Emit properties in ConfigurationSchemaGenerator.ruleSchemaNode()
- [x] Regenerate schema.json and verify all 10 rules have correct constraints


## Summary of Changes

Extended the schema generator to emit custom property constraints for all 10 rule configuration types. The RuleCollector now extracts the generic config type from rule class inheritance, finds the config struct in the same file, and detects nested String-backed enums, string arrays, and optional strings. All enum properties now have valid value constraints in the schema.
