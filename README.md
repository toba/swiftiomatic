# Swiftiomatic

AST-accurate Swift linting, formatting, and code analysis. A fork of [apple/swift-format](https://github.com/swiftlang/swift-format) with rules drawn from [SwiftFormat](https://github.com/nicklockwood/swiftformat) and [SwiftLint](https://github.com/realm/swiftlint), reorganised around a style-driven format pipeline.

The `sm` binary is a drop-in replacement for `swift-format`: the same `format`, `lint`, and `dump-configuration` subcommands and flags, plus extras (`doctor`, `link`, `update`).

## Style-driven configuration

Formatting is selected by a single `style` value rather than ~140 individual rule toggles. Universal layout settings (line length, indentation, line breaks) live alongside it.

```jsonc
{
    "$schema": "https://raw.githubusercontent.com/toba/swiftiomatic/refs/heads/main/schema.json",
    "version": 7,
    "style": "compact",
    "indentation": { "unit": { "spaces": 4 }, "tabWidth": 8 },
    "lineBreaks": { "lineLength": 100, "respectExistingLineBreaks": true }
}
```

Available styles:

| Style | Status |
|---|---|
| `compact` | Default. Prefers single-line constructs; wraps only when exceeding the line length. |
| `roomy` | Reserved name; not yet implemented. Selecting it fails fast. |

The CLI flag `--style <name>` overrides the configured style for a single invocation.

Lint behaviour is still configurable per-rule (`"lint": "no" | "warn" | "error"`) — rules-as-toggles only went away on the format side.

## CLI

```sh
sm format Sources/             # auto-fix in place
sm lint Sources/               # report findings without modifying files
sm dump-configuration          # print the resolved configuration
sm doctor                      # diagnose installation/configuration issues
sm link                        # install the Xcode toolchain symlink
sm update                      # update the configuration to the current schema version
```

## Installation

Build and install:

```sh
swift build -c release
cp .build/arm64-apple-macosx/release/sm /opt/homebrew/Cellar/sm/<version>/bin/sm
```

For Xcode IDE integration ("Format with swift-format" and the SPM plugins), see [CLAUDE.md](CLAUDE.md).
