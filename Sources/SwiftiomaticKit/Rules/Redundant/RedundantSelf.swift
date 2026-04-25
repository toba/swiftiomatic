import SwiftSyntax

/// Remove explicit `self.` where the compiler allows implicit self.
///
/// In most contexts inside type bodies, `self.` is redundant when accessing members
/// because Swift resolves bare identifiers to instance members. This rule removes
/// the `self.` prefix when:
/// - The access is inside a type member (method, computed property, init, subscript)
/// - The member name is not shadowed by a local variable, parameter, or nested function
/// - The scope allows implicit self (not a closure in a reference type without capture)
///
/// For closures, implicit self is allowed per SE-0269 (Swift 5.3+) when:
/// - The enclosing type is a value type (struct/enum)
/// - The closure explicitly captures self: `[self]`, `[unowned self]`
///
/// The `[weak self]` + `guard let self` pattern (SE-0365, Swift 5.8+) is handled
/// conservatively: `self.` is kept in weak-self closures.
///
/// Lint: A lint warning is raised for redundant `self.` usage.
///
/// Format: The `self.` prefix is removed.
final class RedundantSelf: RewriteSyntaxRule<BasicRuleValue> {
  override class var group: ConfigurationGroup? { .redundancies }

  // MARK: - State

  /// Whether the immediately enclosing type is a reference type (class/actor).
  /// Stack to handle nested types.
  private var referenceTypeStack: [Bool] = []

  /// Stack of implicit-self-allowed flags. Each scope level (function, accessor,
  /// closure) pushes an entry. When checking whether self. can be removed, the
  /// current (top) entry is consulted.
  private var implicitSelfStack: [Bool] = []

  /// Stack of local name sets. Each scope level pushes a set containing the names
  /// declared in that scope (params, let/var bindings, for-in vars, etc.).
  /// When checking for shadowing, ALL levels are consulted via `allLocalNames`.
  private var localNameStack: [Set<String>] = []

  private var insideTypeBody: Bool { !referenceTypeStack.isEmpty }
  private var isReferenceType: Bool { referenceTypeStack.last ?? false }
  private var implicitSelfAllowed: Bool { implicitSelfStack.last ?? false }

  private var allLocalNames: Set<String> {
    localNameStack.reduce(into: Set()) { $0.formUnion($1) }
  }

  // MARK: - Type Declarations

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    referenceTypeStack.append(false)
    defer { referenceTypeStack.removeLast() }
    return super.visit(node)
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    referenceTypeStack.append(false)
    defer { referenceTypeStack.removeLast() }
    return super.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    referenceTypeStack.append(true)
    defer { referenceTypeStack.removeLast() }
    return super.visit(node)
  }

  override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    referenceTypeStack.append(true)
    defer { referenceTypeStack.removeLast() }
    return super.visit(node)
  }

  override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    // Can't determine if value or reference type from extension alone.
    // Assume reference type (conservative — closures require explicit self).
    referenceTypeStack.append(true)
    defer { referenceTypeStack.removeLast() }
    return super.visit(node)
  }

  // MARK: - Function and Initializer Scopes

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard insideTypeBody else { return super.visit(node) }

    var names = collectParamNames(from: node.signature.parameterClause)
    if let body = node.body {
      names.formUnion(collectLocalNames(in: Syntax(body)))
    }

    localNameStack.append(names)
    implicitSelfStack.append(true)
    defer {
      localNameStack.removeLast()
      implicitSelfStack.removeLast()
    }
    return super.visit(node)
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    guard insideTypeBody else { return super.visit(node) }

    var names = collectParamNames(from: node.signature.parameterClause)
    if let body = node.body {
      names.formUnion(collectLocalNames(in: Syntax(body)))
    }

    localNameStack.append(names)
    implicitSelfStack.append(true)
    defer {
      localNameStack.removeLast()
      implicitSelfStack.removeLast()
    }
    return super.visit(node)
  }

  override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    guard insideTypeBody else { return super.visit(node) }

    let names = collectParamNames(from: node.parameterClause)
    localNameStack.append(names)
    implicitSelfStack.append(true)
    defer {
      localNameStack.removeLast()
      implicitSelfStack.removeLast()
    }
    return super.visit(node)
  }

  // MARK: - Accessor Scopes (get/set/willSet/didSet)

  override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
    guard insideTypeBody || !implicitSelfStack.isEmpty else {
      return super.visit(node)
    }

    var names = Set<String>()
    let spec = node.accessorSpecifier.tokenKind

    // Implicit accessor parameter names
    if let params = node.parameters {
      names.insert(params.name.text)
    } else {
      switch spec {
      case .keyword(.set), .keyword(.willSet):
        names.insert("newValue")
      case .keyword(.didSet):
        names.insert("oldValue")
      default:
        break
      }
    }

    // In get/set, the property's own name is a "local" — using it
    // without self would cause infinite recursion.
    if spec == .keyword(.get) || spec == .keyword(.set) {
      if let propName = enclosingPropertyName(of: node) {
        names.insert(propName)
      }
    }

    if let body = node.body {
      names.formUnion(collectLocalNames(in: Syntax(body)))
    }

    localNameStack.append(names)
    implicitSelfStack.append(true)
    defer {
      localNameStack.removeLast()
      implicitSelfStack.removeLast()
    }
    return super.visit(node)
  }

  // MARK: - Variable Declarations (lazy var)

  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    guard insideTypeBody, node.modifiers.contains(anyOf: [.lazy]) else {
      return super.visit(node)
    }

    // Lazy stored properties have implicit closure semantics.
    // In reference types, self is required. In value types, it's optional.
    let allowed = !isReferenceType
    implicitSelfStack.append(allowed)
    localNameStack.append([])
    defer {
      implicitSelfStack.removeLast()
      localNameStack.removeLast()
    }
    return super.visit(node)
  }

  // MARK: - Shorthand Computed Properties

  override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
    // Shorthand computed var: `var foo: Int { return self.bar }`
    // has .getter(CodeBlockItemListSyntax) with no AccessorDeclSyntax.
    guard case .getter(let body) = node.accessors else {
      // Explicit accessors — handled by AccessorDeclSyntax visitor
      return super.visit(node)
    }
    guard insideTypeBody || !implicitSelfStack.isEmpty else {
      return super.visit(node)
    }

    var names = collectLocalNames(in: Syntax(body))
    // The property's own name is a "local" in its getter — using it without
    // self would cause infinite recursion.
    if let propName = enclosingPropertyName(of: node) {
      names.insert(propName)
    }
    localNameStack.append(names)
    implicitSelfStack.append(true)
    defer {
      localNameStack.removeLast()
      implicitSelfStack.removeLast()
    }
    return super.visit(node)
  }

  // MARK: - Closure Scopes

  override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    guard insideTypeBody else { return super.visit(node) }

    var names = Set<String>()
    var allowsImplicitSelf: Bool

    if !isReferenceType {
      // Value types (struct/enum): closures always allow implicit self (SE-0269)
      allowsImplicitSelf = true
    } else {
      // Reference types: check capture list
      allowsImplicitSelf = closureHasSelfCapture(node)
    }

    // Collect closure parameter names
    if let signature = node.signature {
      names.formUnion(collectClosureParamNames(from: signature))

      // Capture list entries (except self) are also locals
      if let captureClause = signature.capture {
        for capture in captureClause.items {
          let name = capture.name.text
          if name != "self" {
            names.insert(name)
          }
        }
      }
    }

    // Collect names declared in the closure body
    names.formUnion(collectLocalNames(in: Syntax(node.statements)))

    localNameStack.append(names)
    implicitSelfStack.append(allowsImplicitSelf)
    defer {
      localNameStack.removeLast()
      implicitSelfStack.removeLast()
    }
    return super.visit(node)
  }

  // MARK: - The Transform

  override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard let access = visited.as(MemberAccessExprSyntax.self) else { return visited }

    // Must be self.something
    guard let base = access.base?.as(DeclReferenceExprSyntax.self),
      base.baseName.tokenKind == .keyword(.self)
    else { return visited }

    // Never remove self.init (delegating initializer call)
    let memberName = access.declName.baseName.text
    guard memberName != "init" else { return visited }

    // Must be inside a type body with a function/accessor/closure scope
    guard !implicitSelfStack.isEmpty else { return visited }

    // Implicit self must be allowed at this scope level
    guard implicitSelfAllowed else { return visited }

    // Member name must not be shadowed by any local in scope
    guard !allLocalNames.contains(memberName) else { return visited }

    diagnose(.removeRedundantSelf, on: base)

    var replacement = ExprSyntax(access.declName)
    replacement.leadingTrivia = access.leadingTrivia
    replacement.trailingTrivia = access.trailingTrivia
    return replacement
  }

  // MARK: - Helpers

  /// Determines if a closure captures `self` explicitly (strong or unowned).
  /// `[weak self]` returns false (conservative — requires guard let self detection).
  private func closureHasSelfCapture(_ closure: ClosureExprSyntax) -> Bool {
    guard let signature = closure.signature,
      let captureClause = signature.capture
    else { return false }

    for capture in captureClause.items {
      guard capture.name.tokenKind == .keyword(.self) else { continue }

      if let specifier = capture.specifier {
        let specKind = specifier.specifier.tokenKind
        // [unowned self] and [unowned(safe) self] allow implicit self
        if specKind == .keyword(.unowned) { return true }
        // [weak self] does NOT allow implicit self without guard let self
        if specKind == .keyword(.weak) { return false }
      }
      // [self] — strong capture, allows implicit self
      return true
    }
    return false
  }

  /// Collects parameter internal names from a function parameter clause.
  private func collectParamNames(
    from clause: FunctionParameterClauseSyntax
  ) -> Set<String> {
    var names = Set<String>()
    for param in clause.parameters {
      let internalName = param.secondName ?? param.firstName
      guard internalName.tokenKind != .wildcard else { continue }
      names.insert(internalName.text)
    }
    return names
  }

  /// Collects parameter names from a closure signature.
  private func collectClosureParamNames(
    from signature: ClosureSignatureSyntax
  ) -> Set<String> {
    guard let paramClause = signature.parameterClause else { return [] }
    var names = Set<String>()

    switch paramClause {
    case .simpleInput(let params):
      for param in params {
        names.insert(param.name.text)
      }
    case .parameterClause(let clause):
      for param in clause.parameters {
        let internalName = param.secondName ?? param.firstName
        guard internalName.tokenKind != .wildcard else { continue }
        names.insert(internalName.text)
      }
    }
    return names
  }

  /// Walks up from a node to find the enclosing property name.
  /// Used to prevent removing `self.` inside a computed property's own getter/setter.
  private func enclosingPropertyName(of node: some SyntaxProtocol) -> String? {
    var current = node.parent
    while let parent = current {
      if let binding = parent.as(PatternBindingSyntax.self),
        let ident = binding.pattern.as(IdentifierPatternSyntax.self)
      {
        return ident.identifier.text
      }
      current = parent.parent
    }
    return nil
  }

  /// Collects all declared names in a syntax subtree without descending into
  /// nested closures, functions, or type declarations (those have their own scope).
  private func collectLocalNames(in syntax: Syntax) -> Set<String> {
    let collector = LocalNameCollector(viewMode: .sourceAccurate)
    collector.walk(syntax)
    return collector.names
  }
}

// MARK: - Local Name Collector

/// Visitor that collects all identifiers introduced by bindings, patterns,
/// and nested function declarations within a single scope level.
private final class LocalNameCollector: SyntaxVisitor {
  var names: Set<String> = []

  override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
    names.insert(node.identifier.text)
    return .visitChildren
  }

  // Nested function names shadow members
  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    names.insert(node.name.text)
    return .skipChildren
  }

  // Catch clauses have an implicit `error` variable when no explicit binding exists
  override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
    if node.catchItems.isEmpty {
      names.insert("error")
    }
    return .visitChildren
  }

  // Don't descend into nested closures — they have their own scope
  override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  // Don't descend into nested type declarations
  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }
  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }
  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }
  override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }
  override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }
}

// MARK: - Finding Messages

extension Finding.Message {
  fileprivate static let removeRedundantSelf: Finding.Message =
    "remove redundant 'self.' prefix"
}
