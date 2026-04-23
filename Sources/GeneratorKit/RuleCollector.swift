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

/// Collects information about rules in the code base.
package final class RuleCollector {
    /// All layout setting types found by scanning the settings directory.
    var layoutRules = [DetectedLayoutRule]()

    /// A dictionary mapping syntax node types to the lint/format rules that visit them.
    var syntaxNodeLinters = [String: [String]]()

    /// A list of all rules that can lint (thus also including format rules) found in the code base.
    var lintingSyntaxRules = Set<DetectedSyntaxRule>()

    /// A list of all the format-only rules found in the code base.
    var rewritingSyntaxRules = Set<DetectedSyntaxRule>()

    package init() {}

    /// Populates the internal collections with rules in the given directory.
    ///
    /// - Parameter url: The file system URL that should be scanned for rules.
    package func collectSyntaxRules(from url: URL) throws {
        try enumerateSwiftStatements(in: url) { statement in
            guard let rule = self.detectSyntaxRule(at: statement) else { return }

            if rule.canRewrite { rewritingSyntaxRules.insert(rule) }
            lintingSyntaxRules.insert(rule)

            for visitedNode in rule.visitedNodes {
                syntaxNodeLinters[visitedNode, default: []].append(rule.typeName)
            }
        }
    }

    /// Populates `layoutRules` by scanning for `LayoutRule` conformances.
    ///
    /// - Parameter url: The file system URL of the settings directory.
    package func collectLayoutRules(from url: URL) throws {
        try enumerateSwiftStatements(in: url) { statement in
            guard let rule = self.detectLayoutRule(at: statement) else { return }
            layoutRules.append(rule)
        }
        layoutRules.sort { $0.typeName < $1.typeName }
    }

    /// Detect a layout rule type (struct conforming to LayoutRule).
    private func detectLayoutRule(at statement: CodeBlockItemSyntax) -> DetectedLayoutRule? {
        guard let structDecl = statement.item.as(StructDeclSyntax.self),
            let inheritanceClause = structDecl.inheritanceClause
        else { return nil }

        for inheritance in inheritanceClause.inheritedTypes {
            guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self),
                identifier.name.text == "LayoutRule"
            else { continue }

            let members = structDecl.memberBlock.members

            return DetectedLayoutRule(
                group: Self.extractGroup(from: members),
                typeName: structDecl.name.text,
                customKey: Self.extractStringLiteral(named: "key", from: members),
                description: Self.extractStringLiteral(named: "description", from: members),
                valueType: Self.detectValueType(named: "defaultValue", from: members)
            )
        }
        return nil
    }

    // MARK: - Rule detection

    /// Determine the rule kind for the declaration in the given statement, if any.
    private func detectSyntaxRule(at statement: CodeBlockItemSyntax) -> DetectedSyntaxRule? {
        let members: MemberBlockItemListSyntax
        let typeName: String
        let description = DocumentationCommentText(extractedFrom: statement.item.leadingTrivia)
        let maybeInheritanceClause: InheritanceClauseSyntax?

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

        guard let inheritanceClause = maybeInheritanceClause else { return nil }

        for inheritance in inheritanceClause.inheritedTypes {
            guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self) else {
                continue
            }

            let canRewrite: Bool
            switch identifier.name.text {
            case "LintSyntaxRule":
                canRewrite = false
            case "RewriteSyntaxRule":
                canRewrite = true
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

            return DetectedSyntaxRule(
                group: Self.extractGroup(from: members),
                typeName: typeName,
                customKey: Self.extractStringLiteral(named: "key", from: members),
                description: description?.text,
                canRewrite: canRewrite,
                visitedNodes: visitedNodes,
                isOptIn: Self.extractIsOptIn(from: members),
            )
        }

        return nil
    }

    /// Extracts a string literal for a named member.
    ///
    /// Handles both patterns:
    /// - `static let key = "value"` (stored property)
    /// - `override class var key: String { "value" }` (computed property)
    private static func extractStringLiteral(
        named identifier: String,
        from members: MemberBlockItemListSyntax
    ) -> String? {
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == identifier
            else { continue }

            // Stored property: `static let key = "value"`
            if let initializer = binding.initializer?.value.as(StringLiteralExprSyntax.self),
                let segment = initializer.segments.firstAndOnly?.as(StringSegmentSyntax.self)
            {
                return segment.content.text
            }

            // Computed property: `class var key: String { "value" }`
            if let accessorBlock = binding.accessorBlock,
                case .getter(let body) = accessorBlock.accessors
            {
                // Single-expression getter
                if let stringLiteral = body.first?.item.as(StringLiteralExprSyntax.self),
                    let segment = stringLiteral.segments.firstAndOnly?.as(StringSegmentSyntax.self)
                {
                    return segment.content.text
                }
                // Return statement
                if let returnStmt = body.first?.item.as(ReturnStmtSyntax.self),
                    let stringLiteral = returnStmt.expression?.as(StringLiteralExprSyntax.self),
                    let segment = stringLiteral.segments.firstAndOnly?.as(StringSegmentSyntax.self)
                {
                    return segment.content.text
                }
            }
        }
        return nil
    }

    /// Infers the JSON Schema type for a layout rule's `defaultValue` from its AST.
    ///
    /// - `true`/`false` → `.boolean`
    /// - Integer literal → `.integer`
    /// - Everything else (string literals, enum member access) → `.string`
    private static func detectValueType(
        named identifier: String,
        from members: MemberBlockItemListSyntax
    ) -> DetectedLayoutRule.SchemaValueType {
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == identifier,
                let initializer = binding.initializer
            else { continue }

            if initializer.value.is(BooleanLiteralExprSyntax.self) {
                return .boolean
            }
            if initializer.value.is(IntegerLiteralExprSyntax.self) {
                return .integer
            }
            return .string
        }
        return .string
    }

    /// Checks whether a rule is opt-in by detecting disabled defaults in its `defaultValue`.
    ///
    /// Handles three patterns:
    /// - `LintValue(rewrite: false, lint: .no)` (opt-in rewrite rules)
    /// - `LintOnlyValue(lint: .no)` (opt-in lint-only rules)
    /// - Computed getter with `v.rewrite = false` (custom config rules)
    private static func extractIsOptIn(from members: MemberBlockItemListSyntax) -> Bool {
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == "defaultValue"
            else { continue }

            // Check initializer: `LintValue(rewrite: false, ...)` or `LintOnlyValue(lint: .no)`
            if let call = binding.initializer?.value.as(FunctionCallExprSyntax.self) {
                return Self.isDisabledDefault(call)
            }

            // Check computed getter
            if let accessorBlock = binding.accessorBlock,
                case .getter(let body) = accessorBlock.accessors
            {
                if let call = body.first?.item.as(FunctionCallExprSyntax.self) {
                    return Self.isDisabledDefault(call)
                }
                if let returnStmt = body.first?.item.as(ReturnStmtSyntax.self),
                    let call = returnStmt.expression?.as(FunctionCallExprSyntax.self)
                {
                    return Self.isDisabledDefault(call)
                }
                // Multi-statement: look for `v.rewrite = false` anywhere in body
                for item in body {
                    if Self.isRewriteFalseAssignment(item) { return true }
                }
            }
        }
        return false
    }

    /// Checks if a function call represents a disabled default value.
    ///
    /// Matches `LintValue(rewrite: false, ...)` and `LintOnlyValue(lint: .no)`.
    private static func isDisabledDefault(_ call: FunctionCallExprSyntax) -> Bool {
        // `LintValue(rewrite: false, ...)`
        for arg in call.arguments {
            if arg.label?.text == "rewrite",
                let boolLiteral = arg.expression.as(BooleanLiteralExprSyntax.self),
                boolLiteral.literal.text == "false"
            {
                return true
            }
        }
        // `LintOnlyValue(lint: .no)`
        if let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
            callee.baseName.text == "LintOnlyValue"
        {
            for arg in call.arguments {
                if arg.label?.text == "lint",
                    let memberAccess = arg.expression.as(MemberAccessExprSyntax.self),
                    memberAccess.declName.baseName.text == "no"
                {
                    return true
                }
            }
        }
        return false
    }

    /// Checks if a code block item is `v.rewrite = false`.
    private static func isRewriteFalseAssignment(_ item: CodeBlockItemSyntax) -> Bool {
        guard let seq = item.item.as(SequenceExprSyntax.self) else { return false }
        let elements = Array(seq.elements)
        guard elements.count == 3 else { return false }

        // LHS: `v.rewrite`
        guard let memberAccess = elements[0].as(MemberAccessExprSyntax.self),
            memberAccess.declName.baseName.text == "rewrite"
        else { return false }

        // Operator: `=`
        guard elements[1].is(AssignmentExprSyntax.self) else { return false }

        // RHS: `false`
        guard let boolLiteral = elements[2].as(BooleanLiteralExprSyntax.self),
            boolLiteral.literal.text == "false"
        else { return false }

        return true
    }

    /// Extracts `group` from `static let group: ConfigurationGroup? = .someCase` in the AST.
    private static func extractGroup(from members: MemberBlockItemListSyntax) -> ConfigurationGroup?
    {
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
