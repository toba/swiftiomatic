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
import SwiftParser
import SwiftSyntax

/// Collects information about `Configurable` types (rules and layout settings) in the code base.
package final class ConfigurableCollector {
    /// Information about a detected rule.
    struct DetectedRule: Hashable {
        /// The type name of the rule.
        let typeName: String

        /// The custom key from `static let key = "..."`, or `nil` to derive from `typeName`.
        let customKey: String?

        /// The description of the rule, extracted from the rule class or struct DocC comment
        /// with `DocumentationCommentText(extractedFrom:)`.
        let description: String?

        /// The syntax node types visited by the rule type.
        let visitedNodes: [String]

        /// Indicates whether the rule can format code (all rules can lint).
        let canFormat: Bool

        /// The default handling for this rule (e.g. "fix", "warning", "off").
        let defaultHandling: String

        /// The config group this rule belongs to, or `nil` if ungrouped.
        let group: ConfigurationGroup?

        /// The config key for this rule (custom if set, otherwise camelCase type name).
        var ruleName: String {
            if let customKey { return customKey }
            return typeName.prefix(1).lowercased() + typeName.dropFirst()
        }
    }

    /// Information about a detected layout setting.
    struct DetectedSetting: Hashable {
        /// The type name of the setting (e.g. "LineLength").
        let typeName: String
    }

    /// A list of all rules that can lint (thus also including format rules) found in the code base.
    var allLinters = Set<DetectedRule>()

    /// A list of all the format-only rules found in the code base.
    var allFormatters = Set<DetectedRule>()

    /// A dictionary mapping syntax node types to the lint/format rules that visit them.
    var syntaxNodeLinters = [String: [String]]()

    /// All layout setting types found by scanning the settings directory.
    var allSettings = [DetectedSetting]()

    package init() {}

    /// Populates the internal collections with rules in the given directory.
    ///
    /// - Parameter url: The file system URL that should be scanned for rules.
    package func collectRules(from url: URL) throws {
        let fm = FileManager.default
        guard let rulesEnumerator = fm.enumerator(atPath: url.path) else {
            fatalError("Could not list the directory \(url.path)")
        }

        for baseName in rulesEnumerator {
            guard let baseName = baseName as? String, baseName.hasSuffix(".swift") else { continue }

            let fileURL = url.appendingPathComponent(baseName)
            let fileInput = try String(contentsOf: fileURL, encoding: .utf8)
            let sourceFile = Parser.parse(source: fileInput)

            for statement in sourceFile.statements {
                guard let detectedRule = self.detectedRule(at: statement) else { continue }

                if detectedRule.canFormat {
                    allFormatters.insert(detectedRule)
                }

                allLinters.insert(detectedRule)
                for visitedNode in detectedRule.visitedNodes {
                    syntaxNodeLinters[visitedNode, default: []].append(detectedRule.typeName)
                }
            }
        }
    }

    /// Populates `allSettings` by scanning for `LayoutRule` conformances.
    ///
    /// - Parameter url: The file system URL of the settings directory.
    package func collectSettings(from url: URL) throws {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: url.path) else {
            fatalError("Could not list the directory \(url.path)")
        }

        for baseName in enumerator {
            guard let baseName = baseName as? String, baseName.hasSuffix(".swift") else { continue }

            let fileURL = url.appendingPathComponent(baseName)
            let fileInput = try String(contentsOf: fileURL, encoding: .utf8)
            let sourceFile = Parser.parse(source: fileInput)

            for statement in sourceFile.statements {
                guard let setting = self.detectedSetting(at: statement) else { continue }
                allSettings.append(setting)
            }
        }

        allSettings.sort { $0.typeName < $1.typeName }
    }

    /// Detect a layout setting type (struct conforming to LayoutRule).
    private func detectedSetting(at statement: CodeBlockItemSyntax) -> DetectedSetting? {
        guard let structDecl = statement.item.as(StructDeclSyntax.self),
              let inheritanceClause = structDecl.inheritanceClause
        else { return nil }

        for inheritance in inheritanceClause.inheritedTypes {
            guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "LayoutRule"
            else { continue }
            return DetectedSetting(typeName: structDecl.name.text)
        }
        return nil
    }

    // MARK: - Rule detection

    /// Determine the rule kind for the declaration in the given statement, if any.
    private func detectedRule(at statement: CodeBlockItemSyntax) -> DetectedRule? {
        let typeName: String
        let members: MemberBlockItemListSyntax
        let maybeInheritanceClause: InheritanceClauseSyntax?
        let description = DocumentationCommentText(extractedFrom: statement.item.leadingTrivia)

        if let classDecl = statement.item.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
            members = classDecl.memberBlock.members
            maybeInheritanceClause = classDecl.inheritanceClause
        } else if let structDecl = statement.item.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
            members = structDecl.memberBlock.members
            maybeInheritanceClause = structDecl.inheritanceClause
        } else {
            return nil
        }

        guard let inheritanceClause = maybeInheritanceClause else {
            return nil
        }

        for inheritance in inheritanceClause.inheritedTypes {
            guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self) else {
                continue
            }

            let canFormat: Bool
            switch identifier.name.text {
            case "LintSyntaxRule":
                canFormat = false
            case "RewriteSyntaxRule":
                canFormat = true
            default:
                continue
            }

            var visitedNodes = [String]()
            for member in members {
                guard let function = member.decl.as(FunctionDeclSyntax.self) else { continue }
                guard function.name.text == "visit" else { continue }
                let params = function.signature.parameterClause.parameters
                guard let firstType = params.firstAndOnly?.type.as(IdentifierTypeSyntax.self) else {
                    continue
                }
                visitedNodes.append(firstType.name.text)
            }

            guard !visitedNodes.isEmpty else { return nil }
            return DetectedRule(
                typeName: typeName,
                customKey: Self.extractCustomKey(from: members),
                description: description?.text,
                visitedNodes: visitedNodes,
                canFormat: canFormat,
                defaultHandling: Self.extractDefaultHandling(from: members, canFormat: canFormat),
                group: Self.extractGroup(from: members)
            )
        }

        return nil
    }

    /// Extracts the custom `key` from `static let key = "..."` in the AST.
    private static func extractCustomKey(from members: MemberBlockItemListSyntax) -> String? {
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == "key"
            else { continue }

            if let initializer = binding.initializer?.value.as(StringLiteralExprSyntax.self),
                let segment = initializer.segments.firstAndOnly?.as(StringSegmentSyntax.self)
            {
                return segment.content.text
            }
        }
        return nil
    }

    /// Extracts `defaultHandling` from `static let defaultHandling: RuleHandling = .off` in the AST.
    private static func extractDefaultHandling(
        from members: MemberBlockItemListSyntax,
        canFormat: Bool
    ) -> String {
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == "defaultHandling"
            else { continue }

            if let initializer = binding.initializer?.value.as(MemberAccessExprSyntax.self) {
                return initializer.declName.baseName.text
            }

            if let accessorBlock = binding.accessorBlock,
                case .getter(let body) = accessorBlock.accessors
            {
                if let expr = body.first?.item.as(MemberAccessExprSyntax.self) {
                    return expr.declName.baseName.text
                }
                if let returnStmt = body.first?.item.as(ReturnStmtSyntax.self),
                    let expr = returnStmt.expression?.as(MemberAccessExprSyntax.self)
                {
                    return expr.declName.baseName.text
                }
            }
        }
        return canFormat ? "fix" : "warning"
    }

    /// Extracts `group` from `static let group: ConfigurationGroup? = .someCase` in the AST.
    private static func extractGroup(from members: MemberBlockItemListSyntax) -> ConfigurationGroup? {
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == "group"
            else { continue }

            let memberAccess: MemberAccessExprSyntax?

            if let initializer = binding.initializer?.value.as(MemberAccessExprSyntax.self) {
                memberAccess = initializer
            } else if let accessorBlock = binding.accessorBlock,
                case .getter(let body) = accessorBlock.accessors
            {
                if let expr = body.first?.item.as(MemberAccessExprSyntax.self) {
                    memberAccess = expr
                } else if let returnStmt = body.first?.item.as(ReturnStmtSyntax.self) {
                    memberAccess = returnStmt.expression?.as(MemberAccessExprSyntax.self)
                } else {
                    memberAccess = nil
                }
            } else {
                memberAccess = nil
            }

            if let memberAccess {
                return ConfigurationGroup(rawValue: memberAccess.declName.baseName.text)
            }
        }
        return nil
    }
}
