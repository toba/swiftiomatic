//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension SyntaxProtocol {
  /// Returns the absolute position of the trivia piece at the given index in the receiver's leading
  /// trivia collection.
  ///
  /// If the trivia piece spans multiple characters, the value returned is the position of the first
  /// character.
  ///
  /// - Precondition: `index` is a valid index in the receiver's leading trivia collection.
  ///
  /// - Parameter index: The index of the trivia piece in the leading trivia whose position should
  ///   be returned.
  /// - Returns: The absolute position of the trivia piece.
  func position(ofLeadingTriviaAt index: Trivia.Index) -> AbsolutePosition {
    guard leadingTrivia.indices.contains(index) else {
      preconditionFailure("Index was out of bounds in the node's leading trivia.")
    }

    var offset = SourceLength.zero
    for currentIndex in leadingTrivia.startIndex..<index {
      offset += leadingTrivia[currentIndex].sourceLength
    }
    return self.position + offset
  }

  /// Returns the absolute position of the trivia piece at the given index in the receiver's
  /// trailing trivia collection.
  ///
  /// If the trivia piece spans multiple characters, the value returned is the position of the first
  /// character.
  ///
  /// - Precondition: `index` is a valid index in the receiver's trailing trivia collection.
  ///
  /// - Parameter index: The index of the trivia piece in the trailing trivia whose position should
  ///   be returned.
  /// - Returns: The absolute position of the trivia piece.
  func position(ofTrailingTriviaAt index: Trivia.Index) -> AbsolutePosition {
    guard trailingTrivia.indices.contains(index) else {
      preconditionFailure("Index was out of bounds in the node's trailing trivia.")
    }

    var offset = SourceLength.zero
    for currentIndex in trailingTrivia.startIndex..<index {
      offset += trailingTrivia[currentIndex].sourceLength
    }
    return self.endPositionBeforeTrailingTrivia + offset
  }

  /// Returns the source location of the trivia piece at the given index in the receiver's leading
  /// trivia collection.
  ///
  /// If the trivia piece spans multiple characters, the value returned is the location of the first
  /// character.
  ///
  /// - Precondition: `index` is a valid index in the receiver's leading trivia collection.
  ///
  /// - Parameters:
  ///   - index: The index of the trivia piece in the leading trivia whose location should be
  ///     returned.
  ///   - converter: The `SourceLocationConverter` that was previously initialized using the root
  ///     tree of this node.
  /// - Returns: The source location of the trivia piece.
  func startLocation(
    ofLeadingTriviaAt index: Trivia.Index,
    converter: SourceLocationConverter
  ) -> SourceLocation {
    return converter.location(for: position(ofLeadingTriviaAt: index))
  }

  /// Returns the source location of the trivia piece at the given index in the receiver's trailing
  /// trivia collection.
  ///
  /// If the trivia piece spans multiple characters, the value returned is the location of the first
  /// character.
  ///
  /// - Precondition: `index` is a valid index in the receiver's trailing trivia collection.
  ///
  /// - Parameters:
  ///   - index: The index of the trivia piece in the trailing trivia whose location should be
  ///     returned.
  ///   - converter: The `SourceLocationConverter` that was previously initialized using the root
  ///     tree of this node.
  /// - Returns: The source location of the trivia piece.
  func startLocation(
    ofTrailingTriviaAt index: Trivia.Index,
    converter: SourceLocationConverter
  ) -> SourceLocation {
    return converter.location(for: position(ofTrailingTriviaAt: index))
  }

  /// The collection of all contiguous trivia preceding this node; that is, the trailing trivia of
  /// the node before it and the leading trivia of the node itself.
  var allPrecedingTrivia: Trivia {
    var result: Trivia
    if let previousTrailingTrivia = previousToken(viewMode: .sourceAccurate)?.trailingTrivia {
      result = previousTrailingTrivia
    } else {
      result = Trivia()
    }
    result += leadingTrivia
    return result
  }

  /// The collection of all contiguous trivia following this node; that is, the trailing trivia of
  /// the node and the leading trivia of the node after it.
  var allFollowingTrivia: Trivia {
    var result = trailingTrivia
    if let nextLeadingTrivia = nextToken(viewMode: .sourceAccurate)?.leadingTrivia {
      result += nextLeadingTrivia
    }
    return result
  }

  /// Indicates whether the node has any preceding line comments.
  ///
  /// Due to the way trivia is parsed, a preceding comment might be in either the leading trivia of
  /// the node or the trailing trivia of the previous token.
  var hasPrecedingLineComment: Bool {
    if let previousTrailingTrivia = previousToken(viewMode: .sourceAccurate)?.trailingTrivia,
      previousTrailingTrivia.hasLineComment
    {
      return true
    }
    return leadingTrivia.hasLineComment
  }

  /// Indicates whether the node has any preceding comments of any kind.
  ///
  /// Due to the way trivia is parsed, a preceding comment might be in either the leading trivia of
  /// the node or the trailing trivia of the previous token.
  var hasAnyPrecedingComment: Bool {
    if let previousTrailingTrivia = previousToken(viewMode: .sourceAccurate)?.trailingTrivia,
      previousTrailingTrivia.hasAnyComments
    {
      return true
    }
    return leadingTrivia.hasAnyComments
  }

  /// Indicates whether the node has any function ancestor marked with `@Test` attribute.
  var hasTestAncestor: Bool {
    var parent = self.parent
    while let existingParent = parent {
      if let functionDecl = existingParent.as(FunctionDeclSyntax.self),
        functionDecl.hasAttribute("Test", inModule: "Testing")
      {
        return true
      }
      parent = existingParent.parent
    }
    return false
  }
}

extension SyntaxCollection {
  /// The first element in the syntax collection if it is the *only* element, or nil otherwise.
  var firstAndOnly: Element? {
    var iterator = makeIterator()
    guard let first = iterator.next() else { return nil }
    guard iterator.next() == nil else { return nil }
    return first
  }
}

// MARK: - Body Wrapping Helpers

extension CodeBlockSyntax {
  /// Whether this code block's content needs to be wrapped onto new lines.
  /// Returns `true` if the body is non-empty and the first statement or closing
  /// brace is on the same line as the opening brace.
  var bodyNeedsWrapping: Bool {
    guard let firstStmt = statements.first else { return false }
    let firstOnNewLine = firstStmt.leadingTrivia.containsNewlines
    let closingOnNewLine = rightBrace.leadingTrivia.containsNewlines
    return !firstOnNewLine || !closingOnNewLine
  }

  /// Returns a copy with the body content wrapped onto new lines.
  ///
  /// - Parameter baseIndent: The indentation string of the enclosing declaration.
  ///   The body content is indented by `baseIndent + "    "` and the closing brace
  ///   is placed at `baseIndent`.
  func wrappingBody(baseIndent: String) -> CodeBlockSyntax {
    var result = self
    let bodyIndent = baseIndent + "    "

    let firstOnNewLine = statements.first?.leadingTrivia.containsNewlines ?? true
    let closingOnNewLine = rightBrace.leadingTrivia.containsNewlines

    if !firstOnNewLine {
      // Strip trailing spaces from leftBrace (keep comments)
      result.leftBrace = leftBrace.with(
        \.trailingTrivia, leftBrace.trailingTrivia.trimmingTrailingWhitespace)

      // Set first statement leading trivia to newline + body indent
      var items = Array(result.statements)
      items[0].leadingTrivia = .newline + Trivia(stringLiteral: bodyIndent)
      result.statements = CodeBlockItemListSyntax(items)
    }

    if !closingOnNewLine {
      // Strip trailing whitespace from last statement
      var items = Array(result.statements)
      let lastIdx = items.count - 1
      items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia.trimmingTrailingWhitespace
      result.statements = CodeBlockItemListSyntax(items)

      // Set rightBrace leading trivia to newline + base indent
      result.rightBrace = result.rightBrace.with(
        \.leadingTrivia, .newline + Trivia(stringLiteral: baseIndent))
    }

    return result
  }
}

extension Trivia {
  /// Extracts the indentation string (spaces/tabs) after the last newline.
  var indentation: String {
    var indent = ""
    var foundNewline = false
    for piece in pieces.reversed() {
      if foundNewline { break }
      switch piece {
      case .spaces(let n):
        indent = String(repeating: " ", count: n) + indent
      case .tabs(let n):
        indent = String(repeating: "\t", count: n) + indent
      case .newlines, .carriageReturns, .carriageReturnLineFeeds:
        foundNewline = true
      default:
        indent = ""
      }
    }
    return indent
  }

  /// Returns a copy with trailing spaces and tabs removed.
  var trimmingTrailingWhitespace: Trivia {
    var pieces = Array(self.pieces)
    while let last = pieces.last {
      if case .spaces = last { pieces.removeLast() }
      else if case .tabs = last { pieces.removeLast() }
      else { break }
    }
    return Trivia(pieces: pieces)
  }
}

// MARK: - Switch Case Element Helpers

extension SwitchCaseListSyntax.Element {
  /// Returns a copy with an extra newline prepended to the leading trivia.
  func prependingNewline() -> SwitchCaseListSyntax.Element {
    switch self {
    case .switchCase(var switchCase):
      switchCase.leadingTrivia = .newline + switchCase.leadingTrivia
      return .switchCase(switchCase)
    case .ifConfigDecl(var ifConfig):
      ifConfig.leadingTrivia = .newline + ifConfig.leadingTrivia
      return .ifConfigDecl(ifConfig)
    }
  }

  /// Returns a copy with multi-newlines collapsed to single newlines in leading trivia.
  func removingBlankLines() -> SwitchCaseListSyntax.Element {
    switch self {
    case .switchCase(var switchCase):
      switchCase.leadingTrivia = switchCase.leadingTrivia.reducingToSingleNewlines
      return .switchCase(switchCase)
    case .ifConfigDecl(var ifConfig):
      ifConfig.leadingTrivia = ifConfig.leadingTrivia.reducingToSingleNewlines
      return .ifConfigDecl(ifConfig)
    }
  }

}
