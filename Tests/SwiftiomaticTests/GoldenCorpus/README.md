# Golden Corpus

Byte-identity safety net for `RewriteCoordinator` output.

## Layout

- `Inputs/<name>.swift.fixture` — source inputs.
- `Snapshots/<name>.swift.golden` — expected output of `RewriteCoordinator.format` with
  the default configuration. Written by the harness.

The `.fixture` and `.golden` extensions are intentional: SPM ignores them, so no
`Package.swift` change is required and there's no risk of the fixtures being compiled or
linted by any tool that expects valid `.swift` files.

## Workflow

- **First time you add a fixture**: drop it under `Inputs/` and run the test. The harness
  writes the snapshot, records a non-fatal Issue (so CI surfaces unreviewed fixtures), and
  passes. Inspect the new snapshot, then commit both files.
- **Intentional formatter change**: re-run with `SWIFTIOMATIC_UPDATE_GOLDEN=1` to overwrite
  every snapshot, review the diff, then commit.
- **Pipeline refactor (the reason this harness exists)**: do *not* set the env var. Any
  drift fails the test with a per-line diff identifying which fixture and which lines
  changed.

```sh
# Verify
swift test --filter GoldenCorpusTests

# Regenerate after a deliberate change
SWIFTIOMATIC_UPDATE_GOLDEN=1 swift test --filter GoldenCorpusTests
```

## Adding a fixture

Pick something narrow and self-contained. The corpus is for catching architectural
regressions, not for replacing per-rule unit tests. Aim for a few dozen short files that
collectively exercise the rules you care about.
