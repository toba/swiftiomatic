import SwiftSyntax

struct NestingRule {
  static let id = "nesting"
  static let name = "Nesting"
  static let summary =
    "Types should be nested at most 1 level deep, and functions should be nested at most 2 levels deep."
  var options = NestingOptions()
}

extension ViolationMessage {
  fileprivate static func nestingTooDeep(
    _ targetName: String, threshold: Int, pluralSuffix: String,
  ) -> Self {
    "\(targetName) should be nested at most \(threshold) level\(pluralSuffix) deep"
  }
}

extension NestingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

private struct Levels {
  var lastIsFunction: Bool {
    functionOrNotStack.peek() == true
  }

  private(set) var typeLevel: Int = -1
  private(set) var functionLevel: Int = -1
  private var functionOrNotStack = Stack<Bool>()

  mutating func push(_ isFunction: Bool) {
    functionOrNotStack.push(isFunction)
    updateLevel(with: 1)
  }

  mutating func pop() {
    updateLevel(with: -1)
    functionOrNotStack.pop()
  }

  private mutating func updateLevel(with value: Int) {
    if lastIsFunction {
      functionLevel += value
    } else {
      typeLevel += value
    }
  }
}

extension NestingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var levels = Levels()

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
      validate(forFunction: false, triggeringToken: node.actorKeyword)
      return .visitChildren
    }

    override func visitPost(_: ActorDeclSyntax) {
      levels.pop()
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      validate(forFunction: false, triggeringToken: node.classKeyword)
      return .visitChildren
    }

    override func visitPost(_: ClassDeclSyntax) {
      levels.pop()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      // if current defines coding keys and we're ignoring coding keys, then skip nesting rule
      // push another level on and proceed to visit children
      if configuration.ignoreCodingKeys, node.definesCodingKeys {
        levels.push(levels.lastIsFunction)
      } else {
        validate(forFunction: false, triggeringToken: node.enumKeyword)
      }

      return .visitChildren
    }

    override func visitPost(_: EnumDeclSyntax) {
      levels.pop()
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
      validate(forFunction: false, triggeringToken: node.extensionKeyword)
      return .visitChildren
    }

    override func visitPost(_: ExtensionDeclSyntax) {
      levels.pop()
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
      validate(forFunction: true, triggeringToken: node.funcKeyword)
      return .visitChildren
    }

    override func visitPost(_: FunctionDeclSyntax) {
      levels.pop()
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
      validate(forFunction: false, triggeringToken: node.protocolKeyword)
      return .visitChildren
    }

    override func visitPost(_: ProtocolDeclSyntax) {
      levels.pop()
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
      validate(forFunction: false, triggeringToken: node.structKeyword)
      return .visitChildren
    }

    override func visitPost(_: StructDeclSyntax) {
      levels.pop()
    }

    // MARK: - configuration for ignoreTypealiasesAndAssociatedTypes

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      if configuration.ignoreTypealiasesAndAssociatedTypes {
        return
      }
      validate(forFunction: false, triggeringToken: node.typealiasKeyword)
      levels.pop()
    }

    override func visitPost(_ node: AssociatedTypeDeclSyntax) {
      if configuration.ignoreTypealiasesAndAssociatedTypes {
        return
      }
      validate(forFunction: false, triggeringToken: node.associatedtypeKeyword)
      levels.pop()
    }

    // MARK: - configuration for checkNestingInClosuresAndStatements

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      guard configuration.checkNestingInClosuresAndStatements else {
        return .skipChildren
      }
      return super.visit(node)
    }

    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
      if !configuration.checkNestingInClosuresAndStatements,
        node.parent?.inStatement ?? false
      {
        return .skipChildren
      }
      return super.visit(node)
    }

    // MARK: -

    private func validate(forFunction: Bool, triggeringToken: TokenSyntax) {
      let inFunction = levels.lastIsFunction
      levels.push(forFunction)

      let level = forFunction ? levels.functionLevel : levels.typeLevel
      let targetLevel = forFunction ? configuration.functionLevel : configuration.typeLevel

      // if parent is function and current is not function types, then skip nesting rule.
      if configuration.alwaysAllowOneTypeInFunctions, inFunction, !forFunction {
        return
      }

      guard let severity = configuration.severity(with: targetLevel, for: level)
      else { return }

      let targetName = forFunction ? "Functions" : "Types"
      let threshold = configuration.threshold(with: targetLevel, for: severity)
      let pluralSuffix = threshold > 1 ? "s" : ""
      violations.append(
        SyntaxViolation(
          position: triggeringToken.positionAfterSkippingLeadingTrivia,
          message: .nestingTooDeep(
            targetName,
            threshold: threshold,
            pluralSuffix: pluralSuffix,
          ),
          severity: severity,
        ),
      )
    }
  }
}

extension Syntax {
  fileprivate var inStatement: Bool {
    func isStatement(_ node: Syntax) -> Bool {
      node.isProtocol((any StmtSyntaxProtocol).self) || node.parent.map(isStatement) ?? false
    }
    return isStatement(self)
  }
}
