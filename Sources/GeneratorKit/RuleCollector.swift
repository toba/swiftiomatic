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

    /// Populates every collection by scanning the given directory once.
    ///
    /// A statement declares at most one kind of rule, so both detectors run against the same parse.
    /// Scanning per kind would parse the tree once per kind, and layout rules and syntax rules
    /// share one directory.
    ///
    /// - Parameter url: The file system URL that should be scanned for rules.
    package func collect(from url: URL) async throws {
        try await enumerateSwiftFiles(in: url) { statements in
            for statement in statements {
                if let rule = self.detectSyntaxRule(at: statement, fileStatements: statements) {
                    if rule.canRewrite { self.rewritingSyntaxRules.insert(rule) }
                    self.lintingSyntaxRules.insert(rule)

                    for visitedNode in rule.visitedNodes {
                        self.syntaxNodeLinters[visitedNode, default: []].append(rule.typeName)
                    }
                    continue
                }
                if let rule = self.detectLayoutRule(at: statement, fileStatements: statements) {
                    self.layoutRules.append(rule)
                }
            }
        }
        layoutRules.sort { $0.typeName < $1.typeName }
    }

    /// Detect a layout rule type (struct conforming to LayoutRule).
    private func detectLayoutRule(
        at statement: CodeBlockItemSyntax,
        fileStatements: CodeBlockItemListSyntax
    ) -> DetectedLayoutRule? {
        guard let structDecl = statement.item.as(StructDeclSyntax.self),
            let inheritanceClause = structDecl.inheritanceClause else { return nil }

        for inheritance in inheritanceClause.inheritedTypes {
            guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self),
                identifier.name.text == "LayoutRule" else { continue }

            let members = structDecl.memberBlock.members

            return DetectedLayoutRule(
                group: Self.extractGroup(from: members),
                typeName: structDecl.name.text,
                customKey: Self.extractStringLiteral(named: "key", from: members),
                documentation: Self.extractStringLiteral(named: "description", from: members),
                valueType: Self.detectValueType(
                    named: "defaultValue",
                    from: members,
                    fileStatements: fileStatements
                )
            )
        }
        return nil
    }

    // MARK: - Rule detection

    /// Determine the rule kind for the declaration in the given statement, if any.
    private func detectSyntaxRule(
        at statement: CodeBlockItemSyntax,
        fileStatements: CodeBlockItemListSyntax
    ) -> DetectedSyntaxRule? {
        let members: MemberBlockItemListSyntax
        let typeName: String
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
            guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self) else { continue }

            let canRewrite: Bool

            switch identifier.name.text {
                case "LintSyntaxRule": canRewrite = false
                case "StructuralFormatRule", "StaticFormatRule": canRewrite = true
                default: continue
            }

            // Extract the generic parameter (config type name).
            let configTypeName = identifier.genericArgumentClause?
                .arguments.first?
                .argument.as(IdentifierTypeSyntax.self)?
                .name.text

            var visitedNodes = [String]()

            for member in members {
                guard let function = member.decl.as(FunctionDeclSyntax.self),
                    function.name.text == "visit" else { continue }

                let params = function.signature.parameterClause.parameters
                if let firstType = params.firstAndOnly?.type.as(IdentifierTypeSyntax.self) {
                    visitedNodes.append(firstType.name.text)
                }
            }

            // Detect threshold-style config (conforms to ThresholdRuleValue) so schema generation
            // can pick the right base shape.
            let isThreshold = configTypeName.map {
                Self.structConforms($0, to: "ThresholdRuleValue", in: fileStatements)
            } ?? false

            // Extract custom properties from the configuration type.
            let customProperties = configTypeName.map {
                Self.extractCustomProperties(
                    configTypeName: $0,
                    from: fileStatements,
                    isThreshold: isThreshold
                )
            } ?? []

            return DetectedSyntaxRule(
                group: Self.extractGroup(from: members),
                typeName: typeName,
                customKey: Self.extractStringLiteral(named: "key", from: members),
                documentation: DocumentationCommentText.normalized(
                    from: statement.item.leadingTrivia),
                canRewrite: canRewrite,
                isThreshold: isThreshold,
                visitedNodes: visitedNodes,
                isOptIn: Self.extractIsOptIn(from: members),
                customProperties: customProperties,
            )
        }

        return nil
    }

    // MARK: - Member lookup

    /// The single binding of a stored or computed member named `identifier` , or `nil` when the
    /// member is absent or declares more than one binding.
    private static func binding(
        named identifier: String,
        in members: MemberBlockItemListSyntax
    ) -> PatternBindingSyntax? {
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                pattern.identifier.text == identifier else { continue }
            return binding
        }
        return nil
    }

    /// The expression a binding evaluates to, across the three shapes a rule declaration uses: an
    /// initializer, a single-expression getter, and a getter whose body is one `return` .
    ///
    /// A multi-statement getter yields `nil` , because no single expression describes it.
    private static func valueExpression(of binding: PatternBindingSyntax) -> ExprSyntax? {
        if let initializer = binding.initializer?.value { return initializer }

        guard let accessorBlock = binding.accessorBlock,
              case let .getter(body) = accessorBlock.accessors,
              let first = body.first?.item else { return nil }

        if let expr = first.as(ExprSyntax.self) { return expr }
        return first.as(ReturnStmtSyntax.self)?.expression
    }

    /// The statements in a member's getter body, or `nil` when it has none.
    private static func getterBody(
        of binding: PatternBindingSyntax
    ) -> CodeBlockItemListSyntax? {
        guard let accessorBlock = binding.accessorBlock,
              case let .getter(body) = accessorBlock.accessors else { return nil }
        return body
    }

    // MARK: - Custom property extraction

    /// Base property keys that are already handled by `ruleBase` / `lintOnlyBase` .
    private static let basePropertyKeys: Set<String> = ["rewrite", "lint"]

    /// Base property keys covered by `thresholdLintBase` .
    private static let thresholdBasePropertyKeys: Set<String> = ["enabled", "warning", "error"]

    /// Returns true when `configTypeName` (declared in `statements` ) lists `protocolName` in its
    /// inheritance clause.
    static func structConforms(
        _ configTypeName: String,
        to protocolName: String,
        in statements: CodeBlockItemListSyntax
    ) -> Bool {
        guard let configStruct = findStruct(named: configTypeName, in: statements),
              let inheritance = configStruct.inheritanceClause else { return false }

        for inherited in inheritance.inheritedTypes {
            if let ident = inherited.type.as(IdentifierTypeSyntax.self),
                ident.name.text == protocolName { return true }
        }
        return false
    }

    /// Extracts custom properties from a configuration struct in the file.
    private static func extractCustomProperties(
        configTypeName: String,
        from statements: CodeBlockItemListSyntax,
        isThreshold: Bool
    ) -> [DetectedProperty] {
        // Find the config struct declaration.
        guard let configStruct = findStruct(named: configTypeName, in: statements) else {
            return []
        }

        let members = configStruct.memberBlock.members

        // Collect nested enum types: type name → cases (Swift identifier + raw value).
        var enumTypes: [String: [SchemaNodeInference.EnumCase]] = [:]

        for member in members {
            guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else { continue }
            let cases = SchemaNodeInference.enumCases(from: enumDecl)
            if !cases.isEmpty { enumTypes[enumDecl.name.text] = cases }
        }

        // Collect sibling struct types usable as an array element, such as the AcquireReleasePair
        // behind PairAcquireWithDefer's pairs property.
        var objectTypes: [String: JSONSchemaNode] = [:]

        for statement in statements {
            guard let structDecl = statement.item.as(StructDeclSyntax.self),
                structDecl.name.text != configTypeName,
                let node = SchemaNodeInference.objectSchema(for: structDecl) else { continue }
            objectTypes[structDecl.name.text] = node
        }

        // Scan stored properties for custom (non-base) ones.
        var properties: [DetectedProperty] = []

        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }

            let propertyName = pattern.identifier.text
            guard !basePropertyKeys.contains(propertyName) else { continue }
            if isThreshold, thresholdBasePropertyKeys.contains(propertyName) { continue }

            // Determine the type from the annotation or initializer.
            guard let schemaNode = SchemaNodeInference.schemaNode(
                for: binding,
                propertyName: propertyName,
                description: DocumentationCommentText.normalized(from: varDecl.leadingTrivia),
                enumTypes: enumTypes,
                objectTypes: objectTypes
            ) else { continue }

            properties.append(DetectedProperty(key: propertyName, schemaNode: schemaNode))
        }

        return properties
    }

    /// Finds a struct declaration by name in the file's top-level statements.
    private static func findStruct(
        named name: String,
        in statements: CodeBlockItemListSyntax
    ) -> StructDeclSyntax? {
        for statement in statements {
            if let structDecl = statement.item.as(StructDeclSyntax.self),
                structDecl.name.text == name { return structDecl }
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
        guard let binding = binding(named: identifier, in: members),
              let literal = valueExpression(of: binding)?.as(StringLiteralExprSyntax.self),
              let segment = literal.segments.firstAndOnly?.as(StringSegmentSyntax.self)
        else { return nil }
        return segment.content.text
    }

    /// Infers the JSON Schema type for a layout rule's `defaultValue` from its AST.
    ///
    /// - `true` / `false` → `.boolean`
    /// - Integer literal → `.integer`
    /// - `.enumCase` with matching enum in file → `.stringEnum`
    /// - Everything else (string literals) → `.string`
    private static func detectValueType(
        named identifier: String,
        from members: MemberBlockItemListSyntax,
        fileStatements: CodeBlockItemListSyntax
    ) -> DetectedLayoutRule.SchemaValueType {
        guard let binding = binding(named: identifier, in: members),
              let value = binding.initializer?.value else { return .string }

        if value.is(BooleanLiteralExprSyntax.self) { return .boolean }
        if value.is(IntegerLiteralExprSyntax.self) { return .integer }

        // Array literal → currently treated as `[String]`. Other element types are not supported by
        // the schema generator yet.
        if value.is(ArrayExprSyntax.self) { return .stringArray }
        // `[]` typed as `[String]` (or similar) appears as `Array<String>()` or just `[]` with type
        // annotation. Detect via type annotation.
        if let typeAnnotation = binding.typeAnnotation,
           let array = typeAnnotation.type.as(ArrayTypeSyntax.self),
           array.element.as(IdentifierTypeSyntax.self)?.name.text == "String" {
            return .stringArray
        }

        // Check for `.enumCase` → find the enum type in the file via type annotation.
        if let memberAccess = value.as(MemberAccessExprSyntax.self),
           let typeAnnotation = binding.typeAnnotation,
           let typeName = typeAnnotation.type.as(IdentifierTypeSyntax.self)?.name.text,
           let cases = findEnumCases(named: typeName, in: fileStatements)
        {
            let defaultName = memberAccess.declName.baseName.text
            let defaultRaw = cases.first(where: { $0.name == defaultName })?.rawValue ?? defaultName
            return .stringEnum(values: cases.map(\.rawValue), defaultValue: defaultRaw)
        }

        return .string
    }

    /// Finds a file-level enum by name and extracts its cases.
    private static func findEnumCases(
        named name: String,
        in statements: CodeBlockItemListSyntax
    ) -> [SchemaNodeInference.EnumCase]? {
        for statement in statements {
            guard let enumDecl = statement.item.as(EnumDeclSyntax.self),
                enumDecl.name.text == name else { continue }
            let cases = SchemaNodeInference.enumCases(from: enumDecl)
            return cases.isEmpty ? nil : cases
        }
        return nil
    }

    /// Checks whether a rule is opt-in by detecting disabled defaults in its `defaultValue` .
    ///
    /// Handles three patterns:
    /// - `BasicRuleValue(rewrite: false, lint: .no)` (opt-in rewrite rules)
    /// - `LintOnlyValue(lint: .no)` (opt-in lint-only rules)
    /// - Computed getter with `v.rewrite = false` (custom config rules)
    private static func extractIsOptIn(from members: MemberBlockItemListSyntax) -> Bool {
        guard let binding = binding(named: "defaultValue", in: members) else { return false }

        if let call = valueExpression(of: binding)?.as(FunctionCallExprSyntax.self) {
            return isDisabledDefault(call)
        }

        // Multi-statement getter: look for `v.rewrite = false` anywhere in the body.
        guard let body = getterBody(of: binding) else { return false }
        return body.contains(where: isRewriteFalseAssignment)
    }

    /// Checks if a function call represents a disabled default value.
    ///
    /// Matches `BasicRuleValue(rewrite: false, ...)` and `LintOnlyValue(lint: .no)` .
    private static func isDisabledDefault(_ call: FunctionCallExprSyntax) -> Bool {
        // `BasicRuleValue(rewrite: false, ...)`
        for arg in call.arguments {
            if arg.label?.text == "rewrite",
               let boolLiteral = arg.expression.as(BooleanLiteralExprSyntax.self),
               boolLiteral.literal.text == "false" { return true }
        }
        // `LintOnlyValue(lint: .no)`
        if let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
            callee.baseName.text == "LintOnlyValue"
        {
            for arg in call.arguments {
                if arg.label?.text == "lint",
                   let memberAccess = arg.expression.as(MemberAccessExprSyntax.self),
                   memberAccess.declName.baseName.text == "no" { return true }
            }
        }
        return false
    }

    /// Checks if a code block item is `v.rewrite = false` .
    private static func isRewriteFalseAssignment(_ item: CodeBlockItemSyntax) -> Bool {
        guard let seq = item.item.as(SequenceExprSyntax.self) else { return false }
        let elements = Array(seq.elements)
        guard elements.count == 3 else { return false }

        // LHS: `v.rewrite`
        guard let memberAccess = elements[0].as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "rewrite" else { return false }

        // Operator: `=`
        guard elements[1].is(AssignmentExprSyntax.self) else { return false }

        // RHS: `false`
        guard let boolLiteral = elements[2].as(BooleanLiteralExprSyntax.self),
              boolLiteral.literal.text == "false" else { return false }

        return true
    }

    /// Extracts `group` from `static let group: ConfigurationGroup? = .someCase` in the AST.
    private static func extractGroup(
        from members: MemberBlockItemListSyntax
    ) -> ConfigurationGroup? {
        guard let binding = binding(named: "group", in: members),
              let memberAccess = valueExpression(of: binding)?.as(MemberAccessExprSyntax.self)
        else { return nil }
        return ConfigurationGroup(rawValue: memberAccess.declName.baseName.text)
    }
}
