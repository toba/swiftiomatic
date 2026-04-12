---
# 3zl-gq6
title: 'Document-based SwiftUI app: open/create .swiftiomatic.yaml'
status: ready
type: feature
priority: normal
created_at: 2026-04-12T15:40:32Z
updated_at: 2026-04-12T15:40:32Z
sync:
    github:
        issue_number: "223"
        synced_at: "2026-04-12T16:02:57Z"
---

Redesign the macOS app as a **document-based SwiftUI app** centered on `.swiftiomatic.yaml` files.

## Requirements

- [ ] App launch requires opening an existing `.swiftiomatic.yaml` or creating a new one
- [ ] New documents start with default rule configuration
- [ ] Standard "recently opened" list (Open Recent menu / welcome screen)
- [ ] Use SwiftUI `DocumentGroup` or `.fileImporter`/`.fileExporter` for native document handling
- [ ] File association: register `.swiftiomatic.yaml` as a supported document type

## Notes

- This shifts the app from a utility sidebar to a proper document-based workflow
- Each open document represents one project's Swiftiomatic configuration
- Standard macOS document behaviors apply: Cmd+O to open, Cmd+N for new, recent documents in File menu
