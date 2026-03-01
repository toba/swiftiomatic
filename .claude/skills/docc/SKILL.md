---
name: docc
description: |
  Write and maintain DocC documentation for Swift modules. Use when:
  (1) Creating new Documentation.docc catalogs
  (2) Writing or editing Main.md landing pages
  (3) Adding articles or guides to documentation
  (4) Documenting symbols with triple-slash comments
  (5) Organizing Topics sections
  (6) Adding images, diagrams, or code examples to docs
  (7) Fixing DocC build warnings or broken links
  (8) User mentions "documentation", "docc", "docs", or asks to document code
---

# DocC Documentation

Write documentation that builds correctly and follows Apple's DocC conventions.

## Quick Reference

### Documentation Comment Syntax

```swift
/// Summary sentence (becomes the abstract).
///
/// Discussion paragraph with additional context.
/// Can span multiple lines.
///
/// - Parameters:
///   - name: Description of the parameter.
///   - value: Another parameter description.
/// - Returns: What the function returns.
/// - Throws: ``ErrorType`` when something fails.
///
/// ## Example
/// ```swift
/// let result = myFunction(name: "test", value: 42)
/// ```
func myFunction(name: String, value: Int) throws -> String
```

### Symbol Linking

| Syntax | Use |
|--------|-----|
| `` ``TypeName`` `` | Link to type |
| `` ``TypeName/method`` `` | Link to member |
| `<doc:ArticleName>` | Link to article |

### Documentation Catalog Structure

```
ModuleName/
├── Sources/
│   └── *.swift
└── Documentation.docc/
    ├── Main.md           # Landing page (# ``ModuleName``)
    ├── Article.md        # Conceptual articles
    └── Resources/
        ├── image@2x.png      # Light mode
        └── image~dark@2x.png # Dark mode
```

### Main.md Template

```markdown
# ``ModuleName``

One-sentence summary of the module.

## Overview

Paragraph explaining the module's purpose and key concepts.

## Topics

### Group Name
- ``TypeName``
- ``TypeName/property``
- <doc:ArticleName>
```

### Article Template

```markdown
# Article Title

Summary sentence for the article.

## Overview

Introductory paragraph.

## Section Header

Content with code examples:

```swift
// Example code
```

![Image alt text](image-name)
```

## Project Conventions

This project follows specific DocC patterns. See [references/swiftiomatic-conventions.md](references/swiftiomatic-conventions.md) for project-specific rules including:
- Where documentation lives in the single-module structure
- How to document rules and analysis categories
- Cross-referencing between rule types and configuration

## Metadata Directives

Use `@Metadata` at the top of an article (after the title) to control page behavior and appearance:

```markdown
# My Sample Project

@Metadata {
    @PageKind(sampleCode)
    @CallToAction(url: "https://github.com/org/repo", purpose: link)
    @PageImage(purpose: card, source: "project-card", alt: "Screenshot of the project")
    @PageColor(green)
}

Summary sentence.
```

### @PageKind

Sets the page type and navigator icon. Values: `article` (default for `.md` files), `sampleCode`.

Sample code pages display "Sample Code" as the role heading (eyebrow text above the title) and get a distinct sidebar icon.

### @CallToAction

Adds a prominent button in the page header. Use with sample code pages to link to the source repo or download.

| Parameter | Description |
|-----------|-------------|
| `url` | External URL (use for repo links) |
| `file` | Local file path relative to the `.docc` bundle (use for downloads) |
| `purpose` | Default label: `link` → "Visit", `download` → "Download" |
| `label` | Custom button text (overrides `purpose` label) |

One of `url` or `file` required. One of `purpose` or `label` required. Only one `@CallToAction` per page.

```markdown
@Metadata {
    @CallToAction(url: "https://github.com/org/repo", label: "View on GitHub")
}
```

### @PageImage

Sets the card image shown when the page appears in a `@Links` grid. Also used as the page's icon.

```markdown
@PageImage(purpose: card, source: "my-image", alt: "Description")
```

The `source` references an image file in the `Resources/` directory (without extension). Supports `@2x` and `~dark` variants.

### @PageColor

Sets the accent color for the page. Built-in colors: `blue` (default), `green`, `yellow`, `orange`, `purple`, `red`.

```markdown
@PageColor(green)
```

## @Links Directive

Feature documentation pages with styled link collections anywhere on a page — outside the `## Topics` section.

```markdown
@Links(visualStyle: detailedGrid) {
    - <doc:SampleProject1>
    - <doc:SampleProject2>
    - <doc:GettingStartedGuide>
}
```

### visualStyle Options

| Style | Shows | Best for |
|-------|-------|----------|
| `list` | Title + abstract (matches Topics style) | General link lists |
| `compactGrid` | Card image + title only | Visual galleries, sample code collections |
| `detailedGrid` | Card image + title + abstract | Featured content with descriptions |

Card images come from `@PageImage(purpose: card, ...)` on the linked page. Pages without a card image still work but show a placeholder.

The directive can only contain `<doc:>` links — no headings or prose inside the block.

## Sample Code Page Template

A complete sample code page combining these directives:

```markdown
# Building a Custom Linter

@Metadata {
    @PageKind(sampleCode)
    @CallToAction(url: "https://github.com/org/custom-linter", purpose: link)
    @PageImage(purpose: card, source: "custom-linter-card", alt: "Custom linter running in Xcode")
    @PageColor(purple)
}

Learn how to build a custom Swift linter using Swiftiomatic's rule API.

## Overview

This sample project demonstrates creating rules, configuring severity,
and integrating with Xcode's build system.

## Topics

### Essentials
- <doc:CreatingYourFirstRule>
- ``Rule``
- ``RuleConfiguration``
```

### Featuring Sample Code from a Landing Page

On Main.md or a category page, use `@Links` to showcase sample projects:

```markdown
## Featured Sample Code

@Links(visualStyle: compactGrid) {
    - <doc:BuildingACustomLinter>
    - <doc:IntegratingWithXcode>
    - <doc:WritingFormatRules>
}
```

## Layout Directives

For rich layouts beyond standard Markdown:

```markdown
@Row {
    @Column {
        Paragraph text explaining a concept.
    }

    @Column {
        ![Description](image-name)
    }
}

@TabNavigator {
    @Tab("First") {
        Content for first tab.
    }

    @Tab("Second") {
        Content for second tab.
    }
}
```

## What NOT to Use DocC For

**Rule documentation** (examples, triggering/non-triggering code, corrections) must stay in the Swift type system — not DocC. The `RuleDescription` and `FormatRule` types carry structured data that DocC cannot express:

- `nonTriggeringExamples` / `triggeringExamples` arrays of `Example` with per-example configuration overrides and test metadata (`shouldTestMultiByteOffsets`, `shouldTestWrappingInComment`, etc.)
- `corrections` dictionary mapping before→after code for auto-fix validation
- FormatRule `examples` closures with string interpolation of runtime values (e.g. `VisibilityCategory.defaultOrdering(...)`)
- `options` / `sharedOptions` arrays consumed by `generate-docs` and CLI `--help`

This data is consumed programmatically at runtime (CLI help, `generate-docs` markdown output, test harnesses). DocC is a compile-time documentation system that produces HTML — it cannot serve these use cases.

**Use DocC for:** module-level overviews, conceptual articles, API symbol documentation, guides.
**Use RuleDescription/FormatRule for:** per-rule examples, configuration docs, triggering/non-triggering code.

## Common Issues

| Problem | Solution |
|---------|----------|
| Symbol not found | Verify symbol is `public`; use full path ``Module/Type/member`` |
| Image not showing | Check file is in Documentation.docc, correct naming (`@2x`, `~dark`) |
| Article not linked | Add `<doc:ArticleName>` to Topics section in Main.md |
| Build warning "No overview" | Add `## Overview` section after title |

## Validation

Build documentation to check for errors:

```bash
swift package generate-documentation --target Swiftiomatic
```
