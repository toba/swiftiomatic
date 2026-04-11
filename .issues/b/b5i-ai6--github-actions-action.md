---
# b5i-ai6
title: GitHub Actions action
status: completed
type: feature
priority: normal
created_at: 2026-04-10T22:25:29Z
updated_at: 2026-04-11T21:31:58Z
parent: pms-xpz
sync:
    github:
        issue_number: "167"
        synced_at: "2026-04-11T22:00:31Z"
---

Provide a GitHub Action so teams can add Swiftiomatic to CI with minimal config:

```yaml
- uses: toba/swiftiomatic-action@v1
  with:
    command: analyze
    format: json
```

## Tasks

- [ ] Create \`action.yml\` with inputs for command, args, config path
- [ ] Support annotation output (map Xcode-format diagnostics to GitHub annotations)
- [ ] Pre-built binary download (avoid building from source in CI)
- [ ] Support \`--baseline\` for incremental adoption in CI (depends on baseline feature)
- [ ] Add example workflow to README
- [ ] Publish to GitHub Marketplace
