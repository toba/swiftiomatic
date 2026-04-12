import SwiftiomaticSyntax

struct VoidReturnRule {
  static let id = "void_return"
  static let name = "Void Return"
  static let summary = "Prefer `-> Void` over `-> ()`, and `()` over `(Void)` in parameters"
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let abc: () -> Void = {}"),
      Example("let abc: () -> (VoidVoid) = {}"),
      Example("func foo(completion: () -> Void)"),
      Example("let foo: (ConfigurationTests) -> () throws -> Void"),
      Example("let foo: (ConfigurationTests) ->   () throws -> Void"),
      Example("let foo: (ConfigurationTests) ->() throws -> Void"),
      Example("let foo: (ConfigurationTests) -> () -> Void"),
      Example("let foo: () -> () async -> Void"),
      Example("let foo: () -> () async throws -> Void"),
      Example("let foo: () -> () async -> Void"),
      Example("func foo() -> () async throws -> Void {}"),
      Example("func foo() async throws -> () async -> Void { return {} }"),
      Example("func foo() -> () async -> Int { 1 }"),
      Example("typealias Completion = Void"),
      Example("let callback: () -> Void = {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let abc: () -> ↓() = {}"),
      Example("let abc: () -> ↓(Void) = {}"),
      Example("let abc: () -> ↓(   Void ) = {}"),
      Example("func foo(completion: () -> ↓())"),
      Example("func foo(completion: () -> ↓(   ))"),
      Example("func foo(completion: () -> ↓(Void))"),
      Example("let foo: (ConfigurationTests) -> () throws -> ↓()"),
      Example("func foo() async -> ↓()"),
      Example("func foo() async throws -> ↓()"),
      Example("let callback: (↓Void) -> Void = {}"),
      Example("typealias Completion = ↓()"),
      Example("typealias Completion = ↓(Void)"),
      Example("typealias Completion = ↓(   Void )"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("let abc: () -> ↓() = {}"): Example("let abc: () -> Void = {}"),
      Example("let abc: () -> ↓(Void) = {}"): Example("let abc: () -> Void = {}"),
      Example("let abc: () -> ↓(   Void ) = {}"): Example("let abc: () -> Void = {}"),
      Example("func foo(completion: () -> ↓())"): Example("func foo(completion: () -> Void)"),
      Example("func foo(completion: () -> ↓(   ))"): Example(
        "func foo(completion: () -> Void)",
      ),
      Example("func foo(completion: () -> ↓(Void))"): Example(
        "func foo(completion: () -> Void)",
      ),
      Example("let foo: (ConfigurationTests) -> () throws -> ↓()"):
        Example("let foo: (ConfigurationTests) -> () throws -> Void"),
      Example("func foo() async throws -> ↓()"): Example("func foo() async throws -> Void"),
      Example("let callback: (↓Void) -> Void = {}"): Example(
        "let callback: () -> Void = {}",
      ),
      Example("typealias Completion = ↓()"): Example("typealias Completion = Void"),
      Example("typealias Completion = ↓(Void)"): Example("typealias Completion = Void"),
      Example("typealias Completion = ↓(   Void )"): Example(
        "typealias Completion = Void",
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension VoidReturnRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension VoidReturnRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ReturnClauseSyntax) {
      guard let tupleType = node.type.as(TupleTypeSyntax.self),
        tupleType.isVoidEquivalent
      else { return }

      violations.append(
        at: node.type.positionAfterSkippingLeadingTrivia,
        correction: .init(
          start: node.type.positionAfterSkippingLeadingTrivia,
          end: node.type.endPositionBeforeTrailingTrivia,
          replacement: "Void",
        ),
      )
    }

    override func visitPost(_ node: FunctionTypeSyntax) {
      guard let singleParam = node.parameters.onlyElement,
        singleParam.type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
      else { return }

      // Replace content between parens with nothing: (Void) → ()
      violations.append(
        at: singleParam.type.positionAfterSkippingLeadingTrivia,
        correction: .init(
          start: node.leftParen.endPositionBeforeTrailingTrivia,
          end: node.rightParen.positionAfterSkippingLeadingTrivia,
          replacement: "",
        ),
      )
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      guard let tupleType = node.initializer.value.as(TupleTypeSyntax.self),
        tupleType.isVoidEquivalent
      else { return }

      violations.append(
        at: tupleType.positionAfterSkippingLeadingTrivia,
        correction: .init(
          start: tupleType.positionAfterSkippingLeadingTrivia,
          end: tupleType.endPositionBeforeTrailingTrivia,
          replacement: "Void",
        ),
      )
    }
  }
}

extension TupleTypeSyntax {
  /// Whether this tuple type is `()` or `(Void)` — both equivalent to `Void`
  fileprivate var isVoidEquivalent: Bool {
    elements.isEmpty
      || elements.onlyElement?.type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
  }
}
