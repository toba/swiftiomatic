# Swiftiomatic

AST-accurate Swift linting, formatting, and code analysis. A fork of [apple/swift-format](https://github.com/swiftlang/swift-format) with additional rules drawn from [SwiftFormat](https://github.com/nicklockwood/swiftformat) and [SwiftLint](https://github.com/realm/swiftlint).

The `sm` binary is a drop-in replacement for `swift-format`: the same `format`, `lint`, and `dump-configuration` subcommands and flags, plus extras (`doctor`, `link`, `update`).

## Configuration

Configuration is JSON5. Format and lint are both per-rule, with universal layout settings (line length, indentation, line breaks) alongside.

```jsonc
{
    "$schema": "https://raw.githubusercontent.com/toba/swiftiomatic/refs/heads/main/schema.json",
    "version": 8,
    "indentation": { "unit": { "spaces": 4 }, "tabWidth": 8 },
    "lineBreaks": { "lineLength": 100, "respectExistingLineBreaks": true }
}
```

Each rule accepts `"rewrite": true | false` (format side) and `"lint": "no" | "warn" | "error"` (lint side). Format rules default to active; lint rules default to `"warn"`.

## Ignoring rules in source

Suppress a rule from a comment with `// sm:ignore`. Swiftiomatic recognizes the `sm:` prefix alone, so the upstream `// swift-format-ignore` and `// swift-format-ignore-file` comments have **no effect**.

A bare directive suppresses every rule. Naming rules after it suppresses only those. Both the configuration key (`useTrailingClosures`) and the type name (`UseTrailingClosures`) resolve.

| Form | Scope |
|---|---|
| `// sm:ignore` on its own line | from that line to the end of the file |
| `// sm:ignore:next` on its own line | the next statement or member |
| `// sm:ignore` after code | that statement only |

```swift
// both rules off for the rest of the file
// sm:ignore fileLength, typeBodyLength

// one rule off for the call below
// sm:ignore:next useTrailingClosures
try withoutActuallyEscaping({ ... }, do: { ... })

let x = "trouble"  // sm:ignore
```

Text after the rule list is a free-form comment: `// sm:ignore:next UseSelfNotTypeName the generic parameter shadows it`.

A directive disables the pretty printer too, so the node it covers keeps its existing line breaks and indentation.

On a multi-line statement, a trailing directive attaches on the opening line or the closing line. An interior line scopes it to the inner statement instead. See [Documentation/IgnoringSource.md](Documentation/IgnoringSource.md) for the full rules.

## CLI

```sh
sm format Sources/             # auto-fix in place
sm lint Sources/               # report findings without modifying files
sm dump-configuration          # print the resolved configuration
sm doctor                      # diagnose installation/configuration issues
sm link                        # install the toolchain symlink in every installed Xcode
sm update                      # update the configuration to the current schema version
```

### Reporters

`sm lint --reporter` selects the output format:

| Value | Output |
|---|---|
| `text` | Human-readable diagnostics on stderr (default) |
| `json` | A JSON array of findings on stdout |
| `sarif` | A [SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html) log on stdout |

In a SARIF log, each result has the rule name as its `ruleId`. A parser diagnostic has the `ruleId` `parser`. A tool diagnostic, such as a file that cannot be read, has the `ruleId` `tool`. A file inside the working directory gets a URI relative to `%SRCROOT%`.

`sm format` accepts `text` and `json` only.

GitHub code scanning shows SARIF results as annotations on the pull request diff:

```yaml
- run: sm lint --recursive --reporter sarif Sources > sm.sarif || true
- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: sm.sarif
    category: sm
```

## Installation

Build and install:

```sh
swift build -c release
cp .build/arm64-apple-macosx/release/sm /opt/homebrew/Cellar/sm/<version>/bin/sm
```

For Xcode IDE integration ("Format with swift-format" and the SPM plugins), see [CLAUDE.md](CLAUDE.md).
