//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftSyntax
import ConfigurationKit

extension RuleCollector {
    protocol DetectedRule: Hashable {
        /// The type name of the rule.
        var typeName: String { get }
        /// The custom key from `static let key = "..."` , or `nil` to derive from `typeName` .
        var customKey: String? { get }

        /// The rule's DocC comment, normalized into schema description text by
        /// `DocumentationCommentText.normalized(from:)` .
        var documentation: String? { get }
        /// The config group this rule belongs to, or `nil` if ungrouped.
        var group: ConfigurationGroup? { get }
        /// The config key for this rule (custom if set, otherwise camelCase type name).
        var configKey: String { get }
    }

    /// A custom property on a rule's configuration type, for JSON Schema generation.
    struct DetectedProperty {
        /// The JSON key for this property (from CodingKeys or the property name).
        let key: String
        /// The schema node describing this property's type and constraints.
        let schemaNode: JSONSchemaNode
    }

    /// Information about a detected rule.
    struct DetectedSyntaxRule: DetectedRule {
        let group: ConfigurationGroup?
        let typeName: String
        let customKey: String?
        let documentation: String?

        /// Indicates whether the rule can rewrite code (all rules can lint).
        let canRewrite: Bool

        /// Indicates whether the rule's configuration uses dual numeric thresholds ( `enabled` /
        /// `warning` / `error` ) instead of a single `lint` severity.
        let isThreshold: Bool

        /// The syntax node types visited by the rule type.
        let visitedNodes: [String]

        /// Whether this rule is disabled by default (opt-in).
        let isOptIn: Bool

        /// Custom properties beyond `rewrite` / `lint` (or `enabled` / `warning` / `error` for
        /// threshold rules) on the configuration type.
        var customProperties: [DetectedProperty] = []
    }

    /// Information about a detected layout rule.
    struct DetectedLayoutRule: DetectedRule {
        /// The JSON Schema type inferred from a layout rule's `defaultValue` .
        enum SchemaValueType: Sendable {
            case boolean
            case integer
            case string
            case stringArray
            case stringEnum(values: [String], defaultValue: String)
        }

        let group: ConfigurationGroup?
        let typeName: String
        let customKey: String?
        let documentation: String?
        /// The JSON Schema type of this setting's value.
        let valueType: SchemaValueType
    }
}

extension RuleCollector.DetectedRule {
    /// The config key for this setting (custom if set, otherwise camelCase type name).
    var configKey: String {
        if let customKey { return customKey }
        return configurationKey(forTypeName: typeName)
    }

    // A rule type name is unique across the code base, so it stands in for the whole value.
    // Everything else on these types is metadata derived from the same declaration.
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.typeName == rhs.typeName }
    func hash(into hasher: inout Hasher) { hasher.combine(typeName) }
}
