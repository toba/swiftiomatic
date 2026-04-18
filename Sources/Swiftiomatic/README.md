# sm

The command-line interface for Swiftiomatic -- a drop-in replacement for `swift-format`.

## What It Does

Provides the user-facing CLI that parses arguments, loads configuration, iterates source files, and delegates to the `Swiftiomatic` library for formatting, linting, and analysis.

## Subcommands

| Command | Description |
|---|---|
| `sm format` | Auto-fix formatting issues in-place |
| `sm lint` | Report lint findings without modifying files |
| `sm analyze` | Format + lint + suggest in a single pass |
| `sm dump-configuration` | Print the resolved configuration as JSON |
| `sm list-rules` | List all available rules |
| `sm generate-docs` | Generate rule reference documentation |

## Structure

| Directory | Purpose |
|---|---|
| `Subcommands/` | Argument definitions and dispatch for each CLI subcommand |
| `Frontend/` | `LintFrontend`, `FormatFrontend`, `ConfigurationLoader` -- orchestrates file iteration, rule execution, and output |
| `Utilities/` | Diagnostics engine, TTY detection, terminal formatting |

## Where It Fits

This is the main executable product. Xcode invokes it as `swift-format` (via symlink), SPM plugins call it by name, and users run it directly from the terminal. It depends on the `Swiftiomatic` library for all rule logic and the `ArgumentParser` package for CLI parsing.

**Critical:** The `format`, `lint`, and `dump-configuration` subcommands and all their flags must remain compatible with upstream `swift-format` -- Xcode depends on this contract.
