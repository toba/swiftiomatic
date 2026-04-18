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
public enum ConfigGroup: String, CaseIterable, Sendable {
    case sort
    case wrap
    case capitalization
    case removeRedundant
    case updateBlankLines
    case updateLineBreak

    /// Prefix stripped from rule names to derive short config option names.
    ///
    /// E.g., `removeRedundant` strips `"Redundant"` so `RedundantSelf` becomes `"self"`.
    /// Groups with no common prefix (like `capitalization`) use an empty string,
    /// meaning option names are the full rule name lowercased.
    public var rulePrefix: String {
        switch self {
        case .sort: "Sort"
        case .wrap: "Wrap"
        case .capitalization: ""
        case .removeRedundant: "Redundant"
        case .updateBlankLines: "BlankLines"
        case .updateLineBreak: "Linebreak"
        }
    }
}

/// Declares optional membership in a ``ConfigGroup``.
///
/// Items in a group encode/decode inside the group's JSON object.
/// Items with `nil` group live at the config root.
public protocol Groupable {
    /// The config group this item belongs to, or `nil` if ungrouped.
    static var group: ConfigGroup? { get }
}
