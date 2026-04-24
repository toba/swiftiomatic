# Swiftiomatic

AST-accurate Swift linting, formatting, and code analysis — used from the IDE, CLI, and by LLM agents.

## Agent Rules

- Check cited sources first: repos cloned at `~/Developer/<repo-name>-ref/`. Don't design from scratch when a reference exists.
- Create a jig issue before starting work. Keep it updated as you go.
- Test first: before writing any fix or feature code, create a test that reproduces the bug or asserts the desired behavior. Confirm it fails (or is absent), then implement the solution, then confirm the test passes.
- Build/test with xc-mcp **only at session end or when asked**. Batch changes, verify once.
- Never git stash to dodge an error — fix it.

## Installation

This is a fork of [apple/swift-format](https://github.com/swiftlang/swift-format) with an identical CLI surface (`format`, `lint`, `dump-configuration` subcommands and all flags). The `sm` binary is a drop-in replacement for `swift-format`.

**CRITICAL: Never rename, remove, or alter any swift-format subcommands or flags in `Sources/sm/`.** Xcode calls this binary as `swift-format` — the CLI contract must stay identical. New subcommands and flags (like `analyze`, `list-rules`) may be added, but the existing surface (`format`, `lint`, `dump-configuration` and all their flags) must match upstream.

### Build and install

```sh
swift build -c release
cp .build/arm64-apple-macosx/release/sm /opt/homebrew/Cellar/sm/<version>/bin/sm
```

Homebrew manages the symlink `/opt/homebrew/bin/sm` → `../Cellar/sm/<version>/bin/sm`.

### Xcode IDE integration

Xcode's "Format with swift-format" (Editor menu) resolves the binary via `xcrun --find swift-format`, which points to:
```
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-format
```

This is symlinked to `/opt/homebrew/bin/sm`:
```sh
sudo ln -sf /opt/homebrew/bin/sm \
  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-format
```

This path is **not** SIP-protected — only `sudo` is needed, no SIP disable. After a release build + copy to the Cellar path, Xcode picks up new rules immediately via the symlink chain.

**Xcode updates will overwrite the symlink** — re-run the `ln` command after updating Xcode.

Three invocation paths all work through this:
1. **Editor → "Format with swift-format"** — calls `swift-format format` on the file via stdin with `--assume-filename`, `--lines`/`--offsets`
2. **SPM plugins** ("Format Source Code", "Lint Source Code") — invoke the `sm` binary by name with `format --recursive --parallel --in-place`, available via right-click in Xcode's project navigator
3. **CLI** — `sm format`, `sm lint`, etc. directly

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

Based on [apple/swift-format](https://github.com/swiftlang/swift-format) (reference clone at `~/Developer/swiftiomatic-ref/swift-format`). Two rule base classes:

| Base Class | Inherits | Purpose |
|---|---|---|
| `SyntaxLintRule` | `SyntaxVisitor` + `Rule` | Read-only analysis. Emits findings via `diagnose()`. |
| `SyntaxFormatRule` | `SyntaxRewriter` + `Rule` | Transforms syntax AND emits findings. Returns modified nodes. |

Lint rules are interleaved in a single `LintPipeline` tree walk. Format rules run sequentially in `FormatPipeline`, each over the entire tree. Both pipelines are auto-generated.

Format rules default to `.fix` (auto-fix), lint rules to `.warning`. Override `defaultHandling` to `.off` for opt-in rules.

**Philosophy**: prefer false positives over missed issues. The consumer filters.

## Architecture

Follows [apple/swift-format](https://github.com/swiftlang/swift-format) architecture:

- **swift-syntax** AST parsing (no grep heuristics)
- **swift-argument-parser** CLI
- `Rule` protocol → `SyntaxLintRule` (visitor) / `SyntaxFormatRule` (rewriter)
- `Finding` with `Message`, `Location`, `Note` — emitted via `diagnose()` on `Rule`
- `Context` holds `Configuration`, `FindingEmitter`, `RuleMask`, `SourceLocationConverter`
- `LintPipeline` interleaves lint rules per node; `FormatPipeline` runs format rules sequentially
- `RuleMask` disables rules via `// sm:ignore` comments
- `swiftiomatic.json` config (JSON5); `Configuration.rules: [String: Bool]` enables/disables rules
- Rule-specific config via nested structs on `Configuration` (e.g., `orderedImports`, `fileScopedDeclarationPrivacy`)
- Homebrew installable

### Code Generation

Generated files are produced automatically via the `GenerateCode` SPM build tool plugin on every build. The plugin runs the `Generator` executable, which scans rule and layout source files and writes:

- `Pipelines+Generated.swift` — `visit()` dispatchers for `LintPipeline` + `RewritePipeline.rewrite()`
- `ConfigurationRegistry+Generated.swift` — type arrays for all rules and settings
- `TokenStream+Generated.swift` — forwarding stubs for `TokenStream` subclass

These files live in `Sources/SwiftiomaticKit/Generated/` (excluded from source compilation; the plugin writes to its work directory).

To regenerate `schema.json` (not part of the build plugin):
```sh
swift run Generator
```

**Never edit `*+Generated.swift` directly.**

## Versioning

Managed via Homebrew formula. Version is the Cellar directory name (e.g. `0.26.11`).

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

## Findings

Rules emit `Finding` values via `diagnose(_:on:anchor:notes:)`:

```swift
Finding(
  category: RuleBasedFindingCategory,  // rule name
  message: Finding.Message,            // "remove ';'"
  location: Finding.Location?,         // file, line, column
  notes: [Finding.Note]                // additional detail
)
```

Messages are defined as `Finding.Message` extensions on each rule file. Use string literals or interpolation.
