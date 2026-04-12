import SwiftiomaticSyntax

struct PrefixedTopLevelConstantRule {
  static let id = "prefixed_toplevel_constant"
  static let name = "Prefixed Top-Level Constant"
  static let summary = "Top-level constants should be prefixed by `k`"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("private let kFoo = 20.0"),
      Example("public let kFoo = false"),
      Example("internal let kFoo = \"Foo\""),
      Example("let kFoo = true"),
      Example("let Foo = true", configuration: ["only_private": true]),
      Example(
        """
        struct Foo {
            let bar = 20.0
        }
        """,
      ),
      Example("private var foo = 20.0"),
      Example("public var foo = false"),
      Example("internal var foo = \"Foo\""),
      Example("var foo = true"),
      Example("var foo = true, bar = true"),
      Example("var foo = true, let kFoo = true"),
      Example(
        """
        let
            kFoo = true
        """,
      ),
      Example(
        """
        var foo: Int {
            return a + b
        }
        """,
      ),
      Example(
        """
        let kFoo = {
            return a + b
        }()
        """,
      ),
      Example(
        """
        var foo: String {
            let bar = ""
            return bar
        }
        """,
      ),
      Example(
        """
        if condition() {
            let result = somethingElse()
            print(result)
            exit()
        }
        """,
      ),
      Example(
        #"""
        [1, 2, 3, 1000, 4000].forEach { number in
            let isSmall = number < 10
            if isSmall {
                print("\(number) is a small number")
            }
        }
        """#,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("private let ↓Foo = 20.0"),
      Example("public let ↓Foo = false"),
      Example("internal let ↓Foo = \"Foo\""),
      Example("let ↓Foo = true"),
      Example("let ↓foo = 2, ↓bar = true"),
      Example(
        """
        let
            ↓foo = true
        """,
      ),
      Example(
        """
        let ↓foo = {
            return a + b
        }()
        """,
      ),
    ]
  }

  var options = PrefixedTopLevelConstantOptions()
}

extension PrefixedTopLevelConstantRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PrefixedTopLevelConstantRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private let topLevelPrefix = "k"

    override var skipsNestedScopes: Bool { true }

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .allExcept(VariableDeclSyntax.self)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      guard node.bindingSpecifier.tokenKind == .keyword(.let) else {
        return
      }

      if configuration.onlyPrivateMembers, !node.modifiers.containsPrivateOrFileprivate() {
        return
      }

      for binding in node.bindings {
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          !pattern.identifier.text.hasPrefix(topLevelPrefix)
        else {
          continue
        }

        violations.append(binding.pattern.positionAfterSkippingLeadingTrivia)
      }
    }

  }
}
