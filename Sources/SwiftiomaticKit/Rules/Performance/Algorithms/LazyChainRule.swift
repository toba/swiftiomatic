import SwiftSyntax

struct LazyChainRule {
  static let id = "lazy_chain"
  static let name = "Lazy Chain"
  static let summary =
    "Detects 3+ chained functional transforms (map/filter/compactMap/flatMap) without .lazy"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("[1, 2].map { $0 * 2 }.filter { $0 > 2 }"),
      Example(
        """
        [1, 2, 3].lazy
          .map { $0 * 2 }
          .filter { $0 > 2 }
          .compactMap { Optional($0) }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        [1, 2, 3]
          .↓map { $0 * 2 }
          .filter { $0 > 2 }
          .compactMap { Optional($0) }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension LazyChainRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LazyChainRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      let memberName = node.declName.baseName.text

      let chainableOps: Set<String> = ["map", "flatMap", "compactMap", "filter"]
      guard chainableOps.contains(memberName) else { return }

      // Walk up the chain to count consecutive functional operations
      var chainLength = 1
      var current: ExprSyntax? = node.base
      while let memberAccess = current?.as(FunctionCallExprSyntax.self),
        let callee = memberAccess.calledExpression.as(MemberAccessExprSyntax.self),
        chainableOps.contains(callee.declName.baseName.text)
      {
        chainLength += 1
        current = callee.base
      }

      guard chainLength >= 3 else { return }

      // Check the root of the chain doesn't already use .lazy
      var root: ExprSyntax? = node.base
      for _ in 0..<(chainLength - 1) {
        if let call = root?.as(FunctionCallExprSyntax.self),
          let member = call.calledExpression.as(MemberAccessExprSyntax.self)
        {
          root = member.base
        }
      }
      let rootStr = root?.trimmedDescription ?? ""
      guard !rootStr.hasSuffix(".lazy") else { return }

      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason:
            "Chain of \(chainLength)+ functional transforms without .lazy — creates intermediate arrays",
          severity: .warning,
          confidence: .medium,
          suggestion: "Prefix the chain with .lazy to avoid intermediate allocations",
        ),
      )
    }
  }
}
