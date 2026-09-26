import SwiftSyntax

/// Require `final` on a class that carries `@Model` .
///
/// SwiftData derives the schema from the stored properties of a `@Model` class. A subclass is a
/// part of the schema only when it also carries `@Model` , and a deep query on the base class then
/// returns the subclass too. A class that is not `final` lets a later change add a subclass by
/// accident. `final` also lets the compiler call members directly.
///
/// A model class that the same file subclasses is the base of a model hierarchy, so the rule does
/// not report it. The rule does not report an `open` class. The rule cannot see a subclass in
/// another file. Suppress the finding for a base class that another file subclasses.
///
/// Lint: A class with `@Model` has no `final` modifier.
final class RequireFinalModelClass: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftdata }
    override class var guidance: GuidanceLevel { .should }

    /// The names that some class in the file inherits from.
    private var superclassNames: Set<String> = []

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let collector = InheritedNameCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        superclassNames = collector.names
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.attributes.attribute(named: "Model", module: "SwiftData") != nil,
              !node.modifiers.contains(where: {
                  $0.name.tokenKind == .keyword(.final) || $0.name.tokenKind == .keyword(.open)
              }),
              !superclassNames.contains(node.name.text) else { return .visitChildren }
        diagnose(.modelNotFinal(node.name.text), on: node.name)
        return .visitChildren
    }
}

/// Collects the first inherited type name of every class in a file.
private final class InheritedNameCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if let first = node.inheritanceClause?.inheritedTypes.first?.type {
            if let ident = first.as(IdentifierTypeSyntax.self) {
                names.insert(ident.name.text)
            } else if let member = first.as(MemberTypeSyntax.self) {
                names.insert(member.name.text)
            }
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func modelNotFinal(_ name: String) -> Finding.Message {
        "'@Model' class '\(name)' is not 'final'; mark it 'final' unless a model subclasses it"
    }
}
