//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A named group of related rules and settings in the configuration.
///
/// Groups appear as JSON objects at the config root. Rules and settings that
/// belong to a group are encoded inside their group's object; ungrouped items
/// live at the config root.
package enum ConfigGroup: String, CaseIterable, Sendable {
    case sort
    case wrap
    case hoist
    case forcing
    case comments
    case blankLines
    case lineBreaks
    case indentation
    case redundancies
    case capitalization
}

extension ConfigGroup: ConfigRepresentable {
    /// Non-rule settings owned by this group.
    package var configProperties: [ConfigProperty] {
        switch self {
        case .blankLines:
            [
                .init(
                    "maximumBlankLines",
                    .integer(
                        description: "Maximum consecutive blank lines.",
                        defaultValue: 1,
                        minimum: 0
                    )
                )
            ]
        case .lineBreaks:
            [
                .init(
                    "beforeControlFlowKeywords",
                    .bool(
                        description: "Break before else/catch after closing brace.",
                        defaultValue: false
                    )
                ),
                .init(
                    "beforeEachArgument",
                    .bool(
                        description: "Break before each argument when wrapping.",
                        defaultValue: false
                    )
                ),
                .init(
                    "beforeEachGenericRequirement",
                    .bool(
                        description: "Break before each generic requirement when wrapping.",
                        defaultValue: false
                    )
                ),
                .init(
                    "betweenDeclarationAttributes",
                    .bool(description: "Break between adjacent attributes.", defaultValue: false)
                ),
                .init(
                    "aroundMultilineExpressionChainComponents",
                    .bool(
                        description: "Break around multiline dot-chained components.",
                        defaultValue: false
                    )
                ),
                .init(
                    "beforeGuardConditions",
                    .bool(
                        description:
                            "Break before guard conditions. When true, all conditions start on a new line below guard. When false, the first condition stays on the same line as guard.",
                        defaultValue: true
                    )
                ),
            ]
        case .indentation:
            [
                .init(
                    "blankLines",
                    .bool(
                        description: "Add indentation whitespace to blank lines.",
                        defaultValue: false
                    )
                ),
                .init(
                    "conditionalCompilationBlocks",
                    .bool(
                        description: "Indent #if/#elseif/#else blocks.",
                        defaultValue: true
                    )
                ),
            ]
        default: []
        }
    }
}

/// Declares optional membership in a ``ConfigGroup``.
///
/// Items in a group encode/decode inside the group's JSON object.
/// Items with `nil` group live at the config root.
package protocol Groupable {
    /// The config group this item belongs to, or `nil` if ungrouped.
    static var group: ConfigGroup? { get }
}
