import SwiftSyntax

struct LargeTupleRule {
    static let id = "large_tuple"
    static let name = "Large Tuple"
    static let summary = "Tuples shouldn't have too many members. Create a custom type instead."
    static var nonTriggeringExamples: [Example] {
        [
              Example("let foo: (Int, Int)"),
              Example("let foo: (start: Int, end: Int)"),
              Example("let foo: (Int, (Int, String))"),
              Example("func foo() -> (Int, Int)"),
              Example("func foo() -> (Int, Int) {}"),
              Example("func foo(bar: String) -> (Int, Int)"),
              Example("func foo(bar: String) -> (Int, Int) {}"),
              Example("func foo() throws -> (Int, Int)"),
              Example("func foo() throws -> (Int, Int) {}"),
              Example("let foo: (Int, Int, Int) -> Void"),
              Example("let foo: (Int, Int, Int) throws -> Void"),
              Example("func foo(bar: (Int, String, Float) -> Void)"),
              Example("func foo(bar: (Int, String, Float) throws -> Void)"),
              Example(
                "var completionHandler: ((_ data: Data?, _ resp: URLResponse?, _ e: NSError?) -> Void)!",
              ),
              Example("func getDictionaryAndInt() -> (Dictionary<Int, String>, Int)?"),
              Example("func getGenericTypeAndInt() -> (Type<Int, String, Float>, Int)?"),
              Example("func foo() async -> (Int, Int)"),
              Example("func foo() async -> (Int, Int) {}"),
              Example("func foo(bar: String) async -> (Int, Int)"),
              Example("func foo(bar: String) async -> (Int, Int) {}"),
              Example("func foo() async throws -> (Int, Int)"),
              Example("func foo() async throws -> (Int, Int) {}"),
              Example("let foo: (Int, Int, Int) async -> Void"),
              Example("let foo: (Int, Int, Int) async throws -> Void"),
              Example("func foo(bar: (Int, String, Float) async -> Void)"),
              Example("func foo(bar: (Int, String, Float) async throws -> Void)"),
              Example("func getDictionaryAndInt() async -> (Dictionary<Int, String>, Int)?"),
              Example("func getGenericTypeAndInt() async -> (Type<Int, String, Float>, Int)?"),
              Example(
                "func foo() -> Regex<(Substring, foo: Substring, bar: Substring)>.Match? { nil }",
                configuration: ["ignore_regex": true],
              ),
              Example(
                "let regex: Regex<(Substring, Substring, Substring, Substring)>? = nil",
                configuration: ["ignore_regex": true],
              ),
              Example(
                "var regex: Regex<(Substring, Substring, Substring, Substring)?>.Match? { nil }",
                configuration: ["ignore_regex": true],
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("let foo: ↓(Int, Int, Int)"),
              Example("let foo: ↓(start: Int, end: Int, value: String)"),
              Example("let foo: (Int, ↓(Int, Int, Int))"),
              Example("func foo(bar: ↓(Int, Int, Int))"),
              Example("func foo() -> ↓(Int, Int, Int)"),
              Example("func foo() -> ↓(Int, Int, Int) {}"),
              Example("func foo(bar: String) -> ↓(Int, Int, Int)"),
              Example("func foo(bar: String) -> ↓(Int, Int, Int) {}"),
              Example("func foo() throws -> ↓(Int, Int, Int)"),
              Example("func foo() throws -> ↓(Int, Int, Int) {}"),
              Example("func foo() throws -> ↓(Int, ↓(String, String, String), Int) {}"),
              Example(
                "func getDictionaryAndInt() -> (Dictionary<Int, ↓(String, String, String)>, Int)?",
              ),
              Example("func foo(bar: ↓(Int, Int, Int)) async"),
              Example("func foo() async -> ↓(Int, Int, Int)"),
              Example("func foo() async -> ↓(Int, Int, Int) {}"),
              Example("func foo(bar: String) async -> ↓(Int, Int, Int)"),
              Example("func foo(bar: String) async -> ↓(Int, Int, Int) {}"),
              Example("func foo() async throws -> ↓(Int, Int, Int)"),
              Example(
                "func foo() async throws -> ↓(Int, Int, Int) {}",
                configuration: ["ignore_regex": false],
              ),
              Example("func foo() async throws -> ↓(Int, ↓(String, String, String), Int) {}"),
              Example(
                "func getDictionaryAndInt() async -> (Dictionary<Int, ↓(String, String, String)>, Int)?",
              ),
            ]
    }
  var options = LargeTupleOptions()

}

extension LargeTupleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LargeTupleRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TupleTypeSyntax) {
      if configuration.ignoreRegex, node.isInsideRegexType {
        return
      }

      let memberCount = node.elements.count
      for parameter in configuration.severityConfiguration.params
      where memberCount > parameter.value {
        violations.append(
          .init(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "Tuples should have at most \(configuration.severityConfiguration.warning) members",
            severity: parameter.severity,
          ),
        )
        return
      }
    }
  }
}

extension TupleTypeSyntax {
  fileprivate var isInsideRegexType: Bool {
    var current: Syntax? = Syntax(self)

    // Skip OptionalType wrapper if present (for Regex<(A, B)?>)
    if current?.parent?.is(OptionalTypeSyntax.self) == true {
      current = current?.parent
    }

    guard let genericArgument = current?.parent?.as(GenericArgumentSyntax.self),
      let genericArgumentList = genericArgument.parent?.as(GenericArgumentListSyntax.self),
      let genericArgumentClause = genericArgumentList.parent?
        .as(GenericArgumentClauseSyntax.self),
      let identifierType = genericArgumentClause.parent?.as(IdentifierTypeSyntax.self),
      identifierType.name.text == "Regex"
    else {
      return false
    }
    return true
  }
}
