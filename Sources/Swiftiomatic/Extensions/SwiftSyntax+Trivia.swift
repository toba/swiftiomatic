import SwiftSyntax

extension Trivia {
  /// Whether this trivia contains at least one newline piece
  func containsNewlines() -> Bool {
    contains { piece in
      if case .newlines = piece {
        return true
      }
      return false
    }
  }

  /// Whether this trivia contains comment pieces (line, block, or doc comments)
  var containsComments: Bool {
    isNotEmpty
      && contains { piece in
        !piece.isWhitespace && !piece.isNewline
      }
  }

  var isSingleSpace: Bool {
    self == .spaces(1)
  }

  /// A copy with the first newline piece and everything before it stripped
  var withFirstEmptyLineRemoved: Trivia {
    if let index = firstIndex(where: \.isNewline), index < endIndex {
      return Trivia(pieces: dropFirst(index + 1))
    }
    return self
  }

  /// A copy with the trailing empty line (and any following indentation) stripped
  var withTrailingEmptyLineRemoved: Trivia {
    if let index = pieces.lastIndex(where: \.isNewline), index < endIndex {
      if index == endIndex - 1 {
        return Trivia(pieces: dropLast(1))
      }
      if pieces.suffix(from: index + 1).allSatisfy(\.isHorizontalWhitespace) {
        return Trivia(pieces: prefix(upTo: index))
      }
    }
    return self
  }

  /// A copy with trailing horizontal whitespace (spaces/tabs) removed
  var withoutTrailingIndentation: Trivia {
    Trivia(pieces: reversed().drop(while: \.isHorizontalWhitespace).reversed())
  }

  /// Total number of newline characters across all newline-family pieces
  var newlineCount: Int {
    reduce(into: 0) { count, piece in
      switch piece {
      case .newlines(let n), .carriageReturns(let n), .carriageReturnLineFeeds(let n):
        count += n
      default: break
      }
    }
  }

  var isHorizontalWhitespaceOnly: Bool {
    isNotEmpty && allSatisfy(\.isHorizontalWhitespace)
  }

  var containsHorizontalWhitespace: Bool {
    contains(where: \.isHorizontalWhitespace)
  }
}

extension TriviaPiece {
  var isHorizontalWhitespace: Bool {
    switch self {
    case .spaces, .tabs:
      return true
    default:
      return false
    }
  }
}
