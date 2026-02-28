import SwiftSyntax

extension Trivia {
  func containsNewlines() -> Bool {
    contains { piece in
      if case .newlines = piece {
        return true
      }
      return false
    }
  }

  var containsComments: Bool {
    isNotEmpty
      && contains { piece in
        !piece.isWhitespace && !piece.isNewline
      }
  }

  var isSingleSpace: Bool {
    self == .spaces(1)
  }

  var withFirstEmptyLineRemoved: Trivia {
    if let index = firstIndex(where: \.isNewline), index < endIndex {
      return Trivia(pieces: dropFirst(index + 1))
    }
    return self
  }

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

  var withoutTrailingIndentation: Trivia {
    Trivia(pieces: reversed().drop(while: \.isHorizontalWhitespace).reversed())
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
