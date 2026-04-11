import SwiftSyntax

struct AssignmentWrappingRule {
  static let id = "assignment_wrapping"
  static let name = "Assignment Wrapping"
  static let summary =
    "Keep the right-hand side on the same line as '=' when it fits within the line width"
  static let scope: Scope = .format
  static let isCorrectable = true

  static var nonTriggeringExamples: [Example] {
    [
      // Already on same line
      Example("let x = 1"),
      Example("var name = \"hello\""),
      Example(
        """
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("test")
            .path
        """
      ),
      // Assignment (not declaration)
      Example(
        """
        x = FileManager.default.temporaryDirectory
            .appendingPathComponent("test")
        """
      ),
      // Multiline RHS that legitimately needs wrapping (first line too long for default width)
      Example(
        """
        let x =
            veryLongFunctionName(parameterOne: valueOne, parameterTwo: valueTwo, parameterThree: valueThree, parameterFour: valueFour)
        """,
        configuration: ["max_width": 80]
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // Simple declaration with unnecessary wrap
      Example(
        """
        let x ↓=
            1
        """
      ),
      // Chained call with unnecessary wrap
      Example(
        """
        let tempDir ↓=
            FileManager.default.temporaryDirectory
            .appendingPathComponent("test")
            .path
        """
      ),
      // Over-indented chain
      Example(
        """
        let tempDir ↓=
                    FileManager.default.temporaryDirectory
                    .appendingPathComponent("test")
                    .path
        """
      ),
      // var declaration
      Example(
        """
        var result ↓=
            someFunction()
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("let x ↓=\n    1"): Example("let x = 1"),
      Example("var result ↓=\n    someFunction()"): Example("var result = someFunction()"),
      Example(
        """
        let tempDir ↓=
            FileManager.default.temporaryDirectory
            .appendingPathComponent("test")
            .path
        """
      ): Example(
        """
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test")
            .path
        """
      ),
      Example(
        """
        let tempDir ↓=
                    FileManager.default.temporaryDirectory
                    .appendingPathComponent("test")
                    .path
        """
      ): Example(
        """
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test")
            .path
        """
      ),
    ]
  }

  var options = AssignmentWrappingOptions()
}

extension AssignmentWrappingRule: FormatAwareRule {
  static var formatConfigKeys: Set<String> { ["max_width"] }
}

extension AssignmentWrappingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

// MARK: - Helpers

extension AssignmentWrappingRule {
  /// Calculate the column of a position (1-based from the location converter)
  fileprivate static func column(
    of position: AbsolutePosition,
    in converter: SourceLocationConverter,
  ) -> Int {
    converter.location(for: position).column
  }

  /// Get the length of the first line of an expression's source text (trimmed of leading whitespace)
  fileprivate static func firstLineLength(of expr: some SyntaxProtocol) -> Int {
    let text = expr.description.drop(while: { $0.isWhitespace || $0.isNewline })
    if let newlineIndex = text.firstIndex(where: \.isNewline) {
      return text[text.startIndex..<newlineIndex].count
    }
    return text.count
  }

  /// Check whether the RHS value starts on a new line after the equal sign
  fileprivate static func valueStartsOnNewLine(
    equalToken: TokenSyntax,
    value: some SyntaxProtocol,
    converter: SourceLocationConverter,
  ) -> Bool {
    guard let firstValueToken = value.firstToken(viewMode: .sourceAccurate) else {
      return false
    }
    let equalLine = converter.location(for: equalToken.positionAfterSkippingLeadingTrivia).line
    let valueLine = converter.location(
      for: firstValueToken.positionAfterSkippingLeadingTrivia
    ).line
    return valueLine > equalLine
  }

  /// Check whether moving the first line of the RHS onto the = line would fit within max width
  fileprivate static func fitsOnEqualLine(
    equalToken: TokenSyntax,
    value: some SyntaxProtocol,
    maxWidth: Int,
    converter: SourceLocationConverter,
  ) -> Bool {
    let equalCol = column(of: equalToken.positionAfterSkippingLeadingTrivia, in: converter)
    let rhsFirstLine = firstLineLength(of: value)
    // equalCol is 1-based column of '=', then '= ' adds 2 chars, then the RHS content
    return equalCol + 1 + rhsFirstLine <= maxWidth
  }
}

// MARK: - Visitor

extension AssignmentWrappingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InitializerClauseSyntax) {
      guard
        valueStartsOnNewLine(
          equalToken: node.equal,
          value: node.value,
          converter: locationConverter
        ),
        fitsOnEqualLine(
          equalToken: node.equal,
          value: node.value,
          maxWidth: configuration.maxWidth,
          converter: locationConverter
        )
      else { return }

      violations.append(node.equal.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard let assignment = node.operator.as(AssignmentExprSyntax.self) else { return }
      let equalToken = assignment.equal

      guard
        valueStartsOnNewLine(
          equalToken: equalToken,
          value: node.rightOperand,
          converter: locationConverter
        ),
        fitsOnEqualLine(
          equalToken: equalToken,
          value: node.rightOperand,
          maxWidth: configuration.maxWidth,
          converter: locationConverter
        )
      else { return }

      violations.append(equalToken.positionAfterSkippingLeadingTrivia)
    }
  }
}

// MARK: - Rewriter

extension AssignmentWrappingRule {
  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: InitializerClauseSyntax) -> InitializerClauseSyntax {
      guard !isDisabled(atStartPositionOf: node) else { return super.visit(node) }
      guard
        valueStartsOnNewLine(
          equalToken: node.equal,
          value: node.value,
          converter: locationConverter
        ),
        fitsOnEqualLine(
          equalToken: node.equal,
          value: node.value,
          maxWidth: configuration.maxWidth,
          converter: locationConverter
        )
      else { return super.visit(node) }

      numberOfCorrections += 1

      let statementStartCol = statementStartColumn(for: Syntax(node))
      let targetContinuationIndent = statementStartCol - 1 + configuration.indentWidth

      let reindentedValue = reindentValue(
        node.value,
        targetContinuationIndent: targetContinuationIndent
      )

      let newEqual = node.equal.with(\.trailingTrivia, .space)
      return super.visit(
        node
          .with(\.equal, newEqual)
          .with(\.value, reindentedValue)
      )
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
      guard let assignment = node.operator.as(AssignmentExprSyntax.self) else {
        return super.visit(node)
      }
      guard !isDisabled(atStartPositionOf: node) else { return super.visit(node) }

      let equalToken = assignment.equal

      guard
        valueStartsOnNewLine(
          equalToken: equalToken,
          value: node.rightOperand,
          converter: locationConverter
        ),
        fitsOnEqualLine(
          equalToken: equalToken,
          value: node.rightOperand,
          maxWidth: configuration.maxWidth,
          converter: locationConverter
        )
      else { return super.visit(node) }

      numberOfCorrections += 1

      let statementStartCol = statementStartColumn(for: Syntax(node))
      let targetContinuationIndent = statementStartCol - 1 + configuration.indentWidth

      let reindentedValue = reindentValue(
        node.rightOperand,
        targetContinuationIndent: targetContinuationIndent
      )

      let newAssignment = assignment.with(\.equal, equalToken.with(\.trailingTrivia, .space))

      return super.visit(
        node
          .with(\.operator, ExprSyntax(newAssignment))
          .with(\.rightOperand, reindentedValue)
      )
    }

    /// Find the column where the enclosing statement starts (for computing continuation indent)
    private func statementStartColumn(for node: Syntax) -> Int {
      var current: Syntax? = node
      while let parent = current?.parent {
        if parent.is(CodeBlockItemSyntax.self) || parent.is(MemberBlockItemSyntax.self) {
          break
        }
        current = parent
      }
      guard let stmt = current else {
        return column(of: node.positionAfterSkippingLeadingTrivia, in: locationConverter)
      }
      return column(of: stmt.positionAfterSkippingLeadingTrivia, in: locationConverter)
    }

    /// Reindent the value expression: remove newline before first token, adjust continuation lines
    private func reindentValue(
      _ value: ExprSyntax,
      targetContinuationIndent: Int,
    ) -> ExprSyntax {
      guard let firstToken = value.firstToken(viewMode: .sourceAccurate) else {
        return value
      }

      // Determine the original indentation of the first RHS line
      let originalFirstIndent =
        column(of: firstToken.positionAfterSkippingLeadingTrivia, in: locationConverter) - 1

      // Delta to apply to continuation lines
      let delta = originalFirstIndent - targetContinuationIndent

      let rewriter = IndentAdjuster(delta: delta, indentWidth: configuration.indentWidth)
      return rewriter.rewrite(value)
    }
  }
}

// MARK: - Trivia Rewriter

/// Strips leading whitespace from the first token and adjusts indentation of continuation lines
private final class IndentAdjuster: SyntaxRewriter {
  let delta: Int
  let indentWidth: Int
  private var isFirst = true

  init(delta: Int, indentWidth: Int) {
    self.delta = delta
    self.indentWidth = indentWidth
    super.init(viewMode: .sourceAccurate)
  }

  func rewrite(_ expr: ExprSyntax) -> ExprSyntax {
    isFirst = true
    return visit(expr)
  }

  override func visit(_ token: TokenSyntax) -> TokenSyntax {
    if isFirst {
      isFirst = false
      // Strip leading whitespace/newlines from first token (it moves to the = line)
      let stripped = token.leadingTrivia.pieces.drop(while: {
        switch $0 {
        case .newlines, .spaces, .tabs, .carriageReturns, .carriageReturnLineFeeds: true
        default: false
        }
      })
      return token.with(\.leadingTrivia, Trivia(pieces: Array(stripped)))
    }

    guard delta != 0, token.leadingTrivia.containsNewlines() else {
      return token
    }

    return token.with(\.leadingTrivia, adjustIndentation(of: token.leadingTrivia))
  }

  private func adjustIndentation(of trivia: Trivia) -> Trivia {
    var pieces = Array(trivia.pieces)
    for i in pieces.indices where i > 0 {
      let prev = pieces[i - 1]
      let isAfterNewline: Bool =
        switch prev {
        case .newlines, .carriageReturns, .carriageReturnLineFeeds: true
        default: false
        }
      guard isAfterNewline else { continue }

      switch pieces[i] {
      case .spaces(let count):
        pieces[i] = .spaces(max(0, count - delta))
      case .tabs(let count):
        let tabDelta = delta / max(1, indentWidth)
        pieces[i] = .tabs(max(0, count - tabDelta))
      default:
        break
      }
    }
    return Trivia(pieces: pieces)
  }
}
