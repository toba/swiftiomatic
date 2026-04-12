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
      Example(  // local Void type — skip all normalization
        """
        typealias Void = MyCustomType
        let abc: () -> () = {}
        """
      ),
      // use_void: false — prefer () over Void
      Example("let abc: () -> () = {}", configuration: ["use_void": false]),
      Example("func foo(completion: () -> ())", configuration: ["use_void": false]),
      Example("typealias Completion = ()", configuration: ["use_void": false]),
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
      // use_void: false — Void in return type is violation
      Example("let abc: () -> ↓Void = {}", configuration: ["use_void": false]),
      Example("func foo(completion: () -> ↓Void)", configuration: ["use_void": false]),
      Example("typealias Completion = ↓Void", configuration: ["use_void": false]),
      // (Void) param is always wrong regardless of option
      Example(
        "let callback: (↓Void) -> () = {}",
        configuration: ["use_void": false],
      ),
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
      // use_void: false
      Example("let abc: () -> ↓Void = {}", configuration: ["use_void": false]):
        Example("let abc: () -> () = {}"),
      Example("func foo(completion: () -> ↓Void)", configuration: ["use_void": false]):
        Example("func foo(completion: () -> ())"),
      Example("typealias Completion = ↓Void", configuration: ["use_void": false]):
        Example("typealias Completion = ()"),
    ]
  }

  var options = VoidReturnOptions()
}

extension VoidReturnRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension VoidReturnRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var hasLocalVoid = false

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
      // Check for local Void type declaration — skip all violations if found
      for item in node.statements {
        if let typeAlias = item.item.as(TypeAliasDeclSyntax.self),
          typeAlias.name.text == "Void"
        {
          hasLocalVoid = true
          return .skipChildren
        }
        if let structDecl = item.item.as(StructDeclSyntax.self),
          structDecl.name.text == "Void"
        {
          hasLocalVoid = true
          return .skipChildren
        }
        if let classDecl = item.item.as(ClassDeclSyntax.self),
          classDecl.name.text == "Void"
        {
          hasLocalVoid = true
          return .skipChildren
        }
        if let enumDecl = item.item.as(EnumDeclSyntax.self),
          enumDecl.name.text == "Void"
        {
          hasLocalVoid = true
          return .skipChildren
        }
      }
      return .visitChildren
    }

    override func visitPost(_ node: ReturnClauseSyntax) {
      guard !hasLocalVoid else { return }
      if configuration.useVoid {
        // () or (Void) → Void
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
      } else {
        // Void → ()
        guard let idType = node.type.as(IdentifierTypeSyntax.self),
          idType.name.text == "Void"
        else {
          // Also handle (Void) → ()
          guard let tupleType = node.type.as(TupleTypeSyntax.self),
            tupleType.elements.onlyElement?.type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
          else { return }

          violations.append(
            at: node.type.positionAfterSkippingLeadingTrivia,
            correction: .init(
              start: node.type.positionAfterSkippingLeadingTrivia,
              end: node.type.endPositionBeforeTrailingTrivia,
              replacement: "()",
            ),
          )
          return
        }

        violations.append(
          at: node.type.positionAfterSkippingLeadingTrivia,
          correction: .init(
            start: node.type.positionAfterSkippingLeadingTrivia,
            end: node.type.endPositionBeforeTrailingTrivia,
            replacement: "()",
          ),
        )
      }
    }

    override func visitPost(_ node: FunctionTypeSyntax) {
      guard !hasLocalVoid else { return }
      // (Void) → () is always a violation regardless of use_void option
      guard let singleParam = node.parameters.onlyElement,
        singleParam.type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
      else { return }

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
      guard !hasLocalVoid else { return }
      if configuration.useVoid {
        // () or (Void) → Void
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
      } else {
        // Void → ()
        if let idType = node.initializer.value.as(IdentifierTypeSyntax.self),
          idType.name.text == "Void"
        {
          violations.append(
            at: idType.positionAfterSkippingLeadingTrivia,
            correction: .init(
              start: idType.positionAfterSkippingLeadingTrivia,
              end: idType.endPositionBeforeTrailingTrivia,
              replacement: "()",
            ),
          )
        } else if let tupleType = node.initializer.value.as(TupleTypeSyntax.self),
          tupleType.elements.onlyElement?.type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
        {
          // (Void) → ()
          violations.append(
            at: tupleType.positionAfterSkippingLeadingTrivia,
            correction: .init(
              start: tupleType.positionAfterSkippingLeadingTrivia,
              end: tupleType.endPositionBeforeTrailingTrivia,
              replacement: "()",
            ),
          )
        }
      }
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
