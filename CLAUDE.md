# Swiftiomatic

AST-accurate Swift linting, formatting, and code analysis — used from Xcode, the command line, and by LLM agents.

## Important Agent Rules

- **When a jig issue references a cited source**, always look at the reference implementation first before designing anything. Cited repos are cloned at `~/Developer/<repo-name>-ref/`. Search it for the relevant feature, understand how they did it, then adapt that approach. Do not design from scratch when a working reference exists.
- When working on errors, always create a failing test first then fix the issue and confirm the test passes
- Always create a jig issue before beginning work
- Update the jig issue continuously as you work
- Use the xc-mcp services to build and test, but **only at the end of a work session or when the user asks**. Builds take a long time; don't build or test after every small change. Batch your work and verify once.
- Never git stash to avoid an error — FIX the error
- **Never directly edit generated files** (`*.generated.swift`). After adding, removing, or renaming rules, run `swift run GeneratePipeline` to regenerate `RuleRegistry+AllRules.generated.swift` and `LintPipeline.generated.swift`. The generator scans `Sources/SwiftiomaticKit/Rules/` for all `Rule`-conforming types.
- Rule example validation is handled by a single parameterized test in `Tests/SwiftiomaticTests/Rules/Infrastructure/RuleExampleTests.swift`. It iterates over all registered rules automatically — no per-rule test boilerplate needed. Rules that require SourceKit, compiler arguments, or cross-file collection are excluded. Rules with no examples are also excluded (see follow-up issue to populate missing examples).

## How It's Used

Swiftiomatic has three audiences. The same rules power all of them.

### 1. Xcode Build Phase (lint)

Works exactly like SwiftLint — add a Run Script phase:

```sh
if command -v sm >/dev/null 2>&1; then
    sm lint "$SRCROOT"
else
    echo "warning: sm not found — see https://github.com/toba/swiftiomatic"
fi
```

Xcode displays warnings and errors inline in the editor. Only rules with scope `.lint` run here.

### 2. Xcode Source Editor Extension (format)

Installs as an Xcode plugin that appears in **Editor > Swiftiomatic** with commands like "Format File", "Format Selection". Applies automatic corrections from all correctable rules.

Also available from the CLI: `sm format`.

### 3. Agent Analysis (analyze)

The all-in-one command for LLM agents. It auto-formats, lints, and surfaces suggestions in a single pass:

```sh
sm analyze Sources/ --format json
```

What it does:

1. **Formats** — applies all correctable rules (`.format` + correctable `.lint`), rewriting files in place. Use `--no-fix` to report only.
2. **Lints** — returns remaining `.lint` issues with their severity (warning/error).
3. **Suggests** — returns `.suggest` issues: research patterns for the agent to investigate.

The JSON response includes both lint and suggest findings, distinguished by their `scope` field. The agent uses severity, confidence, and scope to prioritize what to act on.

## Philosophy

Swiftiomatic **always errs on the side of false positives**. The calling agent has context the tool does not (project conventions, intent, history) and can dismiss findings that don't apply. A missed issue is worse than a noisy one — the agent can filter, but it can't find what was never reported.

## Rule Model

Every check is a **rule**. Rules are standalone `SyntaxVisitor` subclasses with two key properties:

### Scope

Where the rule participates. Every rule declares exactly one scope:

| Scope | Runs in | Purpose |
|---|---|---|
| **`.lint`** | Xcode Build Phase, `sm lint` | Definitive checks — wrong code, anti-patterns, style violations. Shows warnings/errors in the editor. |
| **`.format`** | Xcode Editor Extension, `sm format` | Formatting only — whitespace, indentation, brace placement. Never appears as a lint warning. |
| **`.suggest`** | `sm suggest` | Research patterns for agent investigation. Identifies code worth reviewing, not exact errors. Never part of lint or format runs on their own. |

### Correctable

Whether the rule can automatically rewrite the code it flags.

- **Correctable lint rules** show warnings in the Build Phase *and* apply their fixes when the formatter runs.
- **Format rules** are always correctable (that's their whole purpose).
- **Suggest rules** are never correctable — they require human or agent judgment.

When the formatter runs (Editor Extension or CLI), it applies corrections from all correctable rules in scope: all `.format` rules plus correctable `.lint` rules.

## Architecture

- **swift-syntax** for AST-accurate analysis — no grep heuristics
- **swift-argument-parser** CLI with subcommands: `lint`, `format`, `analyze` (format + lint + suggest in one pass), `list-rules`, `generate-docs`
- Two-pass architecture for cross-file checks (dead symbols, duplication): pass 1 collects declarations, pass 2 finds references
- Optional SourceKit enrichment for type-aware rules
- YAML configuration (`.swiftiomatic.yaml`) with nested per-directory overrides
- Installable via Homebrew

## Nested Configuration

`.swiftiomatic.yaml` files in subdirectories override the root config for files within that subtree:

```
MyApp/
  .swiftiomatic.yaml          # root: max_width 120, trailing_commas false
  Sources/
    .swiftiomatic.yaml        # overrides: max_width 80 (inherits trailing_commas)
  Packages/LegacySDK/
    .swiftiomatic.yaml        # inherit: false — ignores all parent configs
```

### Merge semantics

- Configs are collected leaf → root, then merged root → leaf (child wins)
- **Scalars**: child overrides parent
- **Arrays** (e.g. `rules.disabled`): child replaces parent entirely (no append)
- **Nested dicts** (e.g. `format`, `rules.config`): deep-merged key by key
- **`inherit: false`**: stops the chain — that file's config stands alone with defaults
- **`--config` flag**: bypasses chain resolution entirely, uses only the specified file

### Resolution

`ConfigurationResolver` caches the resolved config per directory. All files in the same directory share one resolved config. Format settings are per-directory; lint rule sets use the root config for cross-file consistency.

## Rule Categories

Rules span these areas regardless of scope:

- Generic consolidation & `Any` elimination
- Typed throws candidates
- Structured concurrency / GCD modernization
- Swift 6.2 modernization
- Performance anti-patterns
- Naming heuristics (Swift API Design Guidelines)
- Observation framework pitfalls

## Versioning

Version is defined in two places that must stay in sync:

1. **`Sources/SwiftiomaticKit/Models/SwiftiomaticVersion.swift`** — `SwiftiomaticVersion.current` controls CLI `--version` and internal code
2. **`MARKETING_VERSION`** build setting in the Xcode project — controls app and extension bundle version (use `xc-project set_build_setting` to update both targets)

Info.plists use `$(MARKETING_VERSION)` placeholders — never hardcode versions there.

## Swift & Build Settings

- swift-tools-version: 6.3
- Swift 6.3, `.swiftLanguageMode(.v6)`
- macOS 26+
- Build destination: **My Mac** (macOS only — no iOS target)

## Code Style Requirements

All code must use the latest Swift 6.3 and SwiftUI patterns. Refer to the global `/swift` skill for the full reference. Key rules:

### Swift Language

- **Typed throws**: use `throws(ErrorType)` when a function throws a single error type — don't leave throws untyped
- **`Mutex<Value>`** over `NSLock`/`os_unfair_lock`/serial `DispatchQueue` for state protection — enables proper `Sendable` without `@unchecked`
- **`weak let`** over `weak var` when the reference is never reassigned after init
- **`Task.immediate`** over `Task { }` when the body starts with work on the current actor (eliminates scheduling hop)
- **`@concurrent`** over `Task.detached` for offloading CPU-intensive async work (inherits task-locals)
- **`Span`/`RawSpan`** over `UnsafeBufferPointer`/`UnsafeRawBufferPointer` where possible
- **`InlineArray<N, T>`** over fixed-size tuples `(T, T, T, T)` used as buffers
- **`sending`** for values crossing actor isolation boundaries
- **`@c`** over `@_cdecl` for exposing Swift to C
- **`@specialize`** over `@_specialize` (no longer underscored)
- **No `Any`/`AnyObject`** unless bridging to ObjC — use generics, `some Protocol`, or concrete types
- **Eliminate `@unchecked Sendable`**: if only needed for metatype storage (`[any P.Type]`), remove it (SE-0470 SendableMetatype)

### SwiftUI (Xcode App & Extension)

- **`@Observable`** — never `ObservableObject`/`@Published`/`@StateObject`/`@ObservedObject`/`@EnvironmentObject`
- **`@Entry`** macro for custom `EnvironmentValues` — never `EnvironmentKey` boilerplate
- **`.fileImporter`/`.fileExporter`** — never `NSOpenPanel`/`NSSavePanel`
- **`.fileDialogBrowserOptions(.includeHiddenFiles)`** when config files (dotfiles) must be visible
- **`Observations` AsyncSequence** over `withObservationTracking` with recursive `onChange`
- **`NotificationCenter.Message`** structs over `Notification.Name` + untyped `userInfo`
- **`AttributedString`** over `NSAttributedString`/`NSMutableAttributedString`
- **MV pattern** (Model-View) by default — only introduce a ViewModel when it adds real logic beyond forwarding
- **View member ordering**: `@Environment` → `let` → `@State` → computed var → `init` → `body` → view builders → helpers
- **Stable view tree**: no top-level `if/else` swapping root branches — use single base view with conditional content inside
- **No `@MainActor`** on `View` conformances (already implied)

### Testing

- **Swift Testing** (`import Testing`, `@Test`, `#expect`) — never XCTest except for `measure()` performance tests
- **`#expect(throws:)`** over `XCTAssertThrowsError`
- **`try #require(x)`** over `XCTUnwrap`
- **`sourceLocation: SourceLocation = #_sourceLocation`** in helpers — not `file:`/`line:` pairs

## Output

JSON output per finding:

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

Text output also available for human readability.

Confidence levels: `high` (definitive), `medium` (likely true), `low` (needs review). All levels are reported — the consumer decides what to act on.
