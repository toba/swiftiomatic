# Developing Swiftiomatic

## Keeping the Pipeline Updated

Since Swift does not yet have a runtime reflection system, we use code
generation to keep the linting/formatting pipeline up-to-date. The
`Generator` executable is run automatically by an SPM build tool plugin
on every build. It scans rule and layout source files and writes:

- `Pipelines+Generated.swift` — `visit()` dispatchers for `LintPipeline` + `RewritePipeline.rewrite()`
- `ConfigurationRegistry+Generated.swift` — type arrays for all rules and settings
- `TokenStream+Generated.swift` — forwarding stubs for `TokenStream` subclass

These files live in `Sources/SwiftiomaticKit/Generated/` (excluded from
source compilation; the plugin writes to its work directory).

To regenerate `schema.json` (not part of the build plugin):

```shell
swift run Generator
```

**Never edit `*+Generated.swift` directly.**

## Command Line Options for Debugging

`sm` provides some hidden command line options to facilitate debugging
during development:

* `--debug-disable-pretty-print`: Disables the pretty-printing pass of the
  formatter, causing only the syntax tree transformations in the first phase
  pipeline to run.

* `--debug-dump-token-stream`: Dumps a human-readable indented structure
  representing the pseudotoken stream constructed by the pretty printing
  phase.
