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

import ConfigurationKit
import Foundation
import SwiftSyntax

extension RuleCollector {
    protocol DetectedRule: Hashable {
        /// The type name of the rule.
        var typeName: String { get }
        /// The custom key from `static let key = "..."`, or `nil` to derive from `typeName`.
        var customKey: String? { get }

        /// The description of the rule, extracted from the rule class or struct DocC comment
        /// with `DocumentationCommentText(extractedFrom:)`.
        var description: String? { get }
        /// The config group this rule belongs to, or `nil` if ungrouped.
        var group: ConfigurationGroup? { get }
        /// The config key for this rule (custom if set, otherwise camelCase type name).
        var configKey: String { get }
    }

    /// Information about a detected rule.
    struct DetectedSyntaxRule: DetectedRule {
        let group: ConfigurationGroup?
        let typeName: String
        let customKey: String?
        let description: String?

        /// Indicates whether the rule can rewrite code (all rules can lint).
        let canRewrite: Bool

        /// The syntax node types visited by the rule type.
        let visitedNodes: [String]

        /// Whether this rule is disabled by default (opt-in).
        let isOptIn: Bool
    }

    /// Information about a detected layout rule.
    struct DetectedLayoutRule: DetectedRule {
        let group: ConfigurationGroup?
        let typeName: String
        let customKey: String?
        let description: String?
    }
}

extension RuleCollector.DetectedRule {
    /// The config key for this setting (custom if set, otherwise camelCase type name).
    var configKey: String {
        if let customKey { return customKey }
        return configurationKey(forTypeName: typeName)
    }
}
