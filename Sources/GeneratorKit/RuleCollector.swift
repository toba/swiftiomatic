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
        try enumerateSwiftFiles(in: url) { statements in
            for statement in statements {
                guard
                    let rule = self.detectSyntaxRule(
                        at: statement,
                        fileStatements: statements
                    )
                else { continue }

                if rule.canRewrite { self.rewritingSyntaxRules.insert(rule) }
                self.lintingSyntaxRules.insert(rule)

                for visitedNode in rule.visitedNodes {
                    self.syntaxNodeLinters[visitedNode, default: []].append(rule.typeName)
                }
            }
        }
    }

    /// Populates `layoutRules` by scanning for `LayoutRule` conformances.
    ///
    /// - Parameter url: The file system URL of the settings directory.
    package func collectLayoutRules(from url: URL) throws {
        try enumerateSwiftFiles(in: url) { statements in
            for statement in statements {
                guard
                    let rule = self.detectLayoutRule(
                        at: statement,
                        fileStatements: statements
                    )
                else { continue }
                self.layoutRules.append(rule)
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

            // Extract the generic parameter (config type name).
            let configTypeName = identifier.genericArgumentClause?
                .arguments.first?
                .argument.as(IdentifierTypeSyntax.self)?
                .name.text

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

            // Extract custom properties from the configuration type.
            let customProperties: [DetectedProperty]
            if let configTypeName {
                customProperties = Self.extractCustomProperties(
                    configTypeName: configTypeName,
                    from: fileStatements
                )
            } else {
                customProperties = []
            }

            return DetectedSyntaxRule(
                group: Self.extractGroup(from: members),
                typeName: typeName,
                customKey: Self.extractStringLiteral(named: "key", from: members),
                description: description.map { Self.normalizeDescription($0.text) },
                canRewrite: canRewrite,
                visitedNodes: visitedNodes,
                isOptIn: Self.extractIsOptIn(from: members),
                customProperties: customProperties,
            )
        }

        return nil
    }

    // MARK: - Custom property extraction

    /// Base property keys that are already handled by `ruleBase`/`lintOnlyBase`.
    private static let basePropertyKeys: Set<String> = ["rewrite", "lint"]

    /// Extracts custom properties from a configuration struct in the file.
    private static func extractCustomProperties(
        configTypeName: String,
        from statements: CodeBlockItemListSyntax
    ) -> [DetectedProperty] {
        // Find the config struct declaration.
        guard let configStruct = findStruct(named: configTypeName, in: statements) else {
            return []
        }

        let members = configStruct.memberBlock.members

        // Collect nested enum types: name → [case raw values].
        var enumTypes: [String: [String]] = [:]
        for member in members {
            guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else { continue }
            let cases = extractEnumCases(from: enumDecl)
            if !cases.isEmpty {
                enumTypes[enumDecl.name.text] = cases
            }
        }

        // Scan stored properties for custom (non-base) ones.
        var properties: [DetectedProperty] = []
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.firstAndOnly,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
            else { continue }

            let propertyName = pattern.identifier.text
            guard !basePropertyKeys.contains(propertyName) else { continue }

            let docComment = DocumentationCommentText(
                extractedFrom: varDecl.leadingTrivia
            ).map { Self.normalizeDescription($0.text) }

            // Determine the type from the annotation or initializer.
            guard
                let schemaNode = schemaNode(
                    for: binding,
                    propertyName: propertyName,
                    description: docComment,
                    enumTypes: enumTypes
                )
            else { continue }

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
                structDecl.name.text == name
            {
                return structDecl
            }
        }
        return nil
    }

    /// Extracts all case names from a `String`-backed enum.
    private static func extractEnumCases(from enumDecl: EnumDeclSyntax) -> [String] {
        // Only process enums that inherit from String (raw value enums).
        guard let inheritance = enumDecl.inheritanceClause,
            inheritance.inheritedTypes.contains(where: {
                $0.type.as(IdentifierTypeSyntax.self)?.name.text == "String"
            })
        else { return [] }

        var cases: [String] = []
        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            for element in caseDecl.elements {
                // Strip backticks from keyword-escaped names like `private` → "private".
                let name = element.name.text.trimmingCharacters(in: CharacterSet(charactersIn: "`"))
                cases.append(name)
            }
        }
        return cases
    }

    /// Determines the JSON Schema node for a property binding.
    ///
    /// `description` is the extracted DocC text for the property, when present;
    /// callers fall back to the property name if it is `nil` or empty.
    private static func schemaNode(
        for binding: PatternBindingSyntax,
        propertyName: String,
        description: String?,
        enumTypes: [String: [String]]
    ) -> JSONSchemaNode? {
        let initValue = binding.initializer?.value
        let defaultCase = defaultCaseName(from: initValue)
        let scalarDesc = description?.isEmpty == false ? description! : propertyName

        // Try type annotation first (with initializer for the real default).
        if let typeAnnotation = binding.typeAnnotation {
            return schemaNodeFromType(
                typeAnnotation.type,
                propertyName: propertyName,
                description: description,
                enumTypes: enumTypes,
                defaultCase: defaultCase,
                initValue: initValue
            )
        }

        // No type annotation — infer from initializer alone.
        if let intLiteral = initValue?.as(IntegerLiteralExprSyntax.self),
            let value = Int(intLiteral.literal.text)
        {
            return .integer(description: scalarDesc, defaultValue: value)
        }
        if let boolLiteral = initValue?.as(BooleanLiteralExprSyntax.self) {
            return .boolean(
                description: scalarDesc,
                defaultValue: boolLiteral.literal.text == "true"
            )
        }
        if let defaultCase, let (cases, _) = enumTypes.first(where: { $1.contains(defaultCase) }) {
            return .stringEnum(
                description: description,
                values: enumTypes[cases]!,
                defaultValue: defaultCase
            )
        }

        return nil
    }

    /// Extracts the case name from a `.someCase` initializer expression.
    private static func defaultCaseName(from expr: ExprSyntax?) -> String? {
        expr?.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }

    /// Determines the schema from a type annotation.
    private static func schemaNodeFromType(
        _ type: TypeSyntax,
        propertyName: String,
        description: String?,
        enumTypes: [String: [String]],
        defaultCase: String?,
        initValue: ExprSyntax?
    ) -> JSONSchemaNode? {
        let scalarDesc = description?.isEmpty == false ? description! : propertyName

        // Optional type: `String?` or `[String]?`
        if let optional = type.as(OptionalTypeSyntax.self) {
            return schemaNodeFromType(
                optional.wrappedType,
                propertyName: propertyName,
                description: description,
                enumTypes: enumTypes,
                defaultCase: defaultCase,
                initValue: initValue
            )
        }

        // Array type: `[String]`
        if let array = type.as(ArrayTypeSyntax.self),
            let elementIdent = array.element.as(IdentifierTypeSyntax.self),
            elementIdent.name.text == "String"
        {
            return .stringArray(description: scalarDesc)
        }

        // Simple identifier type
        if let ident = type.as(IdentifierTypeSyntax.self) {
            let typeName = ident.name.text
            if typeName == "String" {
                return .string(description: scalarDesc)
            }
            if typeName == "Int" {
                let defaultValue: Int
                if let intLiteral = initValue?.as(IntegerLiteralExprSyntax.self),
                    let parsed = Int(intLiteral.literal.text)
                {
                    defaultValue = parsed
                } else {
                    defaultValue = 0
                }
                return .integer(description: scalarDesc, defaultValue: defaultValue)
            }
            if typeName == "Bool" {
                let defaultValue: Bool
                if let boolLiteral = initValue?.as(BooleanLiteralExprSyntax.self) {
                    defaultValue = boolLiteral.literal.text == "true"
                } else {
                    defaultValue = false
                }
                return .boolean(description: scalarDesc, defaultValue: defaultValue)
            }
            // Enum type — use initializer's case as default, fall back to first case.
            if let cases = enumTypes[typeName] {
                return .stringEnum(
                    description: description,
                    values: cases,
                    defaultValue: defaultCase ?? cases[0]
                )
            }
        }

        return nil
    }

    /// Normalizes a doc-comment string for use as a JSON Schema description.
    ///
    /// Joins consecutive non-blank lines into a single paragraph (separated by a space),
    /// preserves blank lines between paragraphs, and keeps bullet-list lines (`- `, `* `,
    /// `• `) on their own line so lists render correctly in tooltips.
    static func normalizeDescription(_ raw: String) -> String {
        var paragraphs: [String] = []
        var current: [String] = []

        func flush() {
            if !current.isEmpty {
                paragraphs.append(current.joined(separator: " "))
                current.removeAll()
            }
        }

        for rawLine in raw.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flush()
                if paragraphs.last != "" { paragraphs.append("") }
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
                flush()
                paragraphs.append(line)
            } else {
                current.append(line)
            }
        }
        flush()
        while paragraphs.last == "" { paragraphs.removeLast() }
        return paragraphs.joined(separator: "\n")
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
    /// - `.enumCase` with matching enum in file → `.stringEnum`
    /// - Everything else (string literals) → `.string`
    private static func detectValueType(
        named identifier: String,
        from members: MemberBlockItemListSyntax,
        fileStatements: CodeBlockItemListSyntax
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

            // Check for `.enumCase` → find the enum type in the file via type annotation.
            if let memberAccess = initializer.value.as(MemberAccessExprSyntax.self),
                let typeAnnotation = binding.typeAnnotation,
                let typeName = typeAnnotation.type.as(IdentifierTypeSyntax.self)?.name.text,
                let cases = findEnumCases(named: typeName, in: fileStatements)
            {
                let defaultCase = memberAccess.declName.baseName.text
                return .stringEnum(values: cases, defaultValue: defaultCase)
            }

            return .string
        }
        return .string
    }

    /// Finds a file-level enum by name and extracts its cases.
    private static func findEnumCases(
        named name: String,
        in statements: CodeBlockItemListSyntax
    ) -> [String]? {
        for statement in statements {
            guard let enumDecl = statement.item.as(EnumDeclSyntax.self),
                enumDecl.name.text == name
            else { continue }
            let cases = extractEnumCases(from: enumDecl)
            return cases.isEmpty ? nil : cases
        }
        return nil
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
