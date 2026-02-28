# Swiftiomatic Project DocC Conventions

Project-specific patterns for documentation in the Swiftiomatic codebase.

## Project Structure

Swiftiomatic is a single-module Swift Package (executable target `Swiftiomatic`) with a flat source layout:

```
Sources/Swiftiomatic/
├── Configuration/    # Config loading, lintable files
├── Extensions/       # String utilities, FileManager extensions
├── Format/           # Auto-formatting rules (SwiftFormat)
├── Lint/             # Lint analysis commands
├── Models/           # Shared data models
├── Rules/            # Rule definitions, registry, filtering, documentation
├── SourceKit/        # SourceKit integration
├── Suggest/          # Suggestion/refactoring analysis
├── Support/          # Glob, file discovery, utilities
└── swiftiomatic.swift  # CLI entry point
```

## Documentation Location

Single Documentation.docc catalog at:

```
Sources/Swiftiomatic/Documentation.docc/
├── Main.md           # Landing page: # ``Swiftiomatic``
└── Resources/        # Images, diagrams
```

## Module Name for Symbol Links

Use `Swiftiomatic` as the module name:

```markdown
# ``Swiftiomatic``              <!-- Landing page title -->
- ``Configuration``             <!-- Link to type -->
- ``RulesFilter``               <!-- Link to type -->
- ``SwiftFormat/format(_:)``    <!-- Link to member -->
```

## Documentation Priorities

Document in this order of importance:

1. **Rules** - Each rule's purpose, what it detects, examples of flagged code, and confidence level
2. **Analysis categories** - The 8 categories from CLAUDE.md (generic consolidation, typed throws, etc.)
3. **Configuration** - How `.swiftiomatic.yml` controls behavior
4. **JSON output format** - The finding schema (category, severity, confidence, etc.)
5. **CLI commands** - Entry points and arguments

## Rule Documentation Pattern

When documenting rules, follow the existing `RuleDocumentation` structure:

```swift
/// Detects redundant parentheses in expressions.
///
/// ## Example
///
/// ```swift
/// // Flagged:
/// if (condition) { }
///
/// // Preferred:
/// if condition { }
/// ```
///
/// - Confidence: high
/// - Category: style
```

## Adding New Documentation Files

When creating a new `.md` file in `Documentation.docc/`:

1. Create the article file
2. **Always update Main.md** with a `<doc:ArticleName>` link in the Topics section

## Validation

```bash
# Build documentation via Swift Package Manager
swift package generate-documentation --target Swiftiomatic

# Or via xcodebuild if an Xcode project exists
xcodebuild docbuild -scheme Swiftiomatic
```
