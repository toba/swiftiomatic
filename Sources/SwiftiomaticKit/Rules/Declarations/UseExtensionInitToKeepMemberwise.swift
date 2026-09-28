import SwiftSyntax

/// Declare a custom `struct` initializer in an extension so the synthesized memberwise initializer
/// stays available.
///
/// An initializer in the main body of a `struct` suppresses the memberwise initializer. The same
/// initializer in an extension keeps it, and the extension initializer can call the memberwise
/// initializer to finish the work. The rule flags each initializer in the main body of a `struct`
/// that can move to an extension. This includes an initializer that converts another value, parses
/// input, derives a property, or delegates to a second initializer.
///
/// ```swift
/// struct Track {
///     var title: String
///     var seconds: Int
/// }
///
/// extension Track {
///     init(record: Record) {
///         self.init(title: record.name, seconds: record.duration)
///     }
/// }
/// ```
///
/// Keep the initializer in the main body when every instance must pass through it, for example when
/// it validates or normalizes its input. The memberwise initializer would let a caller skip that
/// step. The rule does not detect normalization, so it reports an initializer that trims, clamps or
/// converts its input. Suppress the finding there.
///
/// The rule stays silent in these cases:
///
/// - The labels match the memberwise labels in order. An extension cannot declare that initializer,
///   because it redeclares the synthesized one. `UseSynthesizedInit` owns that case.
/// - The initializer checks its input with a top-level `guard`, or with `precondition`, `assert`,
///   `fatalError` or a similar call. Every instance must pass through such an initializer. A
///   top-level `guard` whose `else` block calls `self.init` only selects a path, so it is not a
///   check.
/// - The initializer is failable or throws.
/// - The initializer takes no parameters and every stored property has a default value. An
///   extension cannot declare that initializer, because it redeclares the synthesized `init()`.
/// - The type is `public`, `package` or `open`, a stored property is less visible than the type,
///   and the labels are the memberwise labels in a different order. The initializer is the public
///   spelling of the memberwise initializer.
///
/// Lint: An initializer in the main body of a `struct` that can move to an extension raises a
/// warning.
final class UseExtensionInitToKeepMemberwise: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let properties = MemberwiseInitializer(of: node).properties
        guard !properties.isEmpty else { return .visitChildren }

        let typeLevel = DeclaredAccessLevel(node.modifiers) ?? .internal
        let hasHiddenProperty = typeLevel > .internal
            && properties.contains(where: {
                (DeclaredAccessLevel($0.modifiers) ?? .internal) < typeLevel
            })
        let memberwiseLabels = properties.flatMap(\.memberwiseNames)
        let everyPropertyHasDefault = properties.allSatisfy(\.hasDefaultValue)

        for member in node.memberBlock.members {
            guard let initializer = member.decl.as(InitializerDeclSyntax.self),
                initializer.optionalMark == nil,
                initializer.signature.effectSpecifiers?.throwsClause == nil,
                let body = initializer.body,
                !body.statements.isEmpty else { continue }

            let labels = initializer.signature.parameterClause.parameters.map(\.firstName.text)
            guard labels != memberwiseLabels else { continue }
            if labels.isEmpty, everyPropertyHasDefault { continue }
            if hasHiddenProperty, labels.sorted() == memberwiseLabels.sorted() { continue }
            guard !CheckFinder.containsCheck(body) else { continue }

            diagnose(.moveInitToExtension, on: initializer.initKeyword)
        }
        return .visitChildren
    }
}

/// Finds a statement or call that checks the input of an initializer.
///
/// The finder does not enter nested closures or functions, because a check there does not guard the
/// initializer itself.
private final class CheckFinder: SyntaxVisitor {
    private static let checkCalls: Set<String> = [
        "precondition", "preconditionFailure", "assert", "assertionFailure", "fatalError",
        "dispatchPrecondition",
    ]

    private var found = false

    static func containsCheck(_ body: CodeBlockSyntax) -> Bool {
        let finder = CheckFinder(viewMode: .sourceAccurate)
        finder.walk(body)
        return finder.found
    }

    /// A `guard` checks the input only at the top level of the body. A `guard` in a loop usually
    /// skips one element, and it does not reject the input. A `guard` whose `else` block delegates
    /// to `self.init` picks a path and does not reject the input either.
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.parent?.parent?.parent?.is(CodeBlockSyntax.self) == true,
           node.parent?.parent?.parent?.parent?.is(InitializerDeclSyntax.self) == true,
           !Self.delegatesToSelfInit(node.body)
        {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }

    /// Whether `block` has a statement that calls `self.init`
    private static func delegatesToSelfInit(_ block: CodeBlockSyntax) -> Bool {
        block.statements.contains { item in
            guard let call = item.item.as(FunctionCallExprSyntax.self),
                let access = call.calledExpression.as(MemberAccessExprSyntax.self)
            else {
                return false
            }
            return access.declName.baseName.tokenKind == .keyword(.`init`)
                && access.base?.as(DeclReferenceExprSyntax.self)?.baseName
                    .tokenKind
                    == .keyword(.self)
        }
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let name = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
           Self.checkCalls.contains(name)
        {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

fileprivate extension VariableDeclSyntax {
    /// The names this declaration contributes to the memberwise initializer, in order.
    ///
    /// A `let` with an initial value contributes none, because it can never change.
    var memberwiseNames: [String] {
        bindings.compactMap { binding in
            if bindingSpecifier.tokenKind == .keyword(.let), binding.initializer != nil {
                return nil
            }
            return binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }
    }
}

fileprivate extension Finding.Message {
    static let moveInitToExtension: Finding.Message =
        "move this initializer to an extension to keep the synthesized memberwise initializer"
}
