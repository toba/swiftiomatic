// sm:disable file_length

import Foundation
import SwiftSyntax

struct NoMagicNumbersRule {
  var options = NoMagicNumbersOptions()

  static let configuration = NoMagicNumbersConfiguration()
}

extension NoMagicNumbersRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoMagicNumbersRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension NoMagicNumbersRule {}

extension NoMagicNumbersRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var testClasses: Set<String> = []
    private var nonTestClasses: Set<String> = []
    private var possibleViolations: [String: Set<AbsolutePosition>] = [:]

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
      node.isTestSuite ? .skipChildren : .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      node.isTestSuite ? .skipChildren : .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      let className = node.name.text
      if node.isXCTestCase(configuration.testParentClasses) {
        testClasses.insert(className)
        removeViolations(forClassName: className)
      } else {
        nonTestClasses.insert(className)
      }
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      node.isTestSuite ? .skipChildren : .visitChildren
    }

    override func visitPost(_ node: FloatLiteralExprSyntax) {
      guard node.literal.isMagicNumber(configuration.allowedNumbers) else {
        return
      }
      collectViolation(forNode: node)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
      node.attributes.contains(attributeNamed: "Test") ? .skipChildren : .visitChildren
    }

    override func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind {
      if let elements = node.elements {
        walk(elements)
      }
      return .skipChildren
    }

    override func visitPost(_ node: IntegerLiteralExprSyntax) {
      guard node.literal.isMagicNumber(configuration.allowedNumbers) else {
        return
      }
      collectViolation(forNode: node)
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
      node.macroName.text == "Preview" ? .skipChildren : .visitChildren
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
      node.isSimpleTupleAssignment ? .skipChildren : .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
      node.isTestSuite ? .skipChildren : .visitChildren
    }

    private func collectViolation(forNode node: some ExprSyntaxProtocol) {
      if node.isMemberOfATestClass(configuration.testParentClasses) {
        return
      }
      if node.isOperandOfFreestandingShiftOperation() {
        return
      }
      if node.isPartOfUIColorInitializer() {
        return
      }
      let violation = node.positionAfterSkippingLeadingTrivia
      if let extendedTypeName = node.extendedTypeName() {
        if !testClasses.contains(extendedTypeName) {
          violations.append(violation)
          if !nonTestClasses.contains(extendedTypeName) {
            possibleViolations[extendedTypeName, default: []].insert(violation)
          }
        }
      } else {
        violations.append(violation)
      }
    }

    private func removeViolations(forClassName className: String) {
      guard let possibleViolationsForClass = possibleViolations[className] else {
        return
      }
      let violationsToRemove = Set(
        possibleViolationsForClass.map { SyntaxViolation(position: $0) },
      )
      violations.removeAll { violationsToRemove.contains($0) }
      possibleViolations.removeValue(forKey: className)
    }
  }
}

extension DeclGroupSyntax {
  fileprivate var isTestSuite: Bool {
    if attributes.contains(attributeNamed: "Suite") {
      return true
    }
    return memberBlock.members.contains {
      $0.decl.as(FunctionDeclSyntax.self)?.attributes.contains(attributeNamed: "Test") == true
    }
  }
}

extension TokenSyntax {
  fileprivate func isMagicNumber(_ allowedNumbers: Set<Double>) -> Bool {
    guard let number = Double(text.replacingOccurrences(of: "_", with: "")) else {
      return false
    }
    if allowedNumbers.contains(number) {
      return false
    }
    guard let grandparent = parent?.parent else {
      return true
    }
    if grandparent.is(InitializerClauseSyntax.self) {
      return false
    }
    let operatorParent =
      grandparent.as(PrefixOperatorExprSyntax.self)?.parent
      ?? grandparent.as(PostfixOperatorExprSyntax.self)?.parent
      ?? grandparent.asAcceptedInfixOperator?.parent
    return operatorParent?.is(InitializerClauseSyntax.self) != true
  }
}

extension Syntax {
  fileprivate var asAcceptedInfixOperator: InfixOperatorExprSyntax? {
    if let infixOp = `as`(InfixOperatorExprSyntax.self),
      let operatorSymbol = infixOp.operator.as(BinaryOperatorExprSyntax.self)?.operator
        .tokenKind,
      [.binaryOperator("..."), .binaryOperator("..<")].contains(operatorSymbol)
    {
      return infixOp
    }
    return nil
  }
}

extension ExprSyntaxProtocol {
  fileprivate func isMemberOfATestClass(_ testParentClasses: Set<String>) -> Bool {
    var parent = parent
    while parent != nil {
      if let classDecl = parent?.as(ClassDeclSyntax.self),
        classDecl.isXCTestCase(testParentClasses)
      {
        return true
      }
      parent = parent?.parent
    }
    return false
  }

  fileprivate func extendedTypeName() -> String? {
    var parent = parent
    while parent != nil {
      if let extensionDecl = parent?.as(ExtensionDeclSyntax.self) {
        return extensionDecl.extendedType.trimmedDescription
      }
      parent = parent?.parent
    }
    return nil
  }

  fileprivate func isOperandOfFreestandingShiftOperation() -> Bool {
    if let operation = parent?.as(InfixOperatorExprSyntax.self),
      let operatorSymbol = operation.operator.as(BinaryOperatorExprSyntax.self)?.operator
        .tokenKind,
      [.binaryOperator("<<"), .binaryOperator(">>")].contains(operatorSymbol)
    {
      return operation.parent?.isProtocol((any ExprSyntaxProtocol).self) != true
    }
    return false
  }

  fileprivate func isPartOfUIColorInitializer() -> Bool {
    guard let param = parent?.as(LabeledExprSyntax.self),
      let label = param.label?.text
    else {
      return false
    }
    let uiColorInitializerLabels = [
      "white", "alpha", "red", "displayP3Red", "green", "blue", "hue",
      "saturation", "brightness", "cgColor", "ciColor", "resource", "patternImage",
    ]
    if uiColorInitializerLabels.contains(label),
      let call = param.parent?.as(LabeledExprListSyntax.self)?.parent?.as(
        FunctionCallExprSyntax.self,
      )
    {
      if let calledExpr = call.calledExpression.as(DeclReferenceExprSyntax.self),
        calledExpr.baseName.text == "UIColor"
      {
        return true
      }
      if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self),
        let baseExpr = memberAccess.base?.as(DeclReferenceExprSyntax.self),
        baseExpr.baseName.text == "UIColor",
        memberAccess.declName.baseName.text == "init"
      {
        return true
      }
    }
    if ["red", "green", "blue", "alpha"].contains(label),
      let call = param.parent?.as(LabeledExprListSyntax.self)?.parent?.as(
        MacroExpansionExprSyntax.self,
      ),
      call.macroName.text == "colorLiteral"
    {
      return true
    }
    return false
  }
}

extension PatternBindingSyntax {
  fileprivate var isSimpleTupleAssignment: Bool {
    initializer?.value.as(TupleExprSyntax.self)?.elements.allSatisfy {
      $0.expression.is(IntegerLiteralExprSyntax.self)
        || $0.expression.is(FloatLiteralExprSyntax.self)
        || $0.expression.is(StringLiteralExprSyntax.self)
        || $0.expression.is(BooleanLiteralExprSyntax.self)
    } ?? false
  }
}
