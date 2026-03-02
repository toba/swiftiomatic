import SwiftSyntax

struct BalancedXCTestLifecycleRule {
  var options = BalancedXCTestLifecycleOptions()

  static let configuration = BalancedXCTestLifecycleConfiguration()
}

extension BalancedXCTestLifecycleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension BalancedXCTestLifecycleRule {}

// MARK: - Private

extension BalancedXCTestLifecycleRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      guard node.isXCTestCase(configuration.testParentClasses) else {
        return
      }

      let methods = SetupTearDownVisitor(configuration: configuration, file: file)
        .walk(tree: node.memberBlock, handler: \.methods)
      guard methods.contains(.setUp) != methods.contains(.tearDown) else {
        return
      }

      violations.append(node.name.positionAfterSkippingLeadingTrivia)
    }
  }
}

private final class SetupTearDownVisitor<Configuration: RuleOptions>:
  ViolationCollectingVisitor<
    Configuration,
  >
{
  override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
    .all
  }

  private(set) var methods: Set<XCTMethod> = []

  override func visitPost(_ node: FunctionDeclSyntax) {
    if let method = XCTMethod(node.name.description),
      node.signature.parameterClause.parameters.isEmpty
    {
      methods.insert(method)
    }
  }
}

private enum XCTMethod {
  case setUp
  case tearDown

  init?(_ name: String?) {
    switch name {
    case "setUp", "setUpWithError": self = .setUp
    case "tearDown", "tearDownWithError": self = .tearDown
    default: return nil
    }
  }
}
