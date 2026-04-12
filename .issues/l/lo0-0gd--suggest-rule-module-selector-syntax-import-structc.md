---
# lo0-0gd
title: 'Suggest rule: module selector syntax (import struct/class/func → ::)'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:27:04Z
updated_at: 2026-04-12T02:37:46Z
parent: ogh-b3l
sync:
    github:
        issue_number: "212"
        synced_at: "2026-04-12T03:13:35Z"
---

## Overview

Create a suggest-scope rule detecting verbose selective import syntax that can use the modern `::` module selector syntax.

## Patterns to detect

- [ ] `import struct ModuleA.TypeName` → `ModuleA::TypeName`
- [ ] `import class ModuleA.ClassName` → `ModuleA::ClassName`  
- [ ] `import func ModuleA.funcName` → `ModuleA::funcName`
- [ ] `import enum ModuleA.EnumName` → `ModuleA::EnumName`

## Notes

- Suggest scope — the `::` syntax is new and may not be widely adopted yet
- Simple to detect: look for `ImportDeclSyntax` with `importKindSpecifier` set
- Rule ID: `prefer_module_selector`
- Single rule file in `Rules/Modernization/Legacy/` or new `Rules/Modernization/Imports/`
