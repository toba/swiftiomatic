import SwiftSyntax

/// Protocol enabling the lint pipeline to read violations from type-erased visitors
protocol ViolationCollectingVisitorProtocol: AnyObject {
    var violations: [SyntaxViolation] { get }
    var skippableDeclarations: [any DeclSyntaxProtocol.Type] { get }
}

/// Base `SyntaxVisitor` that accumulates ``SyntaxViolation`` positions during AST traversal
///
/// Subclasses override `visitPost` methods to append to ``violations``.
/// The visitor also supports a ``skippableDeclarations`` list so rules can
/// opt out of visiting certain declaration kinds.
class ViolationCollectingVisitor<Configuration: RuleOptions>: SyntaxVisitor {
    /// The rule configuration driving this visitor's thresholds and options
    let configuration: Configuration

    /// The source file whose syntax tree is being traversed
    let file: SwiftSource

    /// A location converter for the current file
    let locationConverter: SourceLocationConverter

    /// Creates a visitor for the given rule configuration and source file
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: The source file whose syntax tree will be traversed.
    init(configuration: Configuration, file: SwiftSource) {
        self.configuration = configuration
        self.file = file
        self.locationConverter = file.locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    /// Accumulated violation positions collected during traversal
    var violations: [SyntaxViolation] = []

    /// Declaration types that this visitor skips entirely
    ///
    /// Override in subclasses to restrict traversal. Defaults to an empty array
    /// (visit everything).
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

extension ViolationCollectingVisitor: ViolationCollectingVisitorProtocol {}

extension [any DeclSyntaxProtocol.Type] {
    /// All visitable declaration syntax types
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

    /// All declaration types except for the specified ones
    ///
    /// - Parameters:
    ///   - declarations: The declaration types to exclude.
    /// - Returns: All declaration types minus the excluded ones.
    static func allExcept(_ declarations: Element...) -> Self {
        all.filter { decl in !declarations.contains { $0 == decl } }
    }
}
