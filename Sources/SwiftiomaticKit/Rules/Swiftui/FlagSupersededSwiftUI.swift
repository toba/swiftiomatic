import SwiftSyntax

/// Flag superseded SwiftUI / Combine-era APIs that have modern `@Observable` / navigation
/// replacements:
///
/// - `@StateObject` → `@State` with an `@Observable` type
/// - `@ObservedObject` → pass `@Observable` values directly (or `@Bindable` for two-way bindings)
/// - `@EnvironmentObject` → `@Environment(MyType.self)` with an `@Observable` type
/// - `@Published` → unnecessary on `@Observable` types
/// - `ObservableObject` conformance → `@Observable` macro
/// - `NavigationView` → `NavigationStack` / `NavigationSplitView`
///
/// Flag-only — fixes are contextual (the consumer must move the type to `@Observable`, choose
/// `NavigationStack` vs `NavigationSplitView`, etc.).
final class FlagSupersededSwiftUI: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.attributeName.as(IdentifierTypeSyntax.self) else {
            return .visitChildren
        }
        switch ident.name.text {
            case "StateObject": diagnose(.stateObject, on: node)
            case "ObservedObject": diagnose(.observedObject, on: node)
            case "EnvironmentObject": diagnose(.environmentObject, on: node)
            case "Published": diagnose(.published, on: node)
            default: break
        }
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        flagObservableObject(on: node, inheritance: node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        flagObservableObject(on: node, inheritance: node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        flagObservableObject(on: node, inheritance: node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        flagObservableObject(on: node, inheritance: node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
           ident.baseName.text == "NavigationView"
        {
            diagnose(.navigationView, on: node.calledExpression)
        }
        return .visitChildren
    }

    private func flagObservableObject(
        on node: some SyntaxProtocol,
        inheritance: InheritanceClauseSyntax?
    ) {
        guard let inheritance,
              let inherited = inheritance.inherited(named: "ObservableObject") else { return }
        diagnose(.observableObject, on: inherited)
    }
}

fileprivate extension Finding.Message {
    static let stateObject: Finding.Message =
        "'@StateObject' is superseded — use '@State' with an '@Observable' type"
    static let observedObject: Finding.Message =
        "'@ObservedObject' is superseded — pass '@Observable' values directly (or '@Bindable' for two-way bindings)"
    static let environmentObject: Finding.Message =
        "'@EnvironmentObject' is superseded — use '@Environment(MyType.self)' with an '@Observable' type"
    static let published: Finding.Message =
        "'@Published' is unnecessary on '@Observable' types — remove it"
    static let observableObject: Finding.Message =
        "'ObservableObject' conformance is superseded — use the '@Observable' macro"
    static let navigationView: Finding.Message =
        "'NavigationView' is deprecated — use 'NavigationStack' or 'NavigationSplitView'"
}
