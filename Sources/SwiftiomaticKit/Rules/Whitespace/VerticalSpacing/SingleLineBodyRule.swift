import SwiftSyntax

struct SingleLineBodyRule {
  static let id = "single_line_body"
  static let name = "Single Line Body"
  static let summary =
    "Single-statement bodies should be written on one line when they fit within the max width"
  static let scope: Scope = .format
  static let isOptIn = true
  static let isCorrectable = true

  static var nonTriggeringExamples: [Example] {
    [
      // Already single-line
      Example("guard let x = y else { return }"),
      Example("var count: Int { items.count }"),
      Example("func greet() -> String { \"Hello\" }"),
      Example("names.map { $0.uppercased() }"),
      // Multi-statement — not eligible
      Example(
        """
        func foo() {
            let x = compute()
            return x
        }
        """,
      ),
      // Comment in body — preserve
      Example(
        """
        guard let x = y else {
            // important reason
            return
        }
        """,
      ),
      // Empty body — not eligible
      Example("func foo() {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        guard let x = y else ↓{
            return
        }
        """,
      ),
      Example(
        """
        var count: Int ↓{
            items.count
        }
        """,
      ),
      Example(
        """
        func greeting() -> String ↓{
            "Hello"
        }
        """,
      ),
      Example(
        """
        names.map ↓{
            $0.uppercased()
        }
        """,
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        guard let x = y else ↓{
            return
        }
        """,
      ): Example(
        """
        guard let x = y else { return }
        """,
      ),
      Example(
        """
        var count: Int ↓{
            items.count
        }
        """,
      ): Example(
        """
        var count: Int { items.count }
        """,
      ),
      Example(
        """
        func greeting() -> String ↓{
            "Hello"
        }
        """,
      ): Example(
        """
        func greeting() -> String { "Hello" }
        """,
      ),
      Example(
        """
        names.map ↓{
            $0.uppercased()
        }
        """,
      ): Example(
        """
        names.map { $0.uppercased() }
        """,
      ),
    ]
  }

  var options = SingleLineBodyOptions()
}

// MARK: - FormatAwareRule

extension SingleLineBodyRule: FormatAwareRule {
  static var formatConfigKeys: Set<String> { ["max_width"] }
}

// MARK: - SwiftSyntaxRule

extension SingleLineBodyRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

// MARK: - Helpers

/// Compute the visual column width of leading trivia, accounting for tabs
private func visualColumn(of trivia: Trivia, tabWidth: Int) -> Int {
  var column = 0
  for piece in trivia.reversed() {
    switch piece {
    case .spaces(let count):
      column += count
    case .tabs(let count):
      column += count * tabWidth
    case .newlines, .carriageReturns, .carriageReturnLineFeeds:
      return column // stop at the last newline — we only want the indent after it
    default:
      break
    }
  }
  return column
}

/// Check whether the body contains any comments in its trivia
private func bodyContainsComments(_ statements: CodeBlockItemListSyntax) -> Bool {
  for item in statements {
    if item.leadingTrivia.containsComments || item.trailingTrivia.containsComments {
      return true
    }
    // Check the item's children for embedded comments
    for token in item.tokens(viewMode: .sourceAccurate) {
      if token.leadingTrivia.containsComments || token.trailingTrivia.containsComments {
        return true
      }
    }
  }
  return false
}

/// Check if a braced block is already on a single line
private func isAlreadySingleLine(
  leftBrace: TokenSyntax, rightBrace: TokenSyntax,
  locationConverter: SourceLocationConverter,
) -> Bool {
  let leftLine = locationConverter.location(for: leftBrace.positionAfterSkippingLeadingTrivia).line
  let rightLine = locationConverter.location(for: rightBrace.positionAfterSkippingLeadingTrivia).line
  return leftLine == rightLine
}

/// Compute the single-line text for a node by stripping internal newlines
private func flattenedLength(of node: some SyntaxProtocol) -> Int {
  // Build the single-line form: collapse all internal whitespace runs that contain newlines
  // into a single space
  var result = ""
  for token in node.tokens(viewMode: .sourceAccurate) {
    // Leading trivia: collapse newline-containing whitespace to single space
    let leading = collapseTrivia(token.leadingTrivia)
    result += leading
    result += token.text
    let trailing = collapseTrivia(token.trailingTrivia)
    result += trailing
  }
  return result.count
}

/// Collapse trivia that contains newlines into a single space; preserve non-newline trivia
private func collapseTrivia(_ trivia: Trivia) -> String {
  var hasNewline = false
  var preserved = ""
  for piece in trivia {
    switch piece {
    case .newlines, .carriageReturns, .carriageReturnLineFeeds:
      hasNewline = true
    case .spaces(let n):
      if !hasNewline { preserved += String(repeating: " ", count: n) }
    case .tabs(let n):
      if !hasNewline { preserved += String(repeating: "\t", count: n) }
    default:
      preserved += Trivia(pieces: [piece]).description
    }
  }
  return hasNewline ? " " : preserved
}

/// Find the start of the enclosing line for a braced block, walking up to the parent declaration
private func enclosingLineStart(
  of node: some SyntaxProtocol,
  locationConverter: SourceLocationConverter,
  tabWidth: Int,
) -> Int {
  // Walk up to find the outermost declaration on this line
  var current: Syntax = Syntax(node)
  while let parent = current.parent {
    // Stop at code block items, member list items, or source file — these are statement boundaries
    if parent.is(CodeBlockItemSyntax.self) || parent.is(MemberBlockItemSyntax.self)
      || parent.is(SourceFileSyntax.self)
    {
      break
    }
    current = parent
  }
  return visualColumn(
    of: current.leadingTrivia, tabWidth: tabWidth,
  )
}

// MARK: - Visitor

extension SingleLineBodyRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    // Tab width for visual column calculation (default 4)
    private let tabWidth = 4

    // MARK: CodeBlockSyntax — functions, guard, if, for, while, do, defer, catch

    override func visitPost(_ node: CodeBlockSyntax) {
      guard node.statements.count == 1,
        !isAlreadySingleLine(
          leftBrace: node.leftBrace, rightBrace: node.rightBrace,
          locationConverter: locationConverter,
        ),
        !bodyContainsComments(node.statements),
        !node.leftBrace.trailingTrivia.containsComments,
        !node.rightBrace.leadingTrivia.containsComments
      else { return }

      // Measure from the enclosing declaration
      let startCol = enclosingLineStart(
        of: node, locationConverter: locationConverter, tabWidth: tabWidth,
      )
      guard let parent = node.parent else { return }
      let lineLength = startCol + flattenedLength(of: parent)
      guard lineLength <= configuration.maxWidth else { return }

      violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
    }

    // MARK: ClosureExprSyntax — closures

    override func visitPost(_ node: ClosureExprSyntax) {
      guard node.statements.count == 1,
        node.signature == nil || !node.signature!.description.contains("\n"),
        !isAlreadySingleLine(
          leftBrace: node.leftBrace, rightBrace: node.rightBrace,
          locationConverter: locationConverter,
        ),
        !bodyContainsComments(node.statements),
        !node.leftBrace.trailingTrivia.containsComments,
        !node.rightBrace.leadingTrivia.containsComments
      else { return }

      // For closures, measure from the enclosing expression/statement
      let startCol = enclosingLineStart(
        of: node, locationConverter: locationConverter, tabWidth: tabWidth,
      )
      guard let parent = node.parent else { return }
      let lineLength = startCol + flattenedLength(of: parent)
      guard lineLength <= configuration.maxWidth else { return }

      violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
    }

    // MARK: AccessorBlockSyntax — getter-only computed properties

    override func visitPost(_ node: AccessorBlockSyntax) {
      guard case .getter(let items) = node.accessors,
        items.count == 1,
        !isAlreadySingleLine(
          leftBrace: node.leftBrace, rightBrace: node.rightBrace,
          locationConverter: locationConverter,
        ),
        !bodyContainsComments(items),
        !node.leftBrace.trailingTrivia.containsComments,
        !node.rightBrace.leadingTrivia.containsComments
      else { return }

      let startCol = enclosingLineStart(
        of: node, locationConverter: locationConverter, tabWidth: tabWidth,
      )
      guard let parent = node.parent else { return }
      let lineLength = startCol + flattenedLength(of: parent)
      guard lineLength <= configuration.maxWidth else { return }

      violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
    }

    // MARK: AccessorDeclSyntax — willSet, didSet, get, set

    override func visitPost(_ node: AccessorDeclSyntax) {
      guard let body = node.body,
        body.statements.count == 1,
        !isAlreadySingleLine(
          leftBrace: body.leftBrace, rightBrace: body.rightBrace,
          locationConverter: locationConverter,
        ),
        !bodyContainsComments(body.statements),
        !body.leftBrace.trailingTrivia.containsComments,
        !body.rightBrace.leadingTrivia.containsComments
      else { return }

      let startCol = enclosingLineStart(
        of: node, locationConverter: locationConverter, tabWidth: tabWidth,
      )
      let lineLength = startCol + flattenedLength(of: Syntax(node))
      guard lineLength <= configuration.maxWidth else { return }

      violations.append(body.leftBrace.positionAfterSkippingLeadingTrivia)
    }
  }
}

// MARK: - Rewriter

extension SingleLineBodyRule {
  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    private let tabWidth = 4

    // MARK: CodeBlockSyntax

    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
      guard node.statements.count == 1,
        !isAlreadySingleLine(
          leftBrace: node.leftBrace, rightBrace: node.rightBrace,
          locationConverter: locationConverter,
        ),
        !bodyContainsComments(node.statements),
        !node.leftBrace.trailingTrivia.containsComments,
        !node.rightBrace.leadingTrivia.containsComments,
        let parent = node.parent
      else {
        return super.visit(node)
      }

      let startCol = enclosingLineStart(
        of: node, locationConverter: locationConverter, tabWidth: tabWidth,
      )
      let lineLength = startCol + flattenedLength(of: parent)
      guard lineLength <= configuration.maxWidth else {
        return super.visit(node)
      }

      numberOfCorrections += 1
      return super.visit(collapseSingleLine(node))
    }

    // MARK: ClosureExprSyntax

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
      guard node.statements.count == 1,
        node.signature == nil || !node.signature!.description.contains("\n"),
        !isAlreadySingleLine(
          leftBrace: node.leftBrace, rightBrace: node.rightBrace,
          locationConverter: locationConverter,
        ),
        !bodyContainsComments(node.statements),
        !node.leftBrace.trailingTrivia.containsComments,
        !node.rightBrace.leadingTrivia.containsComments,
        let parent = node.parent
      else {
        return super.visit(node)
      }

      let startCol = enclosingLineStart(
        of: node, locationConverter: locationConverter, tabWidth: tabWidth,
      )
      let lineLength = startCol + flattenedLength(of: parent)
      guard lineLength <= configuration.maxWidth else {
        return super.visit(node)
      }

      numberOfCorrections += 1
      var collapsed = node
      collapsed.leftBrace = node.leftBrace.with(\.trailingTrivia, .space)
      if let first = node.statements.first {
        let stripped = first.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
        collapsed.statements = CodeBlockItemListSyntax([stripped])
      }
      collapsed.rightBrace = node.rightBrace
        .with(\.leadingTrivia, .space)
        .with(\.trailingTrivia, node.rightBrace.trailingTrivia.droppingLeadingWhitespace)
      return super.visit(collapsed)
    }

    // MARK: AccessorBlockSyntax

    override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
      guard case .getter(let items) = node.accessors,
        items.count == 1,
        !isAlreadySingleLine(
          leftBrace: node.leftBrace, rightBrace: node.rightBrace,
          locationConverter: locationConverter,
        ),
        !bodyContainsComments(items),
        !node.leftBrace.trailingTrivia.containsComments,
        !node.rightBrace.leadingTrivia.containsComments,
        let parent = node.parent
      else {
        return super.visit(node)
      }

      let startCol = enclosingLineStart(
        of: node, locationConverter: locationConverter, tabWidth: tabWidth,
      )
      let lineLength = startCol + flattenedLength(of: parent)
      guard lineLength <= configuration.maxWidth else {
        return super.visit(node)
      }

      numberOfCorrections += 1
      let first = items.first!
      let stripped = first.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
      let newItems = CodeBlockItemListSyntax([stripped])
      let newNode = node
        .with(\.leftBrace, node.leftBrace.with(\.trailingTrivia, .space))
        .with(\.accessors, .getter(newItems))
        .with(
          \.rightBrace,
          node.rightBrace
            .with(\.leadingTrivia, .space)
            .with(\.trailingTrivia, node.rightBrace.trailingTrivia.droppingLeadingWhitespace),
        )
      return super.visit(newNode)
    }

    // MARK: AccessorDeclSyntax — individual accessors

    override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
      guard let body = node.body,
        body.statements.count == 1,
        !isAlreadySingleLine(
          leftBrace: body.leftBrace, rightBrace: body.rightBrace,
          locationConverter: locationConverter,
        ),
        !bodyContainsComments(body.statements),
        !body.leftBrace.trailingTrivia.containsComments,
        !body.rightBrace.leadingTrivia.containsComments
      else {
        return super.visit(node)
      }

      let startCol = enclosingLineStart(
        of: node, locationConverter: locationConverter, tabWidth: tabWidth,
      )
      let lineLength = startCol + flattenedLength(of: Syntax(node))
      guard lineLength <= configuration.maxWidth else {
        return super.visit(node)
      }

      numberOfCorrections += 1
      let collapsedBody = collapseSingleLine(body)
      return super.visit(node.with(\.body, collapsedBody))
    }

    // MARK: - Shared collapse logic for CodeBlockSyntax

    private func collapseSingleLine(_ block: CodeBlockSyntax) -> CodeBlockSyntax {
      var newBlock = block
      newBlock.leftBrace = block.leftBrace.with(\.trailingTrivia, .space)
      if let first = block.statements.first {
        let stripped = first.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
        newBlock.statements = CodeBlockItemListSyntax([stripped])
      }
      newBlock.rightBrace = block.rightBrace
        .with(\.leadingTrivia, .space)
        .with(\.trailingTrivia, block.rightBrace.trailingTrivia.droppingLeadingWhitespace)
      return newBlock
    }
  }
}

// MARK: - Trivia helpers

extension Trivia {
  /// Drop leading whitespace (newlines, spaces, tabs) from the trivia,
  /// preserving any non-whitespace pieces that follow
  fileprivate var droppingLeadingWhitespace: Trivia {
    var pieces = Array(self)
    while let first = pieces.first {
      switch first {
      case .spaces, .tabs, .newlines, .carriageReturns, .carriageReturnLineFeeds:
        pieces.removeFirst()
      default:
        return Trivia(pieces: pieces)
      }
    }
    return Trivia(pieces: pieces)
  }
}
