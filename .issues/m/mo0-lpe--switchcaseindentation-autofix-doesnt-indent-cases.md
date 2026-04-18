---
# mo0-lpe
title: switchCaseIndentation autoFix doesn't indent cases relative to switch
status: completed
type: bug
priority: normal
created_at: 2026-04-18T04:41:44Z
updated_at: 2026-04-18T04:54:29Z
---

## Problem

Setting `"switchCaseIndentation": "autoFix"` in config does not indent `case`/`default` labels relative to the `switch` keyword. Cases remain at the same indentation level as `switch`:

```swift
switch macroName {
case "file":
    diagnose(.preferFileID, on: node)
    ...
case "fileID":
    return ExprSyntax(node)
default:
    return ExprSyntax(node)
}
```

Expected (cases indented one level from switch):

```swift
switch macroName {
    case "file":
        diagnose(.preferFileID, on: node)
        ...
    case "fileID":
        return ExprSyntax(node)
    default:
        return ExprSyntax(node)
}
```

## Analysis

Two independent mechanisms control switch-case indentation:

1. **`SwitchCaseIndentation` rule** (`Rules/Indentation/SwitchCaseIndentation.swift`) — a `SyntaxFormatRule` that *dedents* cases to align with `switch`. It does the **opposite** of what the user expects from "autoFix". It's opt-in (`isOptIn = true`).

2. **`indentSwitchCaseLabels` config** (`Configuration.swift`) — a boolean that tells the pretty-printer (`TokenStreamCreator`) to add an extra indent level to case labels. JSON key: `"indentation": { "switchCaseLabels": true }`. Default: `false`.

The rule only strips extra indentation — it never adds it. When cases are already flush with switch, the rule is a no-op. The actual "indent cases" behavior lives in the pretty-printer's `indentSwitchCaseLabels` flag, which is a completely separate config knob.

## TODO

- [x] Unified: single `SwitchCaseIndentation` rule with `style: flush | indented` config
- [x] Removed `indentSwitchCaseLabels` boolean; pretty-printer reads `switchCaseIndentation.style`
- [x] Tests cover both flush and indented styles (rule + pretty-print)


## Summary of Changes

Unified two separate switch-case indentation mechanisms into one:
- Removed `indentSwitchCaseLabels` boolean config and `switchCaseLabels` group setting
- `SwitchCaseIndentation` rule now has a `style` config: `flush` (default) or `indented`
- Pretty-printer reads from the same config
- Rule is bidirectional: enforces whichever style is configured
- Config JSON: `"switchCaseIndentation": { "mode": "autoFix", "style": "indented" }`
