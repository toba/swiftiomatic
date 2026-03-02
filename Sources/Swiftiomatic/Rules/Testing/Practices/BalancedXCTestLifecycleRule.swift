import SwiftSyntax

struct BalancedXCTestLifecycleRule {
    static let id = "balanced_xctest_lifecycle"
    static let name = "Balanced XCTest Life Cycle"
    static let summary = "Test classes must implement balanced setUp and tearDown methods"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUp() {}
                    override func tearDown() {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUpWithError() throws {}
                    override func tearDown() {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUp() {}
                    override func tearDownWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUpWithError() throws {}
                    override func tearDownWithError() throws {}
                }
                final class BarTests: XCTestCase {
                    override func setUpWithError() throws {}
                    override func tearDownWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                struct FooTests {
                    override func setUp() {}
                }
                class BarTests {
                    override func setUpWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUpAlLExamples() {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    class func setUp() {}
                    class func tearDown() {}
                }
                """#,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    override func setUp() {}
                }
                """#,
              ),
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    override func setUpWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUp() {}
                    override func tearDownWithError() throws {}
                }
                final class ↓BarTests: XCTestCase {
                    override func setUpWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    class func tearDown() {}
                }
                """#,
              ),
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    override func tearDown() {}
                }
                """#,
              ),
              Example(
                #"""
                final class ↓FooTests: XCTestCase {
                    override func tearDownWithError() throws {}
                }
                """#,
              ),
              Example(
                #"""
                final class FooTests: XCTestCase {
                    override func setUp() {}
                    override func tearDownWithError() throws {}
                }
                final class ↓BarTests: XCTestCase {
                    override func tearDownWithError() throws {}
                }
                """#,
              ),
            ]
    }
    static let rationale: String? = """
      The `setUp` method of `XCTestCase` can be used to set up variables and resources before \
      each test is run (or with the `class` variant, before all tests are run).

      This rule verifies that every class with an implementation of a `setUp` method also has \
      a `tearDown` method (and vice versa).

      The `tearDown` method should be used to cleanup or reset any resources that could \
      otherwise have any effects on subsequent tests, and to free up any instance variables.
      """
  var options = BalancedXCTestLifecycleOptions()

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
