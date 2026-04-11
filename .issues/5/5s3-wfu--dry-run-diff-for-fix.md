---
# 5s3-wfu
title: Dry-run diff for --fix
status: ready
type: feature
priority: normal
created_at: 2026-04-10T22:25:29Z
updated_at: 2026-04-10T22:25:29Z
parent: pms-xpz
sync:
    github:
        issue_number: "170"
        synced_at: "2026-04-11T01:01:47Z"
---

Show a unified diff of what \`--fix\` would change without modifying files. This lets teams review auto-corrections before applying them.

```bash
# Show diff without applying
swiftiomatic analyze Sources/ --fix --dry-run

# Apply after review
swiftiomatic analyze Sources/ --fix
```

## Tasks

- [ ] Add \`--dry-run\` flag to analyze and format commands
- [ ] Capture before/after content for each file during correction pass
- [ ] Output unified diff format to stdout
- [ ] Support \`--format json\` for dry-run (include diff per file in JSON output)
- [ ] Exit with non-zero status if changes would be made (useful for CI)
- [ ] Add tests for diff output
