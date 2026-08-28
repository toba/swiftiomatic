import Foundation
import SwiftSyntax

/// Infers JSON Schema nodes from the declared Swift types of a rule's configuration properties.
///
/// The rule detector in `RuleCollector` finds *which* properties exist. This type decides what each
/// one looks like in `schema.json` .
enum SchemaNodeInference {
    /// A case from a `String` -backed enum: its Swift identifier and its serialized raw value. When
    /// the case has no explicit raw value, the identifier and raw value are equal.
    typealias EnumCase = (name: String, rawValue: String)

    /// Determines the JSON Schema node for a property binding.
    ///
    /// `description` is the extracted DocC text for the property, when present. The property name
    /// stands in when it is `nil` or empty.
    static func schemaNode(
        for binding: PatternBindingSyntax,
        propertyName: String,
        description: String?,
        enumTypes: [String: [EnumCase]],
        objectTypes: [String: JSONSchemaNode]
    ) -> JSONSchemaNode? {
        let initValue = binding.initializer?.value
        let defaultCase = defaultCaseName(from: initValue)
        let scalarDesc = (description?.isEmpty == false ? description : nil) ?? propertyName

        // Try type annotation first (with initializer for the real default).
        if let typeAnnotation = binding.typeAnnotation {
            return schemaNode(
                forType: typeAnnotation.type,
                propertyName: propertyName,
                description: description,
                enumTypes: enumTypes,
                objectTypes: objectTypes,
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
        if let stringLiteral = initValue?.as(StringLiteralExprSyntax.self),
           let segment = stringLiteral.segments.firstAndOnly?.as(StringSegmentSyntax.self)
        {
            return .string(description: scalarDesc, defaultValue: segment.content.text)
        }

        if let defaultCase,
           let entry = enumTypes.first(where: { $1.contains(where: { $0.name == defaultCase }) }),
           let matched = entry.value.first(where: { $0.name == defaultCase })
        {
            return .stringEnum(
                description: description,
                values: entry.value.map(\.rawValue),
                defaultValue: matched.rawValue
            )
        }

        return nil
    }

    /// Determines the schema from a type annotation.
    private static func schemaNode(
        forType type: TypeSyntax,
        propertyName: String,
        description: String?,
        enumTypes: [String: [EnumCase]],
        objectTypes: [String: JSONSchemaNode],
        defaultCase: String?,
        initValue: ExprSyntax?
    ) -> JSONSchemaNode? {
        let scalarDesc = (description?.isEmpty == false ? description : nil) ?? propertyName

        // Optional type: `String?` or `[String]?`
        if let optional = type.as(OptionalTypeSyntax.self) {
            return schemaNode(
                forType: optional.wrappedType,
                propertyName: propertyName,
                description: description,
                enumTypes: enumTypes,
                objectTypes: objectTypes,
                defaultCase: defaultCase,
                initValue: initValue
            )
        }

        // Array type: `[String]` or an array of a struct declared in the same file
        if let array = type.as(ArrayTypeSyntax.self),
           let elementIdent = array.element.as(IdentifierTypeSyntax.self)
        {
            if elementIdent.name.text == "String" { return .stringArray(description: scalarDesc) }

            if let itemNode = objectTypes[elementIdent.name.text] {
                return .array(description: scalarDesc, items: itemNode)
            }
        }

        guard let ident = type.as(IdentifierTypeSyntax.self) else { return nil }

        switch ident.name.text {
            case "String": return .string(description: scalarDesc)
            case "Int":
                let parsed = initValue?.as(IntegerLiteralExprSyntax.self)
                    .flatMap { Int($0.literal.text) }
                return .integer(description: scalarDesc, defaultValue: parsed ?? 0)
            case "Bool":
                let literal = initValue?.as(BooleanLiteralExprSyntax.self)
                return .boolean(
                    description: scalarDesc,
                    defaultValue: literal?.literal.text == "true"
                )
            case "Lint":
                // Mirrors ConfigurationSchemaGenerator.lintModeValues — `Lint` lives in
                // ConfigurationKit so it isn't found via local enum scan.
                return .stringEnum(
                    description: description,
                    values: ["warn", "error", "no"],
                    defaultValue: defaultCase ?? "warn"
                )
            default:
                // Enum type — use initializer's case as default, fall back to first case.
                guard let cases = enumTypes[ident.name.text] else { return nil }
                let defaultRaw =
                    defaultCase
                    .flatMap { name in cases.first(where: { $0.name == name })?.rawValue }
                    ?? cases[0].rawValue
                return .stringEnum(
                    description: description,
                    values: cases.map(\.rawValue),
                    defaultValue: defaultRaw
                )
        }
    }

    /// Builds the item schema for a struct used as the element of an array-typed config property.
    ///
    /// A field is required when it declares no default value. Returns `nil` when the struct holds a
    /// field the schema generator cannot type, so an unsupported shape stays out of the schema
    /// rather than landing there half described.
    static func objectSchema(for structDecl: StructDeclSyntax) -> JSONSchemaNode? {
        var properties: [String: JSONSchemaNode] = [:]
        var required: [String] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            guard !varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
            else { continue }
            guard let binding = varDecl.bindings.firstAndOnly,
                  binding.accessorBlock == nil,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }

            let fieldName = pattern.identifier.text

            // Nested object types are not resolved, so an element type never recurses.
            guard let node = schemaNode(
                for: binding,
                propertyName: fieldName,
                description: DocumentationCommentText.normalized(from: varDecl.leadingTrivia),
                enumTypes: [:],
                objectTypes: [:]
            ) else { return nil }

            properties[fieldName] = node
            if binding.initializer == nil { required.append(fieldName) }
        }

        guard !properties.isEmpty else { return nil }

        var node = JSONSchemaNode.object(description: nil, properties: properties)
        if !required.isEmpty { node.required = required.sorted() }
        return node
    }

    /// Extracts all cases from a `String` -backed enum, capturing each case's Swift identifier
    /// alongside its serialized raw value (which may differ, e.g. `case getSet = "get_set"` ).
    static func enumCases(from enumDecl: EnumDeclSyntax) -> [EnumCase] {
        // Only process enums that inherit from String (raw value enums).
        guard let inheritance = enumDecl.inheritanceClause,
              inheritance.inheritedTypes.contains(where: {
                  $0.type.as(IdentifierTypeSyntax.self)?.name.text == "String"
              }) else { return [] }

        var cases: [EnumCase] = []

        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }

            for element in caseDecl.elements {
                // Strip backticks from keyword-escaped names like `private` → "private".
                let name = element.name.text.trimmingCharacters(in: CharacterSet(charactersIn: "`"))
                let rawValue = element.rawValue?.value.as(StringLiteralExprSyntax.self)?
                    .segments.firstAndOnly?.as(StringSegmentSyntax.self)?
                    .content.text
                cases.append((name: name, rawValue: rawValue ?? name))
            }
        }
        return cases
    }

    /// Extracts the case name from a `.someCase` initializer expression.
    private static func defaultCaseName(from expr: ExprSyntax?) -> String? {
        expr?.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }
}
