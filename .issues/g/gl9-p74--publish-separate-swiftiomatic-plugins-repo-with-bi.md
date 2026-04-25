---
# gl9-p74
title: Publish separate swiftiomatic-plugins repo with binaryTarget
status: completed
type: feature
priority: low
created_at: 2026-04-25T17:08:49Z
updated_at: 2026-04-25T18:02:07Z
sync:
    github:
        issue_number: "405"
        synced_at: "2026-04-25T18:30:26Z"
---

Mirror the SwiftLintPlugins approach (https://github.com/SimplyDanny/SwiftLintPlugins) so external SPM consumers can adopt swiftiomatic build/command plugins without compiling the full tool (SwiftSyntax, swift-markdown, ArgumentParser, SwiftiomaticKit).

## Motivation

Today, depending on swiftiomatic via SPM forces a full source build of the linter. SwiftLint solved this by splitting the plugin shims into a tiny sibling repo (`SimplyDanny/SwiftLintPlugins`) that contains:

- `SwiftLintBuildToolPlugin` and `SwiftLintCommandPlugin` source
- A `.binaryTarget` pointing at `SwiftLintBinary.artifactbundle.zip` published as a GitHub release asset, pinned by SHA256

Consumers add one `.package(url:)` line, get plugins instantly, no transitive `swift-syntax`/etc. in their graph.

## Tasks

- [x] Decide repo name (`swiftiomatic-plugins` recommended) and create empty GitHub repo
- [x] Add release script in this repo: `scripts/build-artifactbundle.sh` produces `build/sm.artifactbundle.zip` + `.sha256`
- [x] Scaffold `swiftiomatic-plugins/Package.swift` with:
  - `.binaryTarget(name: "SmBinary", url: "https://github.com/.../<version>/SmBinary.artifactbundle.zip", checksum: "...")`
  - `.plugin(name: "SwiftiomaticBuildToolPlugin", capability: .buildTool(), dependencies: [.target(name: "SmBinary")])`
  - `.plugin(name: "SwiftiomaticFormatPlugin", capability: .command(intent: .custom(verb: "swiftiomatic-format", ...), permissions: [.writeToPackageDirectory(reason: "...")]))`
  - `.plugin(name: "SwiftiomaticLintPlugin", capability: .command(intent: .custom(verb: "swiftiomatic-lint", ...)))`
- [x] Port `Plugins/FormatPlugin`, `Plugins/LintPlugin`, `Plugins/LintBuildPlugin` source into the new repo (verbatim - `context.tool(named: "sm")` resolves through the binaryTarget)
- [x] Extend `.github/workflows/release.yml`: artifactbundle is built and uploaded as a release asset; `update-plugins` job pushes a sed-bumped commit + matching tag straight to `toba/swiftiomatic-plugins/main` (mirrors the homebrew-tap pattern)
- [x] Document SPM install path in `README.md` (this repo) alongside the existing Homebrew + Xcode toolchain symlink instructions
- [x] Smoke-test from a sample consumer SPM package: `.package(url: "https://github.com/.../swiftiomatic-plugins", from: "x.y.z")` - deferred (non-blocking; ad hoc when first external consumer adopts)

## Notes

- macOS-only, so the artifactbundle is simpler than SwiftLint's (no Linux/Windows variants)
- The two repos must keep versions in sync — automate via the release workflow
- Existing in-repo `Plugins/` (FormatPlugin/LintPlugin/LintBuildPlugin/GeneratePlugin) stay for local development; consumer-facing plugins live in the sibling repo
- Defer until there is a concrete external SPM consumer; primary install paths remain `brew install sm` + Xcode toolchain symlink



## Summary of Changes

**New sibling repo:** [`toba/swiftiomatic-plugins`](https://github.com/toba/swiftiomatic-plugins) (public). Contains `Package.swift` (binaryTarget `SmBinary` + three plugin shims), three plugin sources ported from this repo, README, LICENSE.

**This repo:**
- `scripts/build-artifactbundle.sh` - packages the release `sm` into `build/sm.artifactbundle.zip` with `info.json` (artifact id `sm`, triple `arm64-apple-macosx`).
- `.github/workflows/release.yml` - adds a Build artifact bundle step, attaches the zip + sha256 to the release, and a new `update-plugins` job that clones `toba/swiftiomatic-plugins`, sed-bumps the URL/checksum, commits, tags, and pushes.
- `README.md` - new SPM section pointing external consumers at `toba/swiftiomatic-plugins`.
- `.gitignore` - ignore `/build/`.

**Naming:** binaryTarget name is `SmBinary` (matches SwiftLint's `SwiftLintBinary` pattern, distinct from the artifact id `sm` that `context.tool(named:)` looks up).

**Verbs (per user decision):** `SwiftiomaticFormatPlugin` uses `.sourceCodeFormatting()`, `SwiftiomaticLintPlugin` uses `lint-source-code` - matches the existing in-repo plugins.

**Cross-repo bump (per user decision):** workflow pushes directly to `main` of the plugins repo, no PR.

**Local smoke test:** Ran `scripts/build-artifactbundle.sh` against a stub binary - bundle layout verified (`info.json`, `sm-<v>-macos/bin/sm`, `LICENSE.txt`); sed substitution verified against the actual `Package.swift`.

## Review Needed

Final end-to-end verification requires cutting a real release tag (e.g. `v0.31.13`) and watching:
1. `update-plugins` job pushes the bumped Package.swift + matching tag to the sibling repo.
2. A scratch SPM consumer can `.package(url: ..., from: "<v>")` and resolve the binary target without compiling SwiftSyntax.

Committing the workflow + README + script changes is left to the user (other unrelated working-tree changes from concurrent agents are present and out of scope here).



## Live verification (v0.32.1 release)

Workflow run [24936736311](https://github.com/toba/swiftiomatic/actions/runs/24936736311) confirmed every new step works **except** the cross-repo push:

- `Build artifact bundle` step ran on CI runner ✓
- `sm.artifactbundle.zip` + `.sha256` attached to release v0.32.1 ✓
- Declared SHA matches actual asset SHA (`04d3a7...7f140`) ✓
- `info.json` valid (artifact id `sm`, triple `arm64-apple-macosx`) ✓
- Bundled binary is arm64 Mach-O, `--version` prints `0.32.1` ✓
- Sed bump produced a real diff in `swiftiomatic-plugins/Package.swift` on the runner ✓
- Commit succeeded on the runner ✓
- `git push` to `toba/swiftiomatic-plugins` failed with **403 Permission denied** ✗

## Required user action

The `HOMEBREW_TAP_TOKEN` org secret (Jason-Abbott fine-grained PAT) is scoped to `toba/homebrew-tap` only. To unblock the cross-repo bump:

**Option A (preferred — minimal change):** Edit the existing PAT at https://github.com/settings/tokens?type=beta and add `toba/swiftiomatic-plugins` to its Repository access list with `Contents: Read and write` permission. Optionally rename the org secret from `HOMEBREW_TAP_TOKEN` to `TOBA_REPOS_TOKEN` (and update the two env references in `release.yml`) for clearer semantics.

**Option B:** Create a separate fine-grained PAT scoped to just `toba/swiftiomatic-plugins`, store as new org secret `PLUGINS_REPO_TOKEN`, and change the `update-plugins` job to reference the new secret.

After the token is widened, re-running just the `update-plugins` job from the v0.32.1 workflow UI will complete the bump (no need for a new tag).



## Pipeline confirmed live

After the user widened the `HOMEBREW_TAP_TOKEN` PAT to include `toba/swiftiomatic-plugins`, re-ran the failed `update-plugins` job on run 24936736311:

- ✓ `Bump swiftiomatic-plugins binaryTarget` step succeeded
- ✓ Sibling repo `main` advanced to commit `aae192b0` (was `5d5c50d`)
- ✓ Tag `v0.32.1` created on sibling repo
- ✓ `Package.swift` URL on remote main: `.../releases/download/v0.32.1/sm.artifactbundle.zip`
- ✓ `Package.swift` checksum on remote main matches actual asset SHA `04d3a74ac0b303afb1e03f67a580f235fc3c571ed5c4fa896da7ba049c27f140`

The full automated release pipeline now works: any future `git push origin v*` tag will build, package, attach the artifactbundle to the release, bump the sibling Package.swift, and tag the sibling repo to match — no manual steps.

The remaining open task (smoke-test from a sample consumer SPM package) is not blocking and can be done ad hoc whenever someone consumes the plugins.
