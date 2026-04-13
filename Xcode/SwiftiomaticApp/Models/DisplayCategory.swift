import SwiftiomaticSyntax

// MARK: - Category Group

/// Top-level section headers in the sidebar.
enum CategoryGroup: String, CaseIterable, Identifiable {
    case formatting = "Formatting"
    case codeQuality = "Code Quality"
    case language = "Language"
    case ecosystem = "Ecosystem"

    var id: String { rawValue }
}

// MARK: - Display Category

/// A user-facing rule category shown in the sidebar.
///
/// Maps from the code-level ``RuleCategory`` (derived from directory structure)
/// to a display-friendly grouping with name, icon, and section.
enum DisplayCategory: String, CaseIterable, Identifiable, Hashable {
    // Formatting
    case blankLines
    case spacing
    case bracesAndIndentation
    case punctuationAndLineEndings
    case lineWrapping

    // Code Quality
    case redundantExpressions
    case redundantSyntax
    case redundantDeclarations
    case redundantVisibility
    case deadCode
    case performance
    case metrics

    // Language
    case accessControl
    case closuresAndReturns
    case conditionalsAndPatterns
    case naming
    case ordering
    case typeSafety

    // Ecosystem
    case concurrency
    case legacyCode
    case foundation
    case swiftUI
    case documentation
    case testing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blankLines: "Blank Lines"
        case .spacing: "Spacing"
        case .bracesAndIndentation: "Braces & Indentation"
        case .punctuationAndLineEndings: "Punctuation & Line Endings"
        case .lineWrapping: "Line Wrapping"
        case .redundantExpressions: "Redundant Expressions"
        case .redundantSyntax: "Redundant Syntax"
        case .redundantDeclarations: "Redundant Declarations"
        case .redundantVisibility: "Redundant Visibility"
        case .deadCode: "Dead Code"
        case .performance: "Performance"
        case .metrics: "Metrics"
        case .accessControl: "Access Control"
        case .closuresAndReturns: "Closures & Returns"
        case .conditionalsAndPatterns: "Conditionals & Patterns"
        case .naming: "Naming"
        case .ordering: "Ordering"
        case .typeSafety: "Type Safety"
        case .concurrency: "Concurrency"
        case .legacyCode: "Legacy Code"
        case .foundation: "Foundation"
        case .swiftUI: "SwiftUI"
        case .documentation: "Documentation"
        case .testing: "Testing"
        }
    }

    var symbolName: String {
        switch self {
        case .blankLines: "line.3.horizontal"
        case .spacing: "arrow.left.and.right"
        case .bracesAndIndentation: "increase.indent"
        case .punctuationAndLineEndings: "ellipsis.circle"
        case .lineWrapping: "arrow.turn.down.left"
        case .redundantExpressions: "minus.circle"
        case .redundantSyntax: "scissors"
        case .redundantDeclarations: "doc.on.doc"
        case .redundantVisibility: "eye.slash"
        case .deadCode: "leaf"
        case .performance: "gauge.with.dots.needle.bottom.50percent"
        case .metrics: "ruler"
        case .accessControl: "lock"
        case .closuresAndReturns: "arrow.uturn.left"
        case .conditionalsAndPatterns: "arrow.triangle.branch"
        case .naming: "character.cursor.ibeam"
        case .ordering: "arrow.up.arrow.down"
        case .typeSafety: "shield"
        case .concurrency: "arrow.triangle.2.circlepath"
        case .legacyCode: "clock.arrow.circlepath"
        case .foundation: "building.columns"
        case .swiftUI: "swift"
        case .documentation: "doc.text"
        case .testing: "checkmark.circle"
        }
    }

    var group: CategoryGroup {
        switch self {
        case .blankLines, .spacing, .bracesAndIndentation, .punctuationAndLineEndings, .lineWrapping:
            .formatting
        case .redundantExpressions, .redundantSyntax, .redundantDeclarations, .redundantVisibility,
            .deadCode, .performance, .metrics:
            .codeQuality
        case .accessControl, .closuresAndReturns, .conditionalsAndPatterns, .naming, .ordering, .typeSafety:
            .language
        case .concurrency, .legacyCode, .foundation, .swiftUI, .documentation, .testing:
            .ecosystem
        }
    }

    /// Maps a code-level ``RuleCategory`` to a display category.
    static func from(_ category: RuleCategory) -> DisplayCategory {
        let key = if let sub = category.subcategory {
            "\(category.name)/\(sub)"
        } else {
            category.name
        }
        return switch key {
        case "whitespace/verticalspacing": .blankLines
        case "whitespace/horizontalspacing": .spacing
        case "whitespace/braces": .bracesAndIndentation
        case "whitespace/punctuation", "whitespace/lineendings": .punctuationAndLineEndings
        case "multiline/alignment", "multiline/arguments", "multiline/wrapping": .lineWrapping
        case "redundancy/expressions": .redundantExpressions
        case "redundancy/syntax": .redundantSyntax
        case "redundancy/modifiers", "redundancy/types": .redundantDeclarations
        case "redundancy/visibility": .redundantVisibility
        case "deadcode/duplication", "deadcode/unused": .deadCode
        case "performance/algorithms", "performance/collections": .performance
        case "metrics/complexity", "metrics/length": .metrics
        case "accesscontrol/modifiers", "accesscontrol/scope": .accessControl
        case "controlflow/closures", "controlflow/returns": .closuresAndReturns
        case "controlflow/conditionals", "controlflow/patterns": .conditionalsAndPatterns
        case "naming/files", "naming/identifiers": .naming
        case "ordering/sorting", "ordering/structure": .ordering
        case "typesafety/correctness", "typesafety/optionals", "typesafety/types": .typeSafety
        case "modernization/concurrency": .concurrency
        case "modernization/legacy": .legacyCode
        case "frameworks/foundation": .foundation
        case "frameworks/swiftui": .swiftUI
        case "documentation/annotations", "documentation/comments": .documentation
        case "testing/assertions", "testing/practices": .testing
        default: .metrics
        }
    }

    /// All display categories belonging to a group, in declaration order.
    static func categories(in group: CategoryGroup) -> [DisplayCategory] {
        allCases.filter { $0.group == group }
    }
}
