import SwiftSyntax

/// Flag a `private` or `fileprivate` function or property that nothing in the file references.
///
/// Private scope ends at the file. Thus a search of one file finds every possible reference, and a
/// private member with no reference is dead code.
///
/// A reference is any name expression or member access with the member's base name, a key path
/// component, or a `#selector` argument. `$name` and `_name` count as references to `name` . The
/// match is by name only, so a reference to a different declaration with the same name also counts.
/// Thus the rule can miss dead code, but it does not report live code.
///
/// The rule skips these members:
///
/// - A member with `@objc` , `@IBAction` , `@IBOutlet` , `@_dynamicReplacement` or another
///   attribute that lets code outside the file reach it. A function with any attribute that is not
///   a known inert attribute, such as a test macro, is also skipped.
/// - A member with the `override` or `dynamic` modifier, and a member of an `@objcMembers` type.
/// - `init` , `deinit` , subscripts, operators, and `callAsFunction` , because a call does not
///   spell their names.
/// - A `fileprivate` member of a type that declares a conformance in the file. A `fileprivate`
///   member can be a protocol witness, and the rule cannot see protocol requirements. A `private`
///   member cannot be a witness, because Swift requires a witness to be at least `fileprivate` .
///   Thus the rule still checks a `private` member of a conforming type.
/// - A stored instance property of a type that conforms to a protocol outside a known set, such as
///   `View` or `Sendable` . A synthesized conformance such as `Codable` or `Hashable` reads the
///   stored properties without a reference in the source.
///
/// Lint: A `private` or `fileprivate` function or property has no reference in the file.
final class NoUnusedPrivateMember: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var guidance: GuidanceLevel { .should }

    /// Attributes that let code outside the file, or the runtime, reach a member
    private static let exposingAttributes: Set<String> = [
        "objc", "IBAction", "IBOutlet", "IBInspectable", "IBSegueAction", "GKInspectable",
        "NSManaged", "_dynamicReplacement", "_cdecl", "c", "_silgen_name", "export",
    ]

    /// Function attributes that do not change how code reaches the function
    private static let inertFunctionAttributes: Set<String> = [
        "MainActor", "discardableResult", "inlinable", "inline", "usableFromInline", "available",
        "concurrent", "Sendable", "nonobjc", "preconcurrency", "ViewBuilder",
        "ToolbarContentBuilder",
        "CommandsBuilder", "SceneBuilder", "resultBuilder", "specialize", "_specialize",
        "warn_unqualified_access", "backDeployed", "_disfavoredOverload", "TaskLocal",
    ]

    /// Protocols that synthesize no member reads from stored properties
    private static let nonSynthesizingProtocols: Set<String> = [
        "View", "SwiftUI.View", "ViewModifier", "SwiftUI.ViewModifier", "App", "Scene", "Sendable",
        "Error", "Identifiable", "CustomStringConvertible", "CustomDebugStringConvertible",
        "Observable", "ObservableObject",
    ]

    /// Names that code reaches without spelling them
    private static let implicitNames: Set<String> = [
        "callAsFunction", "wrappedValue", "projectedValue",
    ]

    /// The base names that the file references, built on first use
    private var referencedNames: Set<String>?

    /// Facts about each type in the file, keyed by simple name, built on first use
    private var typeFacts: [String: TypeFacts]?

    private struct TypeFacts {
        /// Whether a declaration or extension of the type has an inheritance clause
        var conforms = false
        /// Whether an inherited type is outside `nonSynthesizingProtocols`
        var mayRequireStoredProperties = false
        /// Whether the type carries `@objcMembers` or `@resultBuilder`
        var exposesMembers = false
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let access = Self.privateAccess(node.modifiers) else { return .visitChildren }
        let name = node.name

        guard case .identifier = name.tokenKind,
              !Self.implicitNames.contains(name.text),
              !node.modifiers.contains(where: Self.isExposingModifier),
              node.attributes.allSatisfy({
                  Self.attributeName($0).map(Self.inertFunctionAttributes.contains) ?? true
              }),
              !isExempt(node, access: access, isStoredProperty: false),
              !references.contains(name.text) else { return .visitChildren }
        diagnose(.unusedPrivateMember(name.text), on: name)
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let access = Self.privateAccess(node.modifiers),
              !node.modifiers.contains(where: Self.isExposingModifier),
              !node.attributes.contains(where: {
                  Self.attributeName($0).map(Self.exposingAttributes.contains) ?? false
              }) else { return .visitChildren }
        let isStatic = node.modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }

        for binding in node.bindings {
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
            else { continue }
            let isStored = !isStatic && Self.isStored(binding)

            guard !Self.implicitNames.contains(identifier.text),
                  !isExempt(node, access: access, isStoredProperty: isStored),
                  !references.contains(identifier.text) else { continue }
            diagnose(.unusedPrivateMember(identifier.text), on: identifier)
        }
        return .visitChildren
    }

    /// Whether the type that holds `node` makes it exempt
    private func isExempt(
        _ node: some SyntaxProtocol,
        access: Keyword,
        isStoredProperty: Bool
    ) -> Bool {
        guard let owner = Self.owningDecl(of: node) else { return false }
        guard let typeName = TypeMemberIndex.typeName(of: owner) else {
            // A member of a protocol or of an extension of a qualified generic type
            return true
        }
        let facts = facts[typeName] ?? TypeFacts()
        if facts.exposesMembers { return true }
        if access == .fileprivate, facts.conforms { return true }
        return isStoredProperty && facts.mayRequireStoredProperties
    }

    /// The base names of every reference in the file
    private var references: Set<String> {
        if let referencedNames { return referencedNames }
        let collector = ReferenceCollector(viewMode: .sourceAccurate)
        collector.walk(context.sourceFileSyntax)
        referencedNames = collector.names
        return collector.names
    }

    private var facts: [String: TypeFacts] {
        if let typeFacts { return typeFacts }
        let collector = TypeFactCollector(viewMode: .sourceAccurate)
        collector.walk(context.sourceFileSyntax)
        typeFacts = collector.facts
        return collector.facts
    }

    /// `private` or `fileprivate` when the modifiers give that access to the whole member
    private static func privateAccess(_ modifiers: DeclModifierListSyntax) -> Keyword? {
        for modifier in modifiers where modifier.detail == nil {
            if modifier.name.tokenKind == .keyword(.private) { return .private }
            if modifier.name.tokenKind == .keyword(.fileprivate) { return .fileprivate }
        }
        return nil
    }

    private static func isExposingModifier(_ modifier: DeclModifierSyntax) -> Bool {
        modifier.name.tokenKind == .keyword(.override)
            || modifier.name.tokenKind == .keyword(.dynamic)
    }

    private static func attributeName(_ element: AttributeListSyntax.Element) -> String? {
        guard case let .attribute(attribute) = element else { return nil }
        return attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
            ?? attribute.attributeName.trimmedDescription
    }

    /// Whether the binding stores a value, rather than computes one
    private static func isStored(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessors = binding.accessorBlock?.accessors else { return true }

        switch accessors {
            case .getter: return false
            case let .accessors(list):
                return !list.contains {
                    $0.accessorSpecifier.tokenKind == .keyword(.get)
                        || $0.accessorSpecifier.tokenKind == .keyword(.set)
                }
        }
    }

    /// The type, extension or protocol declaration whose member block directly holds `node`
    private static func owningDecl(of node: some SyntaxProtocol) -> Syntax? {
        guard let block = node.parent?.parent?.parent, block.is(MemberBlockSyntax.self)
        else { return nil }
        return block.parent
    }

    private final class ReferenceCollector: SyntaxVisitor {
        var names = Set<String>()

        override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
            let text = node.baseName.text
            names.insert(text)
            if text.hasPrefix("$") || text.hasPrefix("_") { names.insert(String(text.dropFirst())) }
            return .visitChildren
        }
    }

    private final class TypeFactCollector: SyntaxVisitor {
        var facts: [String: TypeFacts] = [:]

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), node.attributes, node.inheritanceClause)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), node.attributes, node.inheritanceClause)
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), node.attributes, node.inheritanceClause)
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), node.attributes, node.inheritanceClause)
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), node.attributes, node.inheritanceClause)
        }

        private func record(
            _ decl: Syntax,
            _ attributes: AttributeListSyntax,
            _ inheritance: InheritanceClauseSyntax?
        ) -> SyntaxVisitorContinueKind {
            guard let name = TypeMemberIndex.typeName(of: decl) else { return .visitChildren }
            var entry = facts[name] ?? TypeFacts()

            if attributes.attribute(named: "objcMembers") != nil
                || attributes.attribute(named: "resultBuilder") != nil {
                entry.exposesMembers = true
            }

            if let inheritance, !inheritance.inheritedTypes.isEmpty {
                entry.conforms = true

                if inheritance.inheritedTypes.contains(where: {
                    !NoUnusedPrivateMember.nonSynthesizingProtocols
                        .contains($0.type.trimmedDescription)
                }) { entry.mayRequireStoredProperties = true }
            }
            facts[name] = entry
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static func unusedPrivateMember(_ name: String) -> Finding.Message {
        "nothing in the file references private '\(name)'. Remove it"
    }
}
