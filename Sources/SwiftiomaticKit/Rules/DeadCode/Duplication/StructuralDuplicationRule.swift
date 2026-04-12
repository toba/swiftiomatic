import SwiftiomaticSyntax

struct StructuralDuplicationRule: CollectingRule {
  static let id = "structural_duplication"
  static let name = "Structural Duplication"
  static let summary =
    "Functions with identical AST structure are likely duplicated code that should be consolidated"
  static let isOptIn = true
  static let isCrossFile = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("func unique1() { print(1) }\nfunc unique2() { return 2 }")
    ]
  }

  static var triggeringExamples: [Example] {
    []
  }

  typealias FileInfo = [FunctionFingerprint]

  var options = SeverityOption<Self>(.warning)

  func collectInfo(for file: SwiftSource) -> [FunctionFingerprint] {
    guard let path = file.path else { return [] }
    let collector = FingerprintCollector(filePath: path, viewMode: .sourceAccurate)
    collector.walk(file.syntaxTree)
    return collector.fingerprints
  }

  func validate(file: SwiftSource, collectedInfo: [SwiftSource: [FunctionFingerprint]])
    -> [RuleViolation]
  {
    guard let filePath = file.path else { return [] }

    // Group all fingerprints by their structural hash
    var groups: [String: [FunctionFingerprint]] = [:]
    for (_, fingerprints) in collectedInfo {
      for fp in fingerprints {
        groups[fp.fingerprint, default: []].append(fp)
      }
    }

    var violations: [RuleViolation] = []

    for (_, members) in groups where members.count >= 2 {
      let confidence: Confidence = members.count >= 3 ? .high : .medium

      for (index, member) in members.enumerated() where member.file == filePath {
        let peers = members.enumerated()
          .filter { $0.offset != index }
          .map { "'\($0.element.name)' (\($0.element.file):\($0.element.line))" }
          .joined(separator: ", ")

        violations.append(
          RuleViolation(
            ruleType: Self.self,
            severity: options.severity,
            location: Location(file: filePath, line: member.line, column: 1),
            reason: "Function '\(member.name)' is structurally identical to \(peers)",
            confidence: confidence,
            suggestion: "Consider extracting shared logic into a common function",
          ),
        )
      }
    }

    return violations
  }
}

struct FunctionFingerprint {
  let name: String
  let file: String
  let line: Int
  let fingerprint: String
}

/// Recursively walks a syntax subtree and collects the type name of every
/// non-token, non-trivia node to produce a structural fingerprint.
enum FingerprintBuilder {
  /// Container node types to skip — they add no structural signal.
  private static let containerTypes: Set<String> = [
    "CodeBlockSyntax",
    "CodeBlockItemListSyntax",
    "CodeBlockItemSyntax",
  ]

  /// Collect structural node type names from the given syntax subtree.
  static func collectNodeTypes(from node: some SyntaxProtocol) -> [String] {
    var result: [String] = []
    collect(from: Syntax(node), into: &result)
    return result
  }

  private static func collect(from node: Syntax, into result: inout [String]) {
    // Skip tokens — we only care about structural (non-leaf) nodes.
    if node.is(TokenSyntax.self) { return }

    let typeName = "\(type(of: node.asProtocol(SyntaxProtocol.self)))"

    if !containerTypes.contains(typeName) {
      result.append(typeName)
    }

    for child in node.children(viewMode: .sourceAccurate) {
      collect(from: child, into: &result)
    }
  }
}

private final class FingerprintCollector: SyntaxVisitor {
  let filePath: String
  var fingerprints: [FunctionFingerprint] = []

  init(filePath: String, viewMode: SyntaxTreeViewMode) {
    self.filePath = filePath
    super.init(viewMode: viewMode)
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let body = node.body else { return .visitChildren }

    let nodes = FingerprintBuilder.collectNodeTypes(from: body)
    guard nodes.count >= 5 else { return .visitChildren }

    let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))
    fingerprints.append(
      FunctionFingerprint(
        name: node.name.text,
        file: filePath,
        line: loc.line,
        fingerprint: nodes.joined(separator: ","),
      ),
    )

    return .visitChildren
  }
}
