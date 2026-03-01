---
# 55b-kur
title: Rename Configuration files/types to Options, eliminate RuleDescription
status: in-progress
type: epic
created_at: 2026-03-01T22:44:17Z
updated_at: 2026-03-01T22:44:17Z
---

Multi-step refactoring to establish correct naming convention and consolidate rule metadata.

## Tasks
- [ ] Task 1: Finish options rename (drop Rule+ prefix from files), commit
- [ ] Task 2: Add defaults to RuleConfiguration protocol
- [ ] Task 3: Add static var configuration to Rule protocol
- [ ] Task 4: Create Configuration types for all rules (~165 files)
- [ ] Task 5: Update infrastructure to use configuration instead of description
- [ ] Task 6: Update test infrastructure
- [ ] Task 7: Remove RuleDescription bridge and delete
