import SwiftiomaticSyntax

struct AttributeNameSpacingRule {
  static let id = "attribute_name_spacing"
  static let name = "Attribute Name Spacing"
  static let summary = "There should be no space between an attribute or modifier and its arguments"
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("private(set) var foo: Bool = false"),
      Example("fileprivate(set) var foo: Bool = false"),
      Example("@MainActor class Foo {}"),
      Example("func funcWithEscapingClosure(_ x: @escaping () -> Int) {}"),
      Example("@available(*, deprecated)"),
      Example("@MyPropertyWrapper(param: 2) "),
      Example("nonisolated(unsafe) var _value: X?"),
      Example("@testable import SwiftLintCore"),
      Example("func func_type_attribute_with_space(x: @convention(c) () -> Int) {}"),
      Example(
        """
        @propertyWrapper
        struct MyPropertyWrapper {
            var wrappedValue: Int = 1

            init(param: Int) {}
        }
        """,
      ),
      Example(
        """
        let closure2 = { @MainActor
          (a: Int, b: Int) in
        }
        """,
      ),
      Example(
        """
        let closure1 = { @MainActor (a, b) in
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("private ↓(set) var foo: Bool = false"),
      Example("fileprivate ↓(set) var foo: Bool = false"),
      Example("public ↓(set) var foo: Bool = false"),
      Example("  public  ↓(set) var foo: Bool = false"),
      Example("@ ↓MainActor class Foo {}"),
      Example("func funcWithEscapingClosure(_ x: @ ↓escaping () -> Int) {}"),
      Example("func funcWithEscapingClosure(_ x: @escaping↓() -> Int) {}"),
      Example("@available ↓(*, deprecated)"),
      Example("@MyPropertyWrapper ↓(param: 2) let a = 1"),
      Example("nonisolated ↓(unsafe) var _value: X?"),
      Example("@MyProperty ↓() class Foo {}"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("private↓ (set) var foo: Bool = false"): Example(
        "private(set) var foo: Bool = false",
      ),
      Example("fileprivate↓ (set) var foo: Bool = false"): Example(
        "fileprivate(set) var foo: Bool = false",
      ),
      Example("internal↓ (set) var foo: Bool = false"): Example(
        "internal(set) var foo: Bool = false",
      ),
      Example("public↓ (set) var foo: Bool = false"): Example(
        "public(set) var foo: Bool = false",
      ),
      Example("public↓  (set) var foo: Bool = false"): Example(
        "public(set) var foo: Bool = false",
      ),
      Example("@↓ MainActor"): Example("@MainActor"),
      Example("func test(_ x: @↓ escaping () -> Int) {}"): Example(
        "func test(_ x: @escaping () -> Int) {}",
      ),
      Example("func test(_ x: @escaping↓() -> Int) {}"): Example(
        "func test(_ x: @escaping () -> Int) {}",
      ),
      Example("@available↓ (*, deprecated)"): Example("@available(*, deprecated)"),
      Example("@MyPropertyWrapper↓ (param: 2) let a = 1"): Example(
        "@MyPropertyWrapper(param: 2) let a = 1",
      ),
      Example("nonisolated↓ (unsafe) var _value: X?"): Example(
        "nonisolated(unsafe) var _value: X?",
      ),
      Example("@MyProperty↓ () let a = 1"): Example("@MyProperty() let a = 1"),
    ]
  }

  var options = SeverityOption<Self>(.error)
}

extension AttributeNameSpacingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AttributeNameSpacingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclModifierSyntax) {
      guard node.detail != nil, node.name.trailingTrivia.isNotEmpty else {
        return
      }

      violations.append(
        SyntaxViolation(
          position: node.name.endPosition,
          reason: "There must not be any space between access control modifier and scope",
          severity: configuration.severity,
          correction: .replaceTrailingTrivia(token: node.name, newTrivia: []),
        ),
      )
    }

    override func visitPost(_ node: AttributeSyntax) {
      // Check for trailing trivia after the '@' sign. Handles cases like `@ MainActor` / `@ escaping`.
      if node.atSign.trailingTrivia.isNotEmpty {
        violations.append(
          SyntaxViolation(
            position: node.atSign.endPosition,
            reason: "Attributes must not have trivia between `@` and the identifier",
            severity: configuration.severity,
            correction: .replaceTrailingTrivia(token: node.atSign, newTrivia: []),
          ),
        )
      }

      let hasTrailingTrivia = node.attributeName.trailingTrivia.isNotEmpty

      // Handles cases like `@MyPropertyWrapper (param: 2)`.
      if node.arguments != nil, hasTrailingTrivia {
        if let lastToken = node.attributeName.lastToken(viewMode: .sourceAccurate) {
          violations.append(
            SyntaxViolation(
              position: lastToken.endPosition,
              reason: "Attribute declarations with arguments must not have trailing trivia",
              severity: configuration.severity,
              correction: .replaceTrailingTrivia(token: lastToken, newTrivia: []),
            ),
          )
        }
      }

      if !hasTrailingTrivia, node.isEscaping {
        // Handles cases where escaping has the wrong spacing: `@escaping()`
        if let lastToken = node.attributeName.lastToken(viewMode: .sourceAccurate) {
          violations.append(
            SyntaxViolation(
              position: lastToken.endPosition,
              reason: "`@escaping` must have a trailing space before the associated type",
              severity: configuration.severity,
              correction: .replaceTrailingTrivia(token: lastToken, newTrivia: .space),
            ),
          )
        }
      }
    }
  }
}

extension AttributeSyntax {
  fileprivate var isEscaping: Bool {
    attributeNameText == "escaping"
  }
}
