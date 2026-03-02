import SwiftSyntax

struct UnusedControlFlowLabelRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnusedControlFlowLabelConfiguration()
}

extension UnusedControlFlowLabelRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension UnusedControlFlowLabelRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: LabeledStmtSyntax) {
      if let position = node.violationPosition {
        violations.append(position)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: LabeledStmtSyntax) -> StmtSyntax {
      guard node.violationPosition != nil else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return visit(node.statement.with(\.leadingTrivia, node.leadingTrivia))
    }
  }
}

extension LabeledStmtSyntax {
  fileprivate var violationPosition: AbsolutePosition? {
    let visitor = BreakAndContinueLabelCollector(viewMode: .sourceAccurate)
    let labels = visitor.walk(tree: self, handler: \.labels)
    guard !labels.contains(label.text) else {
      return nil
    }

    return label.positionAfterSkippingLeadingTrivia
  }
}

private final class BreakAndContinueLabelCollector: SyntaxVisitor {
  private(set) var labels: Set<String> = []

  override func visitPost(_ node: BreakStmtSyntax) {
    if let label = node.label?.text {
      labels.insert(label)
    }
  }

  override func visitPost(_ node: ContinueStmtSyntax) {
    if let label = node.label?.text {
      labels.insert(label)
    }
  }
}
