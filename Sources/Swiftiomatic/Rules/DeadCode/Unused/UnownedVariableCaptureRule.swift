import SwiftSyntax

struct UnownedVariableCaptureRule {
    static let id = "unowned_variable_capture"
    static let name = "Unowned Variable Capture"
    static let summary = "Prefer capturing references as weak to avoid potential crashes"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("foo { [weak self] in _ }"),
              Example("foo { [weak self] param in _ }"),
              Example("foo { [weak bar] in _ }"),
              Example("foo { [weak bar] param in _ }"),
              Example("foo { bar in _ }"),
              Example("foo { $0 }"),
              Example(
                """
                final class First {}
                final class Second {
                    unowned var value: First
                    init(value: First) {
                        self.value = value
                    }
                }
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("foo { [↓unowned self] in _ }"),
              Example("foo { [↓unowned bar] in _ }"),
              Example("foo { [bar, ↓unowned self] in _ }"),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension UnownedVariableCaptureRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnownedVariableCaptureRule {}

extension UnownedVariableCaptureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      if case .keyword(.unowned) = node.tokenKind,
        node.parent?.is(ClosureCaptureSpecifierSyntax.self) == true
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
