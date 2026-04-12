package import SwiftSyntax

/// Protocol enabling the lint pipeline to read violations from type-erased visitors
package protocol ViolationCollectingVisitorProtocol: AnyObject {
  var violations: [SyntaxViolation] { get }
  var skippableDeclarations: [any DeclSyntaxProtocol.Type] { get }

  /// When `true`, the visitor automatically skips children of all nested-scope
  /// node types: ``CodeBlockSyntax`` (function / control-flow bodies),
  /// ``AccessorBlockSyntax`` (computed property / subscript getters and setters),
  /// and ``ClosureExprSyntax``.
  ///
  /// This is a **structural guarantee** — setting a single flag skips all three
  /// types together, eliminating the class of bug where a rule skips one scope
  /// kind but forgets another (e.g. skipping `CodeBlockSyntax` but not
  /// `AccessorBlockSyntax`).
  ///
  /// The lint pipeline reads this flag at registration time and manages
  /// `skipDepths` accounting automatically, mirroring how
  /// ``skippableDeclarations`` works for declaration types.
  var skipsNestedScopes: Bool { get }
}

/// Base `SyntaxVisitor` that accumulates ``SyntaxViolation`` positions during AST traversal
///
/// Subclasses override `visitPost` methods to append to ``violations``.
/// The visitor also supports a ``skippableDeclarations`` list so rules can
/// opt out of visiting certain declaration kinds.
open class ViolationCollectingVisitor<Configuration: RuleOptions>: SyntaxVisitor {
  /// The rule configuration driving this visitor's thresholds and options
  public let configuration: Configuration

  /// The source file whose syntax tree is being traversed
  package let file: SwiftSource

  /// A location converter for the current file
  package let locationConverter: SourceLocationConverter

  /// Creates a visitor for the given rule configuration and source file
  ///
  /// - Parameters:
  ///   - configuration: Configuration of a rule.
  ///   - file: The source file whose syntax tree will be traversed.
  public init(configuration: Configuration, file: SwiftSource) {
    self.configuration = configuration
    self.file = file
    self.locationConverter = file.locationConverter
    super.init(viewMode: .sourceAccurate)
  }

  /// Accumulated violation positions collected during traversal
  public var violations: [SyntaxViolation] = []

  /// Declaration types that this visitor skips entirely
  ///
  /// Override in subclasses to restrict traversal. Defaults to an empty array
  /// (visit everything).
  open var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
    []
  }

  /// Skip children of all nested-scope blocks: ``CodeBlockSyntax``,
  /// ``AccessorBlockSyntax``, and ``ClosureExprSyntax``.
  ///
  /// Override and return `true` in visitors that only care about declarations
  /// at the current scope level (e.g. top-level-only or member-level rules).
  /// The three scope types always travel together — this prevents the common
  /// bug of skipping `CodeBlockSyntax` but forgetting `AccessorBlockSyntax`.
  ///
  /// For the **direct-walk** path (fallback rules), the default `visit(_:)`
  /// overrides below handle skipping. For **pipeline** rules, the generated
  /// ``LintPipeline`` reads this flag at init and manages `skipDepths`
  /// automatically.
  open var skipsNestedScopes: Bool { false }

  open override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  open override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldSkip(node)
  }

  // MARK: - Nested-scope skipping (direct-walk path)

  /// Skips function and control-flow bodies when ``skipsNestedScopes`` is set.
  /// Subclasses may override for custom logic; the override takes precedence.
  open override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
    skipsNestedScopes ? .skipChildren : .visitChildren
  }

  /// Skips computed-property and subscript accessor bodies when
  /// ``skipsNestedScopes`` is set. This is the scope type most commonly
  /// forgotten when rules manually skip only ``CodeBlockSyntax``.
  open override func visit(_: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
    skipsNestedScopes ? .skipChildren : .visitChildren
  }

  /// Skips closure expression bodies when ``skipsNestedScopes`` is set.
  open override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    skipsNestedScopes ? .skipChildren : .visitChildren
  }

  private func shouldSkip(_ node: some DeclSyntaxProtocol) -> SyntaxVisitorContinueKind {
    skippableDeclarations
      .contains { $0 == node.syntaxNodeType } ? .skipChildren : .visitChildren
  }
}

extension ViolationCollectingVisitor: ViolationCollectingVisitorProtocol {}

package extension [any DeclSyntaxProtocol.Type] {
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
