# Swiftiomatic

AST-accurate Swift linting, formatting, and code analysis — used from the IDE, CLI, and by LLM agents.

## Agent Rules

- Check cited sources first: repos cloned at `~/Developer/<repo-name>-ref/`. Don't design from scratch when a reference exists.
- Create a jig issue before starting work. Keep it updated as you go.
- Errors: write a failing test first, then fix, then confirm the test passes.
- Build/test with xc-mcp **only at session end or when asked**. Batch changes, verify once.
- Never git stash to dodge an error — fix it.
- Never edit `*.generated.swift`. Run `swift run GeneratePipeline` after adding/removing/renaming rules.
- Rule examples are validated by a single parameterized test in `Tests/SwiftiomaticTests/Rules/Infrastructure/RuleExampleTests.swift` — no per-rule test boilerplate.

### Diagnosing App UI

Use xc-mcp to build, launch, screenshot — don't guess.

1. `build_run_macos` (scheme: `Swiftiomatic`, bundle ID: `app.toba.swiftiomatic`)
2. `start_mac_log_cap` (use `level: debug` for verbose)
3. `screenshot_mac_window` to verify UI state
4. `show_mac_log` for historical logs
5. `stop_mac_log_cap` / `stop_mac_app` to clean up
6. `sample_mac_app` if slow or hanging

## CLI

```sh
sm lint Sources/          # lint only
sm format Sources/        # auto-fix only
sm analyze Sources/ --format json   # format + lint + suggest in one pass
sm list-rules
sm generate-docs
```

`analyze` formats (correctable rules), lints (remaining issues), and suggests (research patterns). Use `--no-fix` to report without rewriting.

## Rule Model

Rules are `SyntaxVisitor` subclasses. Each has a **scope** and may be **correctable**.

| Scope | Runs in | Purpose |
|---|---|---|
| `.lint` | Build phase, `sm lint` | Wrong code, anti-patterns, style. Warnings/errors in editor. |
| `.format` | Editor extension, `sm format` | Whitespace, indentation, braces. Never a lint warning. |
| `.suggest` | `sm suggest` | Research patterns for agent review. Never auto-fixed. |

Correctable lint rules fix on format. Format rules are always correctable. Suggest rules are never correctable.

**Philosophy**: prefer false positives over missed issues. The consumer filters.

**Grouping**: suggest-scope rules may group related patterns into one rule (e.g., `swiftui_view_anti_patterns` covers multiple view body smells). Lint and format rules must be one rule per concern — users need per-rule enable/disable control for anything that appears in the editor or auto-fixes.

## Architecture

- **swift-syntax** AST parsing (no grep heuristics)
- **swift-argument-parser** CLI
- Two-pass for cross-file checks: pass 1 collects, pass 2 references
- Optional SourceKit for type-aware rules
- `.swiftiomatic.yaml` config with nested per-directory overrides
- Homebrew installable

### Config Merge

Child `.swiftiomatic.yaml` overrides parent (leaf wins). Scalars: child wins. Arrays: child replaces. Dicts: deep-merged. `inherit: false` stops the chain. `--config` flag bypasses chain entirely. `ConfigurationResolver` caches per directory.

## Versioning

Keep in sync:
1. `Sources/SwiftiomaticKit/Models/SwiftiomaticVersion.swift` — `SwiftiomaticVersion.current`
2. `MARKETING_VERSION` build setting (use `xc-project set_build_setting` for both targets)

Never hardcode versions in Info.plists (they use `$(MARKETING_VERSION)`).

## Build Settings

- swift-tools-version: 6.3, `.swiftLanguageMode(.v6)`, macOS 26+
- macOS only — build destination: My Mac

## Code Style

Use latest Swift 6.3 and SwiftUI patterns. See `/swift` skill for full reference.

### Swift

- `throws(ErrorType)` when single error type
- `Mutex<Value>` over locks/serial queues
- `weak let` over `weak var` when never reassigned
- `Task.immediate` over `Task { }` for same-actor starts
- `@concurrent` over `Task.detached`
- `Span`/`RawSpan` over `UnsafeBufferPointer`/`UnsafeRawBufferPointer`
- `InlineArray<N, T>` over fixed-size tuples as buffers
- `sending` for cross-isolation values
- `@c` over `@_cdecl`, `@specialize` over `@_specialize`
- No `Any`/`AnyObject` unless ObjC bridging
- No `@unchecked Sendable` for metatype storage (SE-0470)

### SwiftUI

- `@Observable` only — no `ObservableObject`/`@Published`/`@StateObject`/`@ObservedObject`/`@EnvironmentObject`
- `@Entry` for `EnvironmentValues` — no `EnvironmentKey` boilerplate
- `.fileImporter`/`.fileExporter` — no `NSOpenPanel`/`NSSavePanel`
- `.fileDialogBrowserOptions(.includeHiddenFiles)` for dotfiles
- `Observations` AsyncSequence over recursive `withObservationTracking`
- `NotificationCenter.Message` over `Notification.Name` + `userInfo`
- `AttributedString` over `NSAttributedString`
- MV pattern default; ViewModel only when it adds real logic
- Member order: `@Environment` → `let` → `@State` → computed var → `init` → `body` → view builders → helpers
- Stable view tree: no top-level `if/else` swapping root branches
- No `@MainActor` on Views (already implied)

### Testing

- Swift Testing only (`@Test`, `#expect`) — XCTest only for `measure()`
- `#expect(throws:)` over `XCTAssertThrowsError`
- `try #require(x)` over `XCTUnwrap`
- `sourceLocation: SourceLocation = #_sourceLocation` in helpers

## Output

```json
{
  "ruleID": "typed-throws",
  "source": "lint",
  "severity": "warning",
  "confidence": "high",
  "file": "Sources/Foo.swift",
  "line": 42,
  "column": 5,
  "message": "Function 'parse' throws only ParseError but declares untyped 'throws'",
  "suggestion": "func parse() throws(ParseError)",
  "canAutoFix": true
}
```

Confidence: `high` (definitive), `medium` (likely), `low` (needs review). All reported — consumer decides.
