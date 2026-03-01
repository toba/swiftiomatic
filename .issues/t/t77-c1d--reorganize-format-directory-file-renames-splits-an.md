---
# t77-c1d
title: 'Reorganize Format/ directory: file renames, splits, and type renames'
status: completed
type: task
priority: normal
created_at: 2026-02-28T21:10:17Z
updated_at: 2026-02-28T21:25:17Z
sync:
    github:
        issue_number: "41"
        synced_at: "2026-03-01T01:01:36Z"
---

## Plan
- [x] Type renames: `_FormatRules` → `FormatRuleCatalog`, `_Descriptors` → `OptionDescriptorCatalog` (skipped `DeclarationType` → `DeclarationCategory` due to existing `DeclarationCategory` struct in OrganizeDeclarations.swift)
- [x] File renames: Engine→FormatEngine, FormattingHelpers→Formatter+FormattingHelpers, ParsingHelpers→Formatter+ParsingHelpers
- [x] Split SwiftFormat.swift → FormatPipeline.swift + FormatError.swift + Extensions
- [x] Split Options.swift → FormatOptions.swift + Version.swift + FileInfo.swift
- [x] Split Tokenizer.swift → Token.swift + Tokenizer.swift
- [x] Extract Visibility from Declaration.swift
- [x] Extract FileHandle+TextOutputStream from FormatCommand.swift
- [x] Move expandPath/stripMarkdown to Extensions/
- [x] Build verification
- [ ] Test verification (interrupted)

## Summary of Changes

### Type Renames (2 of 3)
- `_FormatRules` → `FormatRuleCatalog` (9 files)
- `_Descriptors` → `OptionDescriptorCatalog` (1 file)
- Skipped `DeclarationType` → `DeclarationCategory`: name collision with existing `DeclarationCategory` struct in OrganizeDeclarations.swift

### File Renames (3)
- `Engine.swift` → `FormatEngine.swift`
- `FormattingHelpers.swift` → `Formatter+FormattingHelpers.swift`
- `ParsingHelpers.swift` → `Formatter+ParsingHelpers.swift`

### File Splits (5 source files → 11 files)
- `SwiftFormat.swift` → `FormatPipeline.swift` + `FormatError.swift` + `Extensions/String+Path.swift` + `Extensions/String+Markdown.swift`
- `Options.swift` → `FormatOptions.swift` + `Version.swift` + `FileInfo.swift`
- `Tokenizer.swift` → `Token.swift` (706 lines) + `Tokenizer.swift` (1504 lines)
- `Declaration.swift` → extracted `Visibility.swift`
- `FormatCommand.swift` → extracted `Extensions/FileHandle+TextOutputStream.swift`

### Verification
- `swift build` passes (727 compiled)
