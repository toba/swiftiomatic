import SwiftSyntax

struct VoidFunctionInTernaryConditionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = VoidFunctionInTernaryConditionConfiguration()
}

extension VoidFunctionInTernaryConditionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension VoidFunctionInTernaryConditionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TernaryExprSyntax) {
      guard node.thenExpression.is(FunctionCallExprSyntax.self),
        node.elseExpression.is(FunctionCallExprSyntax.self),
        let parent = node.parent?.as(ExprListSyntax.self),
        !parent.containsAssignment,
        let grandparent = parent.parent,
        grandparent.is(SequenceExprSyntax.self),
        let blockItem = grandparent.parent?.as(CodeBlockItemSyntax.self),
        !blockItem.isImplicitReturn
      else {
        return
      }

      violations.append(node.questionMark.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: UnresolvedTernaryExprSyntax) {
      guard node.thenExpression.is(FunctionCallExprSyntax.self),
        let parent = node.parent?.as(ExprListSyntax.self),
        parent.last?.is(FunctionCallExprSyntax.self) == true,
        !parent.containsAssignment,
        let grandparent = parent.parent,
        grandparent.is(SequenceExprSyntax.self),
        let blockItem = grandparent.parent?.as(CodeBlockItemSyntax.self),
        !blockItem.isImplicitReturn
      else {
        return
      }

      violations.append(node.questionMark.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension ExprListSyntax {
  fileprivate var containsAssignment: Bool {
    children(viewMode: .sourceAccurate).contains {
      if let binOp = $0.as(BinaryOperatorExprSyntax.self) {
        // https://developer.apple.com/documentation/swift/operator-declarations
        return [
          "*=",
          "/=",
          "%=",
          "+=",
          "-=",
          "<<=",
          ">>=",
          "&=",
          "|=",
          "^=",
          "&*=",
          "&+=",
          "&-=",
          "&<<=",
          "&>>=",
          ".&=",
          ".|=",
          ".^=",
        ].contains(binOp.operator.text)
      }
      return $0.is(AssignmentExprSyntax.self)
    }
  }
}

extension CodeBlockItemSyntax {
  fileprivate var isImplicitReturn: Bool {
    isClosureImplicitReturn || isFunctionImplicitReturn || isVariableImplicitReturn
      || isSubscriptImplicitReturn || isAccessorImplicitReturn
  }

  fileprivate var isClosureImplicitReturn: Bool {
    guard let parent = parent?.as(CodeBlockItemListSyntax.self),
      let grandparent = parent.parent
    else {
      return false
    }

    return parent.children(viewMode: .sourceAccurate).count == 1
      && grandparent.is(ClosureExprSyntax.self)
  }

  fileprivate var isFunctionImplicitReturn: Bool {
    guard let parent = parent?.as(CodeBlockItemListSyntax.self),
      let functionDecl = parent.parent?.parent?.as(FunctionDeclSyntax.self)
    else {
      return false
    }

    return parent.children(viewMode: .sourceAccurate).count == 1
      && functionDecl.signature.allowsImplicitReturns
  }

  fileprivate var isVariableImplicitReturn: Bool {
    guard let parent = parent?.as(CodeBlockItemListSyntax.self) else {
      return false
    }

    let isVariableDecl = parent.parent?.parent?.as(PatternBindingSyntax.self) != nil
    return parent.children(viewMode: .sourceAccurate).count == 1 && isVariableDecl
  }

  fileprivate var isSubscriptImplicitReturn: Bool {
    guard let parent = parent?.as(CodeBlockItemListSyntax.self),
      let subscriptDecl = parent.parent?.parent?.as(SubscriptDeclSyntax.self)
    else {
      return false
    }

    return parent.children(viewMode: .sourceAccurate).count == 1
      && subscriptDecl.allowsImplicitReturns
  }

  fileprivate var isAccessorImplicitReturn: Bool {
    guard let parent = parent?.as(CodeBlockItemListSyntax.self),
      parent.parent?.parent?.as(AccessorDeclSyntax.self) != nil
    else {
      return false
    }

    return parent.children(viewMode: .sourceAccurate).count == 1
  }
}

extension FunctionSignatureSyntax {
  fileprivate var allowsImplicitReturns: Bool {
    returnClause?.allowsImplicitReturns ?? false
  }
}

extension SubscriptDeclSyntax {
  fileprivate var allowsImplicitReturns: Bool {
    returnClause.allowsImplicitReturns
  }
}

extension ReturnClauseSyntax {
  fileprivate var allowsImplicitReturns: Bool {
    if let simpleType = type.as(IdentifierTypeSyntax.self) {
      return simpleType.name.text != "Void" && simpleType.name.text != "Never"
    }
    if let tupleType = type.as(TupleTypeSyntax.self) {
      return !tupleType.elements.isEmpty
    }
    return true
  }
}
