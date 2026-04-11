---
# hq3-wph
title: .swift-version file support
status: scrapped
type: task
priority: low
created_at: 2026-04-10T22:25:29Z
updated_at: 2026-04-11T21:32:07Z
parent: pms-xpz
sync:
    github:
        issue_number: "164"
        synced_at: "2026-04-11T22:00:31Z"
---

Read a \`.swift-version\` file (if present) to auto-configure the target Swift version for formatting and version-gated rules, matching the convention used by swiftenv and SwiftFormat.

## Tasks

- [ ] Check for \`.swift-version\` in project root during config loading
- [ ] Parse version string (e.g. \`6.2\`) and set \`formatSwiftVersion\` if not already configured
- [ ] Explicit \`formatSwiftVersion\` in \`.swiftiomatic.yaml\` takes precedence
- [ ] Add test
