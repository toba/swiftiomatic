import Foundation
import SwiftSyntax

struct CyclomaticComplexityRule {
  var options = CyclomaticComplexityOptions()

  static let configuration = CyclomaticComplexityConfiguration()
}

extension CyclomaticComplexityRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension CyclomaticComplexityRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      guard let body = node.body else {
        return
      }

      // for legacy reasons, we try to put the violation in the static or class keyword
      let violationToken = node.modifiers.staticOrClassModifier ?? node.funcKeyword
      validate(body: body, violationToken: violationToken)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      guard let body = node.body else {
        return
      }

      validate(body: body, violationToken: node.initKeyword)
    }

    private func validate(body: CodeBlockSyntax, violationToken: TokenSyntax) {
      let complexity = ComplexityVisitor(
        ignoresCaseStatements: configuration.ignoresCaseStatements,
      ).walk(tree: body, handler: \.complexity)

      for parameter in configuration.params where complexity > parameter.value {
        let reason =
          "Function should have complexity \(configuration.length.warning) or less; "
          + "currently complexity is \(complexity)"

        let violation = SyntaxViolation(
          position: violationToken.positionAfterSkippingLeadingTrivia,
          reason: reason,
          severity: parameter.severity,
        )
        violations.append(violation)
        return
      }
    }
  }

  private final class ComplexityVisitor: SyntaxVisitor {
    private(set) var complexity = 0
    let ignoresCaseStatements: Bool

    init(ignoresCaseStatements: Bool) {
      self.ignoresCaseStatements = ignoresCaseStatements
      super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_: ForStmtSyntax) {
      complexity += 1
    }

    override func visitPost(_: IfExprSyntax) {
      complexity += 1
    }

    override func visitPost(_: GuardStmtSyntax) {
      complexity += 1
    }

    override func visitPost(_: RepeatStmtSyntax) {
      complexity += 1
    }

    override func visitPost(_: WhileStmtSyntax) {
      complexity += 1
    }

    override func visitPost(_: CatchClauseSyntax) {
      complexity += 1
    }

    override func visitPost(_: SwitchCaseSyntax) {
      if !ignoresCaseStatements {
        complexity += 1
      }
    }

    override func visitPost(_: FallThroughStmtSyntax) {
      // Switch complexity is reduced by `fallthrough` cases
      if !ignoresCaseStatements {
        complexity -= 1
      }
    }

    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }

    override func visit(_: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }
  }
}

extension DeclModifierListSyntax {
  fileprivate var staticOrClassModifier: TokenSyntax? {
    first { element in
      let kind = element.name.tokenKind
      return kind == .keyword(.static) || kind == .keyword(.class)
    }?.name
  }
}
