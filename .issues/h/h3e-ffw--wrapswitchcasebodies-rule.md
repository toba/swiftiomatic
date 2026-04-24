---
# h3e-ffw
title: WrapSwitchCaseBodies rule
status: in-progress
type: feature
priority: normal
created_at: 2026-04-24T22:31:12Z
updated_at: 2026-04-24T22:31:12Z
sync:
    github:
        issue_number: "384"
        synced_at: "2026-04-24T22:31:21Z"
---

Create a new SyntaxFormatRule that controls whether switch case bodies are wrapped (multiline) or inlined.

## Modes
- `wrap` — always multiline (body on its own line)
- `adaptive` — inline each case independently if it's a single statement fitting within print width; leave others wrapped

## Tasks
- [ ] Study existing rule patterns (WrapCompoundCaseItems, SingleLineBodies)
- [ ] Add configuration option with mode enum
- [ ] Create the rule implementation
- [ ] Create tests
- [ ] Register the rule in generated code
