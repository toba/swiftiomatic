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
