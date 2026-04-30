# sm

The command-line interface for Swiftiomatic -- a drop-in replacement for `swift-format`.

## What It Does

Provides the user-facing CLI that parses arguments, loads configuration, iterates source files, and delegates to `SwiftiomaticKit` for formatting and linting.

## Subcommands

| Command | Description |
|---|---|
| `sm format` | Auto-fix formatting issues in-place |
| `sm lint` | Report lint findings without modifying files |
| `sm dump-configuration` | Print the resolved configuration as JSON |
| `sm doctor` | Diagnose installation and configuration issues |
| `sm link` | Install the Xcode toolchain symlink for "Format with swift-format" |
| `sm update` | Migrate a configuration file to the current schema version |

`format`, `lint`, and `dump-configuration` accept `--style <compact|roomy>` to override the configured formatting style for a single invocation.

## Structure

| Directory | Purpose |
|---|---|
| `Subcommands/` | Argument definitions and dispatch for each CLI subcommand |
| `Frontend/` | `LintFrontend`, `FormatFrontend`, `ConfigurationLoader` -- orchestrates file iteration, rule execution, and output |
| `Utilities/` | Diagnostics engine, TTY detection, terminal formatting |

## Where It Fits

This is the main executable product. Xcode invokes it as `swift-format` (via symlink), SPM plugins call it by name, and users run it directly from the terminal. It depends on the `SwiftiomaticKit` library for all rule logic and the `ArgumentParser` package for CLI parsing.

**Critical:** The `format`, `lint`, and `dump-configuration` subcommands and all their flags must remain compatible with upstream `swift-format` -- Xcode depends on this contract.
