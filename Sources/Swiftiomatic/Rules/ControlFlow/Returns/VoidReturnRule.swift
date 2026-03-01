import SwiftSyntax
import SwiftSyntaxBuilder

struct VoidReturnRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = VoidReturnConfiguration()

  static let description = RuleDescription(
    identifier: "void_return",
    name: "Void Return",
    description: "Prefer `-> Void` over `-> ()`",
    nonTriggeringExamples: [
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
    ],
    triggeringExamples: [
      Example("let abc: () -> ↓() = {}"),
      Example("let abc: () -> ↓(Void) = {}"),
      Example("let abc: () -> ↓(   Void ) = {}"),
      Example("func foo(completion: () -> ↓())"),
      Example("func foo(completion: () -> ↓(   ))"),
      Example("func foo(completion: () -> ↓(Void))"),
      Example("let foo: (ConfigurationTests) -> () throws -> ↓()"),
      Example("func foo() async -> ↓()"),
      Example("func foo() async throws -> ↓()"),
    ],
    corrections: [
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
    ],
  )
}

extension VoidReturnRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension VoidReturnRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ReturnClauseSyntax) {
      if node.violates {
        violations.append(node.type.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ReturnClauseSyntax) -> ReturnClauseSyntax {
      if node.violates {
        numberOfCorrections += 1
        let node =
          node
          .with(\.type, TypeSyntax(IdentifierTypeSyntax(name: "Void")))
          .with(\.trailingTrivia, node.type.trailingTrivia)
        return super.visit(node)
      }
      return super.visit(node)
    }
  }
}

extension ReturnClauseSyntax {
  fileprivate var violates: Bool {
    if let type = type.as(TupleTypeSyntax.self) {
      let elements = type.elements
      return elements.isEmpty
        || elements.onlyElement?.type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
    }
    return false
  }
}
