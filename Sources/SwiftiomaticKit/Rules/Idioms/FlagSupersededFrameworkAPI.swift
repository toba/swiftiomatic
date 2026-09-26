import SwiftSyntax

/// Flag framework types the OS 27 SDK replaced wholesale.
///
/// - `MXMetricManager` and its payload types → `MetricManager` . The MetricKit headers carry
///   `API_DEPRECATED("Use MetricManager instead.")` on the manager, the subscriber protocol and
///   each payload type.
/// - `NSBundleResourceRequest` → Background Assets. The Foundation interface marks it
///   `deprecated: 27` on iOS, tvOS, watchOS and visionOS. It was never available on macOS.
///
/// The rule matches the type name wherever it appears: a conformance, an annotation, a generic
/// argument or a static member reference such as `MXMetricManager.shared` .
///
/// The rule also flags two older patterns that have a Swift replacement:
///
/// - Storage of `NSAttributedString` or `NSMutableAttributedString` → `AttributedString` . The rule
///   reports a stored property of a type, an initializer parameter of a type and an enum case
///   parameter. The Swift value type is `Sendable` , it is `Codable` and SwiftData stores it. The
///   rule does not report a local, a computed property or a function parameter. A TextKit bridge
///   can need the reference type. In that case, keep the code and ignore the finding.
/// - A hand-written `animatableData` on a type that conforms to `Animatable` , `Shape` ,
///   `InsettableShape` or `AnimatableModifier` → the `@Animatable` macro. The macro makes the
///   stored properties animatable and writes `animatableData` . Mark a property that must not
///   animate with `@AnimatableIgnored` . A custom `animatableData` that does more than pack the
///   stored properties can need to stay.
///
/// Lint: A reference to a replaced type, a stored `NSAttributedString` or a hand-written
/// `animatableData` raises a warning.
final class FlagSupersededFrameworkAPI: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        flag(node.name)
        flagAttributedStringStorage(node, name: node.name)
        return .visitChildren
    }

    override func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
        flagAttributedStringStorage(node, name: node.name)
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.bindings.contains(where: {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "animatableData"
        }),
            let owner = owningType(of: node),
            owner.attributes?.attribute(named: "Animatable") == nil,
            let conformance = owner.inheritance?.inheritedTypes.first(where: {
                Self.animatableProtocols.contains(simpleName(of: $0.type))
            }) else { return .visitChildren }

        diagnose(
            .useAnimatableMacro,
            on: node,
            notes: [note(.animatableConformance, at: conformance.type, role: .owner)]
        )
        return .visitChildren
    }

    private static let animatableProtocols: Set<String> = [
        "Animatable", "Shape", "InsettableShape", "AnimatableModifier",
    ]

    private static let attributedStringTypes: Set<String> = [
        "NSAttributedString", "NSMutableAttributedString",
    ]

    /// Reports `type` when it names an attributed string class and it is the type of stored data.
    private func flagAttributedStringStorage(_ type: some TypeSyntaxProtocol, name: TokenSyntax) {
        guard Self.attributedStringTypes.contains(name.text),
            let member = storageMember(containing: Syntax(type)),
            let owner = owningType(of: member) else { return }
        diagnose(
            .useAttributedString,
            on: name,
            notes: [note(.attributedStringOwner, at: owner.name, role: .owner)]
        )
    }

    /// Returns the member declaration that stores a value of the type at `node` .
    ///
    /// The member is a stored property, an initializer or an enum case. The function returns `nil`
    /// for any other position, such as a local, a computed property or a generic argument in an
    /// expression.
    private func storageMember(containing node: Syntax) -> DeclSyntax? {
        var current = node

        while let parent = current.parent {
            if let annotation = parent.as(TypeAnnotationSyntax.self) {
                guard let binding = annotation.parent?.as(PatternBindingSyntax.self),
                      isStored(binding),
                      let variable = binding.parent?.parent?.as(VariableDeclSyntax.self)
                else { return nil }
                return DeclSyntax(variable)
            }
            if parent.is(FunctionParameterSyntax.self) || parent.is(EnumCaseParameterSyntax.self) {
                let decl = enclosingDecl(of: parent)
                return decl?.is(InitializerDeclSyntax.self) == true
                    || decl?.is(EnumCaseDeclSyntax.self) == true ? decl : nil
            }
            if parent.is(DeclSyntax.self) || parent.is(ExprSyntax.self)
                || parent.is(StmtSyntax.self)
                || parent.is(CodeBlockSyntax.self) { return nil }
            current = parent
        }
        return nil
    }

    /// The nearest declaration above `node` .
    private func enclosingDecl(of node: Syntax) -> DeclSyntax? {
        var current = node.parent

        while let node = current {
            if let decl = node.as(DeclSyntax.self) { return decl }
            current = node.parent
        }
        return nil
    }

    /// Whether the binding stores its value, with no accessor or with only observers.
    private func isStored(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else { return true }
        guard case let .accessors(accessors) = accessorBlock.accessors else { return false }
        return accessors.allSatisfy {
            $0.accessorSpecifier.tokenKind == .keyword(.willSet)
                || $0.accessorSpecifier.tokenKind == .keyword(.didSet)
        }
    }

    /// The type declaration that holds `member` directly in its member block.
    private func owningType(of member: some SyntaxProtocol) -> OwningType? {
        guard member.parent?.is(MemberBlockItemSyntax.self) == true,
              let decl = member.parent?.parent?.parent?.parent else { return nil }

        if !decl.is(ProtocolDeclSyntax.self),
           let type = decl.asProtocol(NamedDeclSyntax.self),
           let group = decl.asProtocol(DeclGroupSyntax.self)
        {
            return OwningType(
                name: Syntax(type.name), attributes: group.attributes,
                inheritance: group.inheritanceClause)
        }
        if let ext = decl.as(ExtensionDeclSyntax.self) {
            return OwningType(
                name: Syntax(ext.extendedType), attributes: ext.attributes,
                inheritance: ext.inheritanceClause)
        }
        return nil
    }

    private func simpleName(of type: TypeSyntax) -> String {
        type.as(IdentifierTypeSyntax.self)?.name.text
            ?? type.as(MemberTypeSyntax.self)?.name.text
            ?? type.trimmedDescription
    }

    private func note(
        _ message: Finding.Message,
        at node: some SyntaxProtocol,
        role: EvidenceRole
    ) -> Finding.Note {
        Finding.Note(
            message: message,
            location: Finding.Location(node.startLocation(
                converter: context.sourceLocationConverter)),
            role: role
        )
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        flag(node.baseName)
        return .visitChildren
    }

    private func flag(_ token: TokenSyntax) {
        switch token.text {
            case "MXMetricManager", "MXMetricManagerSubscriber":
                diagnose(.useMetricManager, on: token)
            case "MXMetricPayload", "MXDiagnosticPayload": diagnose(.useMetricReports, on: token)
            case "NSBundleResourceRequest": diagnose(.useBackgroundAssets, on: token)
            default: break
        }
    }
}

/// The type declaration or extension that holds a flagged member.
private struct OwningType {
    let name: Syntax
    let attributes: AttributeListSyntax?
    let inheritance: InheritanceClauseSyntax?
}

fileprivate extension Finding.Message {
    static let useMetricManager: Finding.Message =
        "'MXMetricManager' is deprecated — use 'MetricManager'"
    static let useMetricReports: Finding.Message =
        "the 'MX' payload types are deprecated — read 'MetricManager.metricReports' instead"
    static let useBackgroundAssets: Finding.Message =
        "'NSBundleResourceRequest' is deprecated on OS 27 — stage assets with Background Assets instead"
    static let useAttributedString: Finding.Message =
        "store 'AttributedString', not the reference type 'NSAttributedString'"
    static let attributedStringOwner: Finding.Message = "the type that stores the value"
    static let useAnimatableMacro: Finding.Message =
        "replace the hand-written 'animatableData' with the '@Animatable' macro"
    static let animatableConformance: Finding.Message = "the explicit 'Animatable' conformance"
}
