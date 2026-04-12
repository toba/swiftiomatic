import Foundation
import SwiftiomaticSyntax

struct TrailingCommaRule {
  private static let _triggeringExamples: [Example] = [
    Example("let foo = [1, 2, 3↓,]"),
    Example("let foo = [1, 2, 3↓, ]"),
    Example("let foo = [1, 2, 3   ↓,]"),
    Example("let foo = [1: 2, 2: 3↓, ]"),
    Example("struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}"),
    Example("let foo = [1, 2, 3↓,] + [4, 5, 6↓,]"),
    Example("let example = [ 1,\n2↓,\n // 3,\n]"),
    Example("let foo = [\"אבג\", \"αβγ\", \"🇺🇸\"↓,]"),
    Example("class C {\n #if true\n func f() {\n let foo = [1, 2, 3↓,]\n }\n #endif\n}"),
    Example("foo([1: \"\\(error)\"↓,])"),
    Example("foo(bar: 1, baz: 2↓,)"),
    Example("DispatchQueue.main.async(execute: work↓,)"),
    Example("func foo(a: Int, b: Int↓,) {}"),
    Example("init(x: Int, y: Int↓,) {}"),
    Example("let x: Dictionary<String, Int↓,> = [:]"),
    Example("struct Foo<T, U↓,> {}"),
    Example("let x = (1, 2↓,)"),
    Example("let y: (Int, String↓,) = (1, \"a\")"),
    Example("let f = { (a: Int, b: Int↓,) in a + b }"),
  ]

  private static let _corrections: [Example: Example] = {
    let fixed = _triggeringExamples.map { example -> Example in
      let fixedString = example.code.replacingOccurrences(of: "↓,", with: "")
      return example.with(code: fixedString)
    }
    var result: [Example: Example] = [:]
    for (triggering, correction) in zip(_triggeringExamples, fixed) {
      result[triggering] = correction
    }
    return result
  }()

  static let id = "trailing_comma"
  static let name = "Trailing Comma"
  static let summary = "Trailing commas in collection literals and function calls should be avoided/enforced."
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let foo = [1, 2, 3]"),
      Example("let foo = []"),
      Example("let foo = [:]"),
      Example("let foo = [1: 2, 2: 3]"),
      Example("let foo = [Void]()"),
      Example("let example = [ 1,\n 2\n // 3,\n]"),
      Example("foo([1: \"\\(error)\"])"),
      Example("let foo = [Int]()"),
      Example("foo(bar: 1, baz: 2)"),
      Example("@available(iOS 16, *) func foo() {}"),
      Example("func foo(a: Int, b: Int) {}"),
      Example("let x: Dictionary<String, Int> = [:]"),
      Example("struct Foo<T, U> {}"),
      Example("let x = (1, 2)"),
      Example("let y: (Int, String) = (1, \"a\")"),
      Example("let f = { (a: Int, b: Int) in a + b }"),
    ]
  }

  static var triggeringExamples: [Example] {
    _triggeringExamples
  }

  static var corrections: [Example: Example] {
    _corrections
  }

  var options = TrailingCommaOptions()
}

extension TrailingCommaRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension TrailingCommaRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DictionaryElementListSyntax) {
      guard let lastElement = node.last else {
        return
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
      case (_, true), (nil, false):
        break
      }
    }

    override func visitPost(_ node: LabeledExprListSyntax) {
      guard node.supportsTrailingComma,
        let lastElement = node.last
      else { return }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
      case (_, true), (nil, false):
        break
      }
    }

    override func visitPost(_ node: FunctionParameterListSyntax) {
      guard let lastElement = node.last else { return }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
      case (_, true), (nil, false):
        break
      }
    }

    override func visitPost(_ node: ClosureParameterListSyntax) {
      guard let lastElement = node.last else { return }
      checkTrailingComma(lastElement.trailingComma, lastElement: lastElement, in: node)
    }

    override func visitPost(_ node: TupleTypeElementListSyntax) {
      guard node.count > 1, let lastElement = node.last else { return }
      checkTrailingComma(lastElement.trailingComma, lastElement: lastElement, in: node)
    }

    override func visitPost(_ node: GenericArgumentListSyntax) {
      guard let lastElement = node.last else { return }
      checkTrailingComma(lastElement.trailingComma, lastElement: lastElement, in: node)
    }

    override func visitPost(_ node: GenericParameterListSyntax) {
      guard let lastElement = node.last else { return }
      checkTrailingComma(lastElement.trailingComma, lastElement: lastElement, in: node)
    }

    private func checkTrailingComma(
      _ comma: TokenSyntax?, lastElement: some SyntaxProtocol, in node: some SyntaxProtocol
    ) {
      switch (comma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
      case (_, true), (nil, false):
        break
      }
    }

    override func visitPost(_ node: ArrayElementListSyntax) {
      guard let lastElement = node.last else {
        return
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        violations.append(violation(for: commaToken.positionAfterSkippingLeadingTrivia))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        violations.append(violation(for: lastElement.endPositionBeforeTrailingTrivia))
      case (_, true), (nil, false):
        break
      }
    }

    private func violation(for position: AbsolutePosition) -> SyntaxViolation {
      let reason =
        configuration.mandatoryComma
        ? "Multi-line collection literals should have trailing commas"
        : "Collection literals should not have trailing commas"
      return SyntaxViolation(position: position, reason: reason)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: DictionaryElementListSyntax) -> DictionaryElementListSyntax {
      guard let lastElement = node.last, let index = node.index(of: lastElement) else {
        return super.visit(node)
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        let newTrailingTrivia = (lastElement.value.trailingTrivia)
          .appending(trivia: commaToken.leadingTrivia)
          .appending(trivia: commaToken.trailingTrivia)
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(\.trailingComma, nil)
              .with(\.trailingTrivia, newTrailingTrivia),
          )
        return super.visit(newNode)
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(\.trailingTrivia, [])
              .with(\.trailingComma, .commaToken())
              .with(\.trailingTrivia, lastElement.trailingTrivia),
          )
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }

    override func visit(_ node: LabeledExprListSyntax) -> LabeledExprListSyntax {
      guard node.supportsTrailingComma,
        let lastElement = node.last,
        let index = node.index(of: lastElement)
      else {
        return super.visit(node)
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        let newTrailingTrivia = (lastElement.expression.trailingTrivia)
          .appending(trivia: commaToken.leadingTrivia)
          .appending(trivia: commaToken.trailingTrivia)
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(\.trailingComma, nil)
              .with(
                \.expression,
                lastElement.expression.with(\.trailingTrivia, newTrailingTrivia)),
          )
        return super.visit(newNode)
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(
                \.expression,
                lastElement.expression.with(\.trailingTrivia, []))
              .with(\.trailingComma, .commaToken())
              .with(\.trailingTrivia, lastElement.expression.trailingTrivia),
          )
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }

    override func visit(_ node: FunctionParameterListSyntax) -> FunctionParameterListSyntax {
      guard let lastElement = node.last, let index = node.index(of: lastElement) else {
        return super.visit(node)
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        var cleaned = lastElement.with(\.trailingComma, nil)
        let mergedTrivia = cleaned.trailingTrivia
          .appending(trivia: commaToken.leadingTrivia)
          .appending(trivia: commaToken.trailingTrivia)
        cleaned = cleaned.with(\.trailingTrivia, mergedTrivia)
        return super.visit(node.with(\.[index], cleaned))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(\.trailingTrivia, [])
              .with(\.trailingComma, .commaToken())
              .with(\.trailingTrivia, lastElement.trailingTrivia),
          )
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }

    override func visit(_ node: ClosureParameterListSyntax) -> ClosureParameterListSyntax {
      guard let lastElement = node.last, let index = node.index(of: lastElement) else {
        return super.visit(node)
      }
      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        var cleaned = lastElement.with(\.trailingComma, nil)
        let merged = cleaned.trailingTrivia
          .appending(trivia: commaToken.leadingTrivia)
          .appending(trivia: commaToken.trailingTrivia)
        cleaned = cleaned.with(\.trailingTrivia, merged)
        return super.visit(node.with(\.[index], cleaned))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode = node.with(
          \.[index],
          lastElement
            .with(\.trailingTrivia, [])
            .with(\.trailingComma, .commaToken())
            .with(\.trailingTrivia, lastElement.trailingTrivia))
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }

    override func visit(_ node: TupleTypeElementListSyntax) -> TupleTypeElementListSyntax {
      guard node.count > 1,
        let lastElement = node.last,
        let index = node.index(of: lastElement)
      else {
        return super.visit(node)
      }
      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        var cleaned = lastElement.with(\.trailingComma, nil)
        let merged = cleaned.trailingTrivia
          .appending(trivia: commaToken.leadingTrivia)
          .appending(trivia: commaToken.trailingTrivia)
        cleaned = cleaned.with(\.trailingTrivia, merged)
        return super.visit(node.with(\.[index], cleaned))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode = node.with(
          \.[index],
          lastElement
            .with(\.trailingTrivia, [])
            .with(\.trailingComma, .commaToken())
            .with(\.trailingTrivia, lastElement.trailingTrivia))
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }

    override func visit(_ node: GenericArgumentListSyntax) -> GenericArgumentListSyntax {
      guard let lastElement = node.last, let index = node.index(of: lastElement) else {
        return super.visit(node)
      }
      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        var cleaned = lastElement.with(\.trailingComma, nil)
        let merged = cleaned.trailingTrivia
          .appending(trivia: commaToken.leadingTrivia)
          .appending(trivia: commaToken.trailingTrivia)
        cleaned = cleaned.with(\.trailingTrivia, merged)
        return super.visit(node.with(\.[index], cleaned))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode = node.with(
          \.[index],
          lastElement
            .with(\.trailingTrivia, [])
            .with(\.trailingComma, .commaToken())
            .with(\.trailingTrivia, lastElement.trailingTrivia))
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }

    override func visit(_ node: GenericParameterListSyntax) -> GenericParameterListSyntax {
      guard let lastElement = node.last, let index = node.index(of: lastElement) else {
        return super.visit(node)
      }
      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        var cleaned = lastElement.with(\.trailingComma, nil)
        let merged = cleaned.trailingTrivia
          .appending(trivia: commaToken.leadingTrivia)
          .appending(trivia: commaToken.trailingTrivia)
        cleaned = cleaned.with(\.trailingTrivia, merged)
        return super.visit(node.with(\.[index], cleaned))
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode = node.with(
          \.[index],
          lastElement
            .with(\.trailingTrivia, [])
            .with(\.trailingComma, .commaToken())
            .with(\.trailingTrivia, lastElement.trailingTrivia))
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }

    override func visit(_ node: ArrayElementListSyntax) -> ArrayElementListSyntax {
      guard let lastElement = node.last, let index = node.index(of: lastElement) else {
        return super.visit(node)
      }

      switch (lastElement.trailingComma, configuration.mandatoryComma) {
      case (let commaToken?, false):
        numberOfCorrections += 1
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(\.trailingComma, nil)
              .with(
                \.trailingTrivia,
                (lastElement.expression.trailingTrivia)
                  .appending(trivia: commaToken.leadingTrivia)
                  .appending(trivia: commaToken.trailingTrivia),
              ),
          )
        return super.visit(newNode)
      case (nil, true) where !locationConverter.isSingleLine(node: node):
        numberOfCorrections += 1
        let newNode =
          node
          .with(
            \.[index],
            lastElement
              .with(
                \.expression,
                lastElement.expression.with(\.trailingTrivia, []),
              )
              .with(\.trailingComma, .commaToken())
              .with(\.trailingTrivia, lastElement.expression.trailingTrivia),
          )
        return super.visit(newNode)
      case (_, true), (nil, false):
        return super.visit(node)
      }
    }
  }
}

extension SourceLocationConverter {
  fileprivate func isSingleLine(node: some SyntaxProtocol) -> Bool {
    location(for: node.positionAfterSkippingLeadingTrivia).line
      == location(for: node.endPositionBeforeTrailingTrivia).line
  }
}

extension LabeledExprListSyntax {
  /// Whether this argument list is in a context that supports trailing commas (Swift 6.1+).
  /// Excludes built-in attributes like `@available`, `@backDeployed`.
  fileprivate var supportsTrailingComma: Bool {
    if parent?.is(FunctionCallExprSyntax.self) == true
      || parent?.is(MacroExpansionExprSyntax.self) == true
      || parent?.is(MacroExpansionDeclSyntax.self) == true
      || parent?.is(SubscriptCallExprSyntax.self) == true
    {
      return true
    }
    // Tuple expressions with >1 element support trailing commas (Swift 6.2+).
    // Single-element (x,) changes semantics, so only multi-element tuples.
    if parent?.is(TupleExprSyntax.self) == true, count > 1 {
      return true
    }
    // User-defined attributes (uppercase first letter) support trailing commas;
    // built-in attributes (@available, @objc, @_exported) do not.
    if let attr = parent?.as(AttributeSyntax.self) {
      let name = attr.attributeNameText
      guard let first = name.first else { return false }
      return first.isUppercase
    }
    return false
  }
}

extension Trivia {
  fileprivate func appending(trivia: Trivia) -> Trivia {
    var result = self
    for piece in trivia.pieces {
      result = result.appending(piece)
    }
    return result
  }
}
