import SwiftSyntax

/// A SwiftSyntax `SyntaxVisitor` that produces absolute positions where violations should be reported.
class ViolationCollectingVisitor<Configuration: RuleConfiguration>: SyntaxVisitor {
    /// A rule's configuration.
    let configuration: Configuration
    /// The file from which the traversed syntax tree stems from.
    let file: SwiftSource

    /// A source location converter associated with the syntax tree being traversed.
    lazy var locationConverter = file.locationConverter

    /// Initializer for a ``ViolationCollectingVisitor``.
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: File from which the syntax tree stems from.
    @inlinable
    init(configuration: Configuration, file: SwiftSource) {
        self.configuration = configuration
        self.file = file
        super.init(viewMode: .sourceAccurate)
    }

    /// Positions in a source file where violations should be reported.
    var violations: [SyntaxViolation] = []

    /// List of declaration types that shall be skipped while traversing the AST.
    var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
        []
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        shouldSkip(node)
    }

    private func shouldSkip(_ node: some DeclSyntaxProtocol) -> SyntaxVisitorContinueKind {
        skippableDeclarations
            .contains { $0 == node.syntaxNodeType } ? .skipChildren : .visitChildren
    }
}

extension [any DeclSyntaxProtocol.Type] {
    /// All visitable declaration syntax types.
    static let all: Self = [
        ActorDeclSyntax.self,
        ClassDeclSyntax.self,
        EnumDeclSyntax.self,
        ExtensionDeclSyntax.self,
        FunctionDeclSyntax.self,
        InitializerDeclSyntax.self,
        ProtocolDeclSyntax.self,
        StructDeclSyntax.self,
        SubscriptDeclSyntax.self,
        VariableDeclSyntax.self,
    ]

    /// All declarations except for the specified ones.
    ///
    /// - parameter declarations: The declarations to exclude from all declarations.
    ///
    /// - returns: All declarations except for the specified ones.
    static func allExcept(_ declarations: Element...) -> Self {
        all.filter { decl in !declarations.contains { $0 == decl } }
    }
}
