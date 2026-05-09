---
# mub-usx
title: sm update doesn't bump configuration schema version
status: completed
type: bug
priority: normal
created_at: 2026-05-09T17:39:37Z
updated_at: 2026-05-09T17:45:14Z
sync:
    github:
        issue_number: "685"
        synced_at: "2026-05-09T17:56:53Z"
---

After running `sm update` and accepting changes, the `version` field in swiftiomatic.json is not updated to the current `highestSupportedConfigurationVersion` (8). The update path only adds/removes/relocates rules; it never touches the version key.

## Plan
- Add `versionUpdate: (from: Int, to: Int)?` to `Configuration.UpdateDiff` (or equivalent fields).
- Expose `highestSupportedConfigurationVersion` package-internally.
- `computeUpdate` reads root["version"] and sets versionUpdate when older / missing.
- `hasChanges` includes versionUpdate.
- `applyUpdateText` rewrites the existing `"version": N` value, or inserts one if missing.
- `Update` subcommand prints the version bump and writes it.
- Tests cover bump, missing-version-add, no-change.

- [x] failing test
- [x] implement
- [x] verify all updateText/update tests pass



## Summary of Changes

- `Configuration.UpdateDiff` gained a `versionUpdate: VersionUpdate?` field; `hasChanges` now flags an outdated or missing `version`.
- `computeUpdate` reads the file's `version` and emits a `VersionUpdate(from:to:)` whenever it's missing, non-int, or below `highestSupportedConfigurationVersion` (now `package`).
- `Configuration.apply` writes `root["version"]` to the new value; `applyUpdateText` patches the existing `"version": N` value in place, or inserts a `version` line as the first root member when absent.
- `sm update` prints the schema bump and includes it in the post-apply summary.
- New tests cover in-place bump, missing-version insertion, and detection-only paths.
