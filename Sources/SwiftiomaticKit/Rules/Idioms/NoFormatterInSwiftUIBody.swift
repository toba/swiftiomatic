import SwiftSyntax

/// Lint formatter initializers ( `NumberFormatter` , `DateFormatter` , `MeasurementFormatter` )
/// constructed inside a SwiftUI `body` accessor.
///
/// SwiftUI re-evaluates `body` whenever its dependencies invalidate. Building a formatter inline
/// allocates and configures a new instance on every render and discards it. Hoist to a `static let`
/// or a parent-scoped property.
final class NoFormatterInSwiftUIBody: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    private static let formatterTypes: Set<String> = [
        "NumberFormatter",
        "DateFormatter",
        "MeasurementFormatter",
        "ByteCountFormatter",
        "DateComponentsFormatter",
        "DateIntervalFormatter",
        "ListFormatter",
        "PersonNameComponentsFormatter",
    ]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isSwiftUIBody(node),
              node.bindings.count == 1,
              let binding = node.bindings.first,
              let accessor = binding.accessorBlock else { return .visitChildren }
        let collector = FormatterInitCollector(
            types: Self.formatterTypes, viewMode: .sourceAccurate)

        switch accessor.accessors {
            case let .accessors(block): collector.walk(block)
            case let .getter(stmts): collector.walk(stmts)
        }
        for hit in collector.matches { diagnose(.formatterInBody(hit.type), on: hit.call) }
        return .visitChildren
    }

    private func isSwiftUIBody(_ node: VariableDeclSyntax) -> Bool {
        guard node.bindings.count == 1,
              let binding = node.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              pattern.identifier.text == "body",
              let typeAnnotation = binding.typeAnnotation,
              let some = typeAnnotation.type.as(SomeOrAnyTypeSyntax.self),
              let ident = some.constraint.as(IdentifierTypeSyntax.self) else { return false }
        return ident.name.text == "View" || ident.name.text == "Scene"
    }
}

private final class FormatterInitCollector: SyntaxVisitor {
    let types: Set<String>
    var matches: [(call: FunctionCallExprSyntax, type: String)] = []

    init(types: Set<String>, viewMode: SyntaxTreeViewMode) {
        self.types = types
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
           types.contains(ident.baseName.text)
        {
            matches.append((node, ident.baseName.text))
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func formatterInBody(_ type: String) -> Finding.Message {
        "'\(type)' is built inside SwiftUI 'body' — re-allocated on every render. Hoist to a static let."
    }
}
