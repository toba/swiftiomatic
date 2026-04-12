import SwiftiomaticSyntax

struct DeadSymbolsRule: CollectingRule {
  static let id = "dead_symbols"
  static let name = "Dead Symbols"
  static let summary = "Private symbols with no references are likely dead code"
  static let scope: Scope = .suggest
  static let isOptIn = true
  static let isCrossFile = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        private func helper() {}
        func main() { helper() }
        """,
      )
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓private func unused() {}
        func main() { }
        """,
      )
    ]
  }

  typealias FileInfo = SymbolContribution

  var options = SeverityOption<Self>(.warning)
}

extension ViolationMessage {
  fileprivate static func deadPrivateSymbol(kind: String, name: String) -> Self {
    "Dead private \(kind): '\(name)' — no references found"
  }
}

extension DeadSymbolsRule {
  func collectInfo(for file: SwiftSource) -> SymbolContribution {
    let filePath = file.path ?? ""
    let collector = DeclarationReferenceCollector(filePath: filePath, viewMode: .sourceAccurate)
    collector.walk(file.syntaxTree)
    return SymbolContribution(
      declarations: collector.declarations, references: collector.references,
    )
  }

  func validate(file: SwiftSource, collectedInfo: [SwiftSource: SymbolContribution])
    -> [RuleViolation]
  {
    // Merge all contributions
    var allDeclarations: [SymbolDeclaration] = []
    var allReferences: Set<String> = []

    for (_, contribution) in collectedInfo {
      allDeclarations.append(contentsOf: contribution.declarations)
      allReferences.formUnion(contribution.references)
    }

    // Find unreferenced symbols that belong to this file
    guard let filePath = file.path else { return [] }

    return
      allDeclarations
      .filter { $0.file == filePath && !allReferences.contains($0.name) }
      .map { decl in
        RuleViolation(
          ruleType: Self.self,
          severity: options.severity,
          location: Location(file: filePath, line: decl.line, column: decl.column),
          message: .deadPrivateSymbol(kind: decl.kind, name: decl.name),
          confidence: .medium,
          suggestion: "Remove if unused, or change visibility if needed elsewhere",
        )
      }
  }
}

struct SymbolContribution {
  let declarations: [SymbolDeclaration]
  let references: [String]
}

struct SymbolDeclaration {
  let name: String
  let kind: String
  let file: String
  let line: Int
  let column: Int
}

private final class DeclarationReferenceCollector: SyntaxVisitor {
  let filePath: String
  var declarations: [SymbolDeclaration] = []
  var references: [String] = []

  init(filePath: String, viewMode: SyntaxTreeViewMode) {
    self.filePath = filePath
    super.init(viewMode: viewMode)
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    if isPrivate(node.modifiers), !shouldExclude(node) {
      let loc = node.startLocation(
        converter: .init(fileName: filePath, tree: node.root),
      )
      declarations.append(
        SymbolDeclaration(
          name: node.name.text, kind: "func", file: filePath,
          line: loc.line, column: loc.column,
        ),
      )
    }
    return .visitChildren
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    guard isPrivate(node.modifiers) else { return .visitChildren }
    for binding in node.bindings {
      guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
      let loc = binding.startLocation(
        converter: .init(fileName: filePath, tree: node.root),
      )
      declarations.append(
        SymbolDeclaration(
          name: pattern.identifier.text,
          kind: node.bindingSpecifier.tokenKind == .keyword(.let) ? "let" : "var",
          file: filePath, line: loc.line, column: loc.column,
        ),
      )
    }
    return .visitChildren
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if isPrivate(node.modifiers) {
      let loc = node.startLocation(
        converter: .init(fileName: filePath, tree: node.root),
      )
      declarations.append(
        SymbolDeclaration(
          name: node.name.text, kind: "class", file: filePath,
          line: loc.line, column: loc.column,
        ),
      )
    }
    return .visitChildren
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if isPrivate(node.modifiers) {
      let loc = node.startLocation(
        converter: .init(fileName: filePath, tree: node.root),
      )
      declarations.append(
        SymbolDeclaration(
          name: node.name.text, kind: "struct", file: filePath,
          line: loc.line, column: loc.column,
        ),
      )
    }
    return .visitChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if isPrivate(node.modifiers) {
      let loc = node.startLocation(
        converter: .init(fileName: filePath, tree: node.root),
      )
      declarations.append(
        SymbolDeclaration(
          name: node.name.text, kind: "enum", file: filePath,
          line: loc.line, column: loc.column,
        ),
      )
    }
    return .visitChildren
  }

  override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
    references.append(node.baseName.text)
    return .visitChildren
  }

  override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
    references.append(node.declName.baseName.text)
    return .visitChildren
  }

  private func isPrivate(_ modifiers: DeclModifierListSyntax) -> Bool {
    modifiers.contains { $0.name.text == "private" || $0.name.text == "fileprivate" }
  }

  private func shouldExclude(_ node: FunctionDeclSyntax) -> Bool {
    let name = node.name.text
    if name == "init" || name == "deinit" { return true }
    if node.attributes
      .contains(where: { $0.trimmedDescription.hasPrefix("@objc") })
    {
      return true
    }
    if node.modifiers.contains(where: { $0.name.text == "override" }) { return true }
    if name.hasPrefix("test") { return true }
    if name.count < 3 { return true }
    return false
  }
}
