import SwiftSyntax

struct CaseIterableUsageRule: CollectingRule {
    static let id = "case_iterable_usage"
    static let name = "CaseIterable Usage"
    static let summary = "Enums conforming to CaseIterable without any .allCases references may have unnecessary conformance"
    static let scope: Scope = .suggest
    static let isOptIn = true
    static let isCrossFile = true
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum Direction: CaseIterable { case north, south }
                let all = Direction.allCases
                """,
              )
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓enum Status: CaseIterable { case active, inactive }
                func check() { }
                """,
              )
            ]
    }
  typealias FileInfo = CaseIterableContribution

  var options = SeverityOption<Self>(.warning)

  func collectInfo(for file: SwiftSource) -> CaseIterableContribution {
    let collector = CaseIterableCollector(
      filePath: file.path ?? "",
      viewMode: .sourceAccurate,
    )
    collector.walk(file.syntaxTree)
    return CaseIterableContribution(
      caseIterableEnums: collector.caseIterableEnums,
      allCasesReferences: collector.allCasesReferences,
    )
  }

  func validate(
    file: SwiftSource,
    collectedInfo: [SwiftSource: CaseIterableContribution],
  ) -> [RuleViolation] {
    guard let filePath = file.path else { return [] }

    // Merge all contributions
    var allEnums: [CaseIterableEnum] = []
    var allReferences: Set<String> = []

    for (_, contribution) in collectedInfo {
      allEnums.append(contentsOf: contribution.caseIterableEnums)
      allReferences.formUnion(contribution.allCasesReferences)
    }

    // Find enums in this file with no .allCases references
    return
      allEnums
      .filter { $0.file == filePath && !allReferences.contains($0.name) }
      .map { decl in
        RuleViolation(
          ruleType: Self.self,
          severity: options.severity,
          location: Location(file: filePath, line: decl.line, column: decl.column),
          reason:
            "Enum '\(decl.name)' conforms to CaseIterable but .allCases is never referenced",
          confidence: .medium,
          suggestion: "Remove CaseIterable conformance if unused, or use .allCases",
        )
      }
  }
}

struct CaseIterableContribution {
  let caseIterableEnums: [CaseIterableEnum]
  let allCasesReferences: [String]
}

struct CaseIterableEnum {
  let name: String
  let file: String
  let line: Int
  let column: Int
}

private final class CaseIterableCollector: SyntaxVisitor {
  let filePath: String
  var caseIterableEnums: [CaseIterableEnum] = []
  var allCasesReferences: [String] = []

  init(filePath: String, viewMode: SyntaxTreeViewMode) {
    self.filePath = filePath
    super.init(viewMode: viewMode)
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if let inheritance = node.inheritanceClause {
      let types = inheritance.inheritedTypes.map(\.type.trimmedDescription)
      if types.contains("CaseIterable") {
        let loc = node.startLocation(
          converter: .init(fileName: filePath, tree: node.root),
        )
        caseIterableEnums.append(
          CaseIterableEnum(
            name: node.name.text,
            file: filePath,
            line: loc.line,
            column: loc.column,
          ),
        )
      }
    }
    return .visitChildren
  }

  override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
    if node.declName.baseName.text == "allCases" {
      // Record the type name from the base expression
      if let base = node.base?.as(DeclReferenceExprSyntax.self) {
        allCasesReferences.append(base.baseName.text)
      } else if let base = node.base?.as(MemberAccessExprSyntax.self) {
        allCasesReferences.append(base.declName.baseName.text)
      }
    }
    return .visitChildren
  }
}
