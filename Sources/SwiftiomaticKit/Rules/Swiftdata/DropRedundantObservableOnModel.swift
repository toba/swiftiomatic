import SwiftSyntax

/// Remove `@Observable` from a class that also carries `@Model` .
///
/// The `@Model` macro adds the `Observable` conformance and the observation storage. A second
/// `@Observable` asks for the same work again. The two macros then declare the same members, and
/// the compiler reports a redeclaration.
///
/// Lint: A class carries both `@Model` and `@Observable` .
final class DropRedundantObservableOnModel: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftdata }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let model = node.attributes.attribute(named: "Model", module: "SwiftData"),
            let observable = node.attributes.attribute(named: "Observable", module: "Observation")
        else { return .visitChildren }
        let note = Finding.Note(
            message: .modelAddsObservable,
            location: Finding.Location(model.startLocation(
                converter: context.sourceLocationConverter)),
            role: .related
        )
        diagnose(.redundantObservable(node.name.text), on: observable, notes: [note])
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func redundantObservable(_ name: String) -> Finding.Message {
        "remove '@Observable' from '\(name)'; '@Model' already makes the class observable"
    }

    static let modelAddsObservable: Finding.Message =
        "the '@Model' attribute that adds 'Observable'"
}
