import SwiftSyntax

struct UnusedEnumeratedRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnusedEnumeratedConfiguration()
}

extension UnusedEnumeratedRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnusedEnumeratedRule {
  private struct Closure {
    let enumeratedPosition: AbsolutePosition?
    var zeroPosition: AbsolutePosition?
    var onePosition: AbsolutePosition?

    init(enumeratedPosition: AbsolutePosition? = nil) {
      self.enumeratedPosition = enumeratedPosition
    }
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var nextClosureId: SyntaxIdentifier?
    private var lastEnumeratedPosition: AbsolutePosition?
    private var closures = Stack<Closure>()

    override func visitPost(_ node: ForStmtSyntax) {
      guard let tuplePattern = node.pattern.as(TuplePatternSyntax.self),
        tuplePattern.elements.count == 2,
        let functionCall = node.sequence.asFunctionCall,
        functionCall.isEnumerated,
        let firstElement = tuplePattern.elements.first,
        let secondElement = tuplePattern.elements.last
      else {
        return
      }

      let firstTokenIsUnderscore = firstElement.isUnderscore
      let lastTokenIsUnderscore = secondElement.isUnderscore
      guard firstTokenIsUnderscore || lastTokenIsUnderscore else {
        return
      }

      addViolation(
        zeroPosition: firstTokenIsUnderscore
          ? firstElement.positionAfterSkippingLeadingTrivia : nil,
        onePosition: firstTokenIsUnderscore
          ? nil
          : secondElement
            .positionAfterSkippingLeadingTrivia,
      )
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
      guard node.isEnumerated,
        let parent = node.parent,
        parent.as(MemberAccessExprSyntax.self)?.declName.baseName.text != "filter",
        let trailingClosure = parent.parent?.as(FunctionCallExprSyntax.self)?
          .trailingClosure
      else {
        return .visitChildren
      }

      if let parameterClause = trailingClosure.signature?.parameterClause {
        guard
          let parameterClause =
            parameterClause
            .as(ClosureShorthandParameterListSyntax.self),
          parameterClause.count == 2,
          let firstElement = parameterClause.first,
          let secondElement = parameterClause.last
        else {
          return .visitChildren
        }

        let firstTokenIsUnderscore = firstElement.isUnderscore
        let lastTokenIsUnderscore = secondElement.isUnderscore
        guard firstTokenIsUnderscore || lastTokenIsUnderscore else {
          return .visitChildren
        }

        addViolation(
          zeroPosition: firstTokenIsUnderscore
            ? firstElement.positionAfterSkippingLeadingTrivia : nil,
          onePosition: firstTokenIsUnderscore
            ? nil : secondElement.positionAfterSkippingLeadingTrivia,
        )
      } else {
        nextClosureId = trailingClosure.id
        lastEnumeratedPosition = node.enumeratedPosition
      }

      return .visitChildren
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      if let nextClosureId, nextClosureId == node.id, let lastEnumeratedPosition {
        closures.push(Closure(enumeratedPosition: lastEnumeratedPosition))
        self.nextClosureId = nil
        self.lastEnumeratedPosition = nil
      } else {
        closures.push(Closure())
      }
      return .visitChildren
    }

    override func visitPost(_: ClosureExprSyntax) {
      if let closure = closures.pop(),
        (closure.zeroPosition != nil) != (closure.onePosition != nil)
      {
        addViolation(
          zeroPosition: closure.onePosition,
          onePosition: closure.zeroPosition,
          enumeratedPosition: closure.enumeratedPosition,
        )
      }
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      guard
        let closure = closures.peek(),
        closure.enumeratedPosition != nil,
        node.baseName.text == "$0" || node.baseName.text == "$1"
      else {
        return
      }
      closures.modifyLast {
        if node.baseName.text == "$0" {
          let member = node.parent?.as(MemberAccessExprSyntax.self)?.declName.baseName
            .text
          if member == "element" || member == "1" {
            $0.onePosition = node.positionAfterSkippingLeadingTrivia
          } else {
            $0.zeroPosition = node.positionAfterSkippingLeadingTrivia
            if node.isUnpacked {
              $0.onePosition = node.positionAfterSkippingLeadingTrivia
            }
          }
        } else {
          $0.onePosition = node.positionAfterSkippingLeadingTrivia
        }
      }
    }

    private func addViolation(
      zeroPosition: AbsolutePosition?,
      onePosition: AbsolutePosition?,
      enumeratedPosition: AbsolutePosition? = nil,
    ) {
      var position: AbsolutePosition?
      var reason: String?
      if let zeroPosition {
        position = zeroPosition
        reason = "When the index is not used, `.enumerated()` can be removed"
      } else if let onePosition {
        position = onePosition
        reason = "When the item is not used, `.indices` should be used instead of `.enumerated()`"
      }

      if let enumeratedPosition {
        position = enumeratedPosition
      }

      if let position, let reason {
        violations.append(SyntaxViolation(position: position, reason: reason))
      }
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var isEnumerated: Bool {
    enumeratedPosition != nil
  }

  fileprivate var enumeratedPosition: AbsolutePosition? {
    if let memberAccess = calledExpression.as(MemberAccessExprSyntax.self),
      memberAccess.base != nil,
      memberAccess.declName.baseName.text == "enumerated",
      hasNoArguments
    {
      return memberAccess.declName.positionAfterSkippingLeadingTrivia
    }

    return nil
  }

  fileprivate var hasNoArguments: Bool {
    trailingClosure == nil
      && additionalTrailingClosures.isEmpty
      && arguments.isEmpty
  }
}

extension TuplePatternElementSyntax {
  fileprivate var isUnderscore: Bool {
    pattern.is(WildcardPatternSyntax.self)
  }
}

extension ClosureShorthandParameterSyntax {
  fileprivate var isUnderscore: Bool {
    name.tokenKind == .wildcard
  }
}

extension DeclReferenceExprSyntax {
  fileprivate var isUnpacked: Bool {
    if let initializer = parent?.as(InitializerClauseSyntax.self),
      let binding = initializer.parent?.as(PatternBindingSyntax.self),
      let elements = binding.pattern.as(TuplePatternSyntax.self)?.elements
    {
      return elements.count == 2
        && elements.allSatisfy { !$0.pattern.is(WildcardPatternSyntax.self) }
    }
    return false
  }
}
