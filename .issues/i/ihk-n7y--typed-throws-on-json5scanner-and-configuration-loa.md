---
# ihk-n7y
title: Typed throws on JSON5Scanner and configuration loaders
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:42:07Z
updated_at: 2026-04-25T21:47:29Z
parent: 0ra-lks
sync:
    github:
        issue_number: "421"
        synced_at: "2026-04-25T22:35:10Z"
---

Several functions throw a single concrete error type but declare untyped `throws`.

## Findings

- [x] `Sources/SwiftiomaticKit/Configuration/JSON5Scanner.swift` — all internal lex/parse methods (10 sites: `parseDocument`, `parseObject`, `parseKey`, `parseValue`, `skipArray`, `Lexer.expect`, `Lexer.consume`, `Lexer.advance`, `Lexer.lexString`, `Lexer.lexNumber`) narrowed to `throws(JSON5Scanner.Error)` / `throws(Error)`.
- [ ] `Sources/SwiftiomaticKit/Configuration/Configuration+UpdateText.swift:16` — `applyUpdateText(...)` body only throws `JSON5Scanner.Error` (via `parseDocument`), but the function is `package` and `JSON5Scanner` is internal — Swift refuses to advertise a `package` API with an internal-typed thrown error. Promoting `JSON5Scanner` (or just its `Error`) to `package` for one error type expands the public surface area too much. Left as untyped `throws` with an inline comment noting the rationale.
- [ ] `Sources/Swiftiomatic/Frontend/ConfigurationLoader.swift:28, 39` — `configuration(forPath:)` and `configuration(at:)` propagate errors from `Configuration(contentsOf:)` which can throw Foundation errors (CocoaError from `Data(contentsOf:)`), `DecodingError`, *and* `SwiftiomaticError.unsupportedConfigurationVersion`. Multiple unrelated error types — no single-type narrowing possible without wrapping. Skipped.
- [x] `Sources/Swiftiomatic/Subcommands/Doctor.swift:73` — `findConfiguration()` only throws `ExitCode.failure`. Narrowed to `throws(ExitCode)`.
- [ ] `Sources/Swiftiomatic/Subcommands/Update.swift:89` — `findConfiguration()` throws both `ExitCode.failure` AND propagates `Data(contentsOf:)` errors directly (line 108). Not single-typed without wrapping the data-read into a `do/catch` like `Doctor` does. Skipped to avoid behavior change.
- [ ] `Sources/Swiftiomatic/Subcommands/Update.swift:114` — `encodeDefaultConfiguration()` throws `EncodingError` (from `JSONEncoder.encode`) AND `DecodingError` (from `JSONDecoder.decode`). Two unrelated error types. Skipped.

## Verification
- [x] Build clean.
- [x] Targeted tests pass: 51/51 (`JSON5Scanner` + `Configuration` suites).

## Summary of Changes

**`JSON5Scanner.swift`** — 10 internal methods narrowed to typed throws:
- `static func parseDocument(_:) throws(Error) -> ObjectLayout`
- `parseObject() throws(Error) -> ObjectLayout`
- `parseKey() throws(Error) -> (String, Range<String.Index>)`
- `parseValue() throws(Error) -> ObjectLayout?`
- `skipArray() throws(Error)`
- `Lexer.expect(_:) throws(JSON5Scanner.Error) -> Token`
- `Lexer.consume(_:) throws(JSON5Scanner.Error) -> Token`
- `Lexer.advance() throws(JSON5Scanner.Error)`
- `Lexer.lexString(quote:) throws(JSON5Scanner.Error)`
- `Lexer.lexNumber() throws(JSON5Scanner.Error)`

**`Doctor.swift`** — `findConfiguration(diagnosticsEngine:) throws(ExitCode) -> (URL, Data)`.

**Other findings deferred** — see Findings above. Each has a concrete reason the narrowing breaks: package/internal access mismatch, multiple unrelated error types, or `Foundation` errors mixed with sentinel `ExitCode` throws.
