import Foundation

/// Position-aware JSON5 scanner used by `Configuration.applyUpdateText` to
/// drive surgical edits on a configuration file. Captures top-level object
/// members, their value spans, trailing commas, and any nested object's
/// children — enough to insert or remove a key without disturbing adjacent
/// formatting or comments.
///
/// Design adapted from `croct-tech/json5-parser-js` — a token stream with
/// `peek/next/consume/expect/matches` and a small JSON5 lexicon (unquoted
/// identifier keys, single-quoted strings, hex/Infinity/NaN numbers,
/// trailing commas, `// ...` and `/* ... */` comments).
struct JSON5Scanner {
  enum Error: Swift.Error, CustomStringConvertible {
    case unexpectedEOF
    case expected(String, at: String.Index)
    case unexpected(Character, at: String.Index)
    case invalidValue(at: String.Index)

    var description: String {
      switch self {
      case .unexpectedEOF: "unexpected end of input"
      case .expected(let what, _): "expected \(what)"
      case .unexpected(let c, _): "unexpected character '\(c)'"
      case .invalidValue: "invalid value"
      }
    }
  }

  // MARK: - Token model

  enum TokenKind {
    case braceLeft, braceRight
    case bracketLeft, bracketRight
    case colon, comma
    case string         // "..." or '...'
    case identifier     // unquoted JSON5 key
    case scalar         // number / true / false / null / Infinity / NaN
    case lineComment    // `// ...`
    case blockComment   // `/* ... */`
    case whitespace     // horizontal/space/tab/etc.
    case newline        // \n or \r\n
    case eof
  }

  struct Token {
    var kind: TokenKind
    /// Range covering the token text in the source. For `eof`, both bounds
    /// equal `source.endIndex`.
    var range: Range<String.Index>
  }

  // MARK: - Output

  struct ObjectLayout {
    var openBrace: String.Index
    var closeBrace: String.Index
    var members: [Member]
  }

  struct Member {
    var key: String
    var keyRange: Range<String.Index>
    var valueRange: Range<String.Index>
    /// Single-character range covering the trailing `,`, if present.
    var trailingComma: Range<String.Index>?
    /// Range covering the whole member as a logical block, suitable for
    /// deletion: from the start of the line containing the key (whitespace
    /// before the key on that line is included) through one trailing `\n`
    /// after the value's trailing comma (or after the value, if no comma).
    var fullRange: Range<String.Index>
    /// Whitespace at the start of the line containing the key.
    var indent: Substring
    /// Populated when the member's value is a JSON object `{...}`.
    var nested: ObjectLayout?
  }

  // MARK: - Public entry

  /// Parses a single top-level JSON5 object.
  static func parseDocument(_ source: String) throws(Error) -> ObjectLayout {
    var scanner = JSON5Scanner(source: source)
    try scanner.lexer.advance()
    scanner.lexer.skipInsignificant()
    let layout = try scanner.parseObject()
    scanner.lexer.skipInsignificant()
    return layout
  }

  // MARK: - Internals

  let source: String
  var lexer: Lexer

  private init(source: String) {
    self.source = source
    self.lexer = Lexer(source: source)
  }

  // MARK: - Object / value parsers

  private mutating func parseObject() throws(Error) -> ObjectLayout {
    let openTok = try lexer.expect(.braceLeft)
    let openBrace = openTok.range.lowerBound
    try lexer.advance()
    lexer.skipInsignificant()

    var members: [Member] = []
    while !lexer.matches(.braceRight, .eof) {
      let memberStart = lexer.peek().range.lowerBound
      let memberLineStart = lineStart(of: memberStart)
      let indent = source[memberLineStart..<memberStart]

      let (keyName, keyRange) = try parseKey()
      lexer.skipInsignificant()
      _ = try lexer.consume(.colon)
      lexer.skipInsignificant()

      let valueStart = lexer.peek().range.lowerBound
      let nested = try parseValue()
      let valueEnd = lexer.peek().range.lowerBound

      // Skip horizontal whitespace and inline line comments looking for `,`.
      lexer.skipHorizontalAndLineComments()
      var trailingComma: Range<String.Index>? = nil
      if lexer.matches(.comma) {
        trailingComma = lexer.peek().range
        try lexer.advance()
      }

      // Extend full range to one trailing newline (if present) following
      // any horizontal trivia on the member's line.
      lexer.skipHorizontalAndLineComments()
      var endOfMember = lexer.peek().range.lowerBound
      if lexer.matches(.newline) {
        endOfMember = lexer.peek().range.upperBound
        try lexer.advance()
      }

      members.append(
        Member(
          key: keyName,
          keyRange: keyRange,
          valueRange: valueStart..<valueEnd,
          trailingComma: trailingComma,
          fullRange: memberLineStart..<endOfMember,
          indent: indent,
          nested: nested
        )
      )

      lexer.skipInsignificant()
    }

    let closeTok = try lexer.expect(.braceRight)
    let closeBrace = closeTok.range.lowerBound
    try lexer.advance()
    return ObjectLayout(openBrace: openBrace, closeBrace: closeBrace, members: members)
  }

  /// Parse a member key — either a quoted string or a JSON5 unquoted
  /// identifier. Returns the decoded key name and the source range covering
  /// the key token (including any surrounding quotes).
  private mutating func parseKey() throws(Error) -> (String, Range<String.Index>) {
    let tok = lexer.peek()
    switch tok.kind {
    case .string:
      try lexer.advance()
      return (decodeStringLiteral(at: tok.range), tok.range)
    case .identifier:
      try lexer.advance()
      return (String(source[tok.range]), tok.range)
    default:
      throw Error.expected("object key", at: tok.range.lowerBound)
    }
  }

  /// Advances past one JSON5 value. Returns a nested object layout if the
  /// value is `{...}`, otherwise `nil`.
  private mutating func parseValue() throws(Error) -> ObjectLayout? {
    let tok = lexer.peek()
    switch tok.kind {
    case .braceLeft:
      return try parseObject()
    case .bracketLeft:
      try skipArray()
      return nil
    case .string, .scalar, .identifier:
      try lexer.advance()
      return nil
    default:
      throw Error.expected("value", at: tok.range.lowerBound)
    }
  }

  private mutating func skipArray() throws(Error) {
    _ = try lexer.consume(.bracketLeft)
    lexer.skipInsignificant()
    while !lexer.matches(.bracketRight, .eof) {
      _ = try parseValue()
      lexer.skipInsignificant()
      if lexer.matches(.comma) {
        try lexer.advance()
        lexer.skipInsignificant()
      }
    }
    _ = try lexer.consume(.bracketRight)
  }

  /// Decodes a `"..."` or `'...'` string literal. Handles common escapes;
  /// unsupported escapes pass through as their literal escaped character.
  private func decodeStringLiteral(at range: Range<String.Index>) -> String {
    guard range.lowerBound < range.upperBound else { return "" }
    let quote = source[range.lowerBound]
    let inside =
      source.index(after: range.lowerBound)..<source.index(before: range.upperBound)
    var out = ""
    var i = inside.lowerBound
    while i < inside.upperBound {
      let c = source[i]
      if c == "\\" {
        let next = source.index(after: i)
        if next < inside.upperBound {
          let e = source[next]
          switch e {
          case "n": out.append("\n")
          case "t": out.append("\t")
          case "r": out.append("\r")
          case "\\": out.append("\\")
          case "\"": out.append("\"")
          case "'": out.append("'")
          case "/": out.append("/")
          case "b": out.append("\u{08}")
          case "f": out.append("\u{0C}")
          // Line-continuation: `\` followed by line terminator → drop both.
          case "\n", "\r":
            i = source.index(after: next)
            if e == "\r", i < inside.upperBound, source[i] == "\n" {
              i = source.index(after: i)
            }
            continue
          default:
            out.append(e)
          }
          i = source.index(after: next)
          continue
        }
      }
      if c == quote { break }
      out.append(c)
      i = source.index(after: i)
    }
    return out
  }

  // MARK: - lineStart

  /// Walks back from `i` to the character just past the previous `\n`, or to
  /// `startIndex` if there is no preceding newline. The result points at the
  /// first column of the line containing `i`.
  private func lineStart(of i: String.Index) -> String.Index {
    var p = i
    while p > source.startIndex {
      let prev = source.index(before: p)
      if source[prev] == "\n" { return p }
      p = prev
    }
    return source.startIndex
  }
}

// MARK: - Lexer

extension JSON5Scanner {
  /// JSON5 lexer with explicit token stream. Matches the structure of
  /// `croct-tech/json5-parser-js` — an iterator with `peek/next/consume/
  /// expect/matches/skipInsignificant`. Tokens carry source ranges; all
  /// state advances are explicit so the scanner can attach token positions
  /// directly to surgical edits.
  struct Lexer {
    let source: String
    private var cursor: String.Index
    private var current: Token

    init(source: String) {
      self.source = source
      self.cursor = source.startIndex
      // Sentinel — replaced by the first `advance()`.
      self.current = Token(kind: .eof, range: source.startIndex..<source.startIndex)
    }

    var isEOF: Bool { current.kind == .eof }

    func peek() -> Token { current }

    func matches(_ kinds: TokenKind...) -> Bool { kinds.contains(current.kind) }

    /// Throws unless the current token has one of `kinds`, then returns it
    /// without advancing.
    func expect(_ kinds: TokenKind...) throws(JSON5Scanner.Error) -> Token {
      if kinds.contains(current.kind) { return current }
      throw Error.expected(
        kinds.count == 1
          ? "\(kinds[0])"
          : "one of \(kinds)",
        at: current.range.lowerBound
      )
    }

    /// Returns the current token if it matches, then advances.
    @discardableResult
    mutating func consume(_ kinds: TokenKind...) throws(JSON5Scanner.Error) -> Token {
      if kinds.contains(current.kind) {
        let tok = current
        try advance()
        return tok
      }
      throw Error.expected("\(kinds)", at: current.range.lowerBound)
    }

    /// Skips whitespace, newlines, and comments (line + block).
    mutating func skipInsignificant() {
      while matches(.whitespace, .newline, .lineComment, .blockComment) {
        try? advance()
      }
    }

    /// Skips horizontal whitespace and inline line comments — used between a
    /// value and its trailing `,` to keep multi-line members coherent.
    mutating func skipHorizontalAndLineComments() {
      while matches(.whitespace, .lineComment) {
        try? advance()
      }
    }

    /// Lex the next token from `cursor` and store it as `current`.
    mutating func advance() throws(JSON5Scanner.Error) {
      if cursor >= source.endIndex {
        current = Token(kind: .eof, range: source.endIndex..<source.endIndex)
        return
      }

      let start = cursor
      let c = source[cursor]

      // Single-character punctuation.
      switch c {
      case "{": single(.braceLeft); return
      case "}": single(.braceRight); return
      case "[": single(.bracketLeft); return
      case "]": single(.bracketRight); return
      case ":": single(.colon); return
      case ",": single(.comma); return
      default: break
      }

      // Newlines (counted as their own token so the scanner can pin the
      // end of a member to the right line).
      if c == "\r" {
        cursor = source.index(after: cursor)
        if cursor < source.endIndex, source[cursor] == "\n" {
          cursor = source.index(after: cursor)
        }
        current = Token(kind: .newline, range: start..<cursor)
        return
      }
      if c == "\n" {
        cursor = source.index(after: cursor)
        current = Token(kind: .newline, range: start..<cursor)
        return
      }

      // Whitespace.
      if isHorizontalWhitespace(c) {
        while cursor < source.endIndex, isHorizontalWhitespace(source[cursor]) {
          cursor = source.index(after: cursor)
        }
        current = Token(kind: .whitespace, range: start..<cursor)
        return
      }

      // Comments.
      if c == "/" {
        let next = source.index(after: cursor)
        if next < source.endIndex {
          let n = source[next]
          if n == "/" {
            cursor = next
            while cursor < source.endIndex, source[cursor] != "\n", source[cursor] != "\r" {
              cursor = source.index(after: cursor)
            }
            current = Token(kind: .lineComment, range: start..<cursor)
            return
          }
          if n == "*" {
            cursor = source.index(after: next)
            while cursor < source.endIndex {
              if source[cursor] == "*",
                source.index(after: cursor) < source.endIndex,
                source[source.index(after: cursor)] == "/"
              {
                cursor = source.index(after: source.index(after: cursor))
                current = Token(kind: .blockComment, range: start..<cursor)
                return
              }
              cursor = source.index(after: cursor)
            }
            throw Error.unexpectedEOF
          }
        }
        // Bare `/` is not a valid token at the structural level. Fall
        // through to scalar so the parser surfaces the right error.
      }

      // Strings (single or double quoted).
      if c == "\"" || c == "'" {
        try lexString(quote: c)
        return
      }

      // Identifier / scalar — distinguished by leading character.
      if isIdentifierStart(c) {
        // Could be a JSON5 keyword (true/false/null/Infinity/NaN) or an
        // unquoted identifier key. Same scan, then classify.
        while cursor < source.endIndex, isIdentifierPart(source[cursor]) {
          cursor = source.index(after: cursor)
        }
        let text = source[start..<cursor]
        switch text {
        case "true", "false", "null", "Infinity", "NaN":
          current = Token(kind: .scalar, range: start..<cursor)
        default:
          current = Token(kind: .identifier, range: start..<cursor)
        }
        return
      }

      // Numbers.
      if c == "-" || c == "+" || c == "." || c.isASCIIDigit {
        try lexNumber()
        return
      }

      throw Error.unexpected(c, at: start)
    }

    // MARK: - Lex helpers

    private mutating func single(_ kind: TokenKind) {
      let start = cursor
      cursor = source.index(after: cursor)
      current = Token(kind: kind, range: start..<cursor)
    }

    private mutating func lexString(quote: Character) throws(JSON5Scanner.Error) {
      let start = cursor
      cursor = source.index(after: cursor)  // consume opening quote
      while cursor < source.endIndex {
        let c = source[cursor]
        if c == "\\" {
          cursor = source.index(after: cursor)
          if cursor < source.endIndex {
            // Handle \r\n as a single escape continuation.
            if source[cursor] == "\r" {
              cursor = source.index(after: cursor)
              if cursor < source.endIndex, source[cursor] == "\n" {
                cursor = source.index(after: cursor)
              }
              continue
            }
            cursor = source.index(after: cursor)
          }
          continue
        }
        if c == quote {
          cursor = source.index(after: cursor)
          current = Token(kind: .string, range: start..<cursor)
          return
        }
        // JSON5 disallows raw newlines inside strings; we still terminate on
        // them defensively to keep the lexer well-behaved on malformed input.
        if c == "\n" || c == "\r" { break }
        cursor = source.index(after: cursor)
      }
      throw Error.unexpectedEOF
    }

    private mutating func lexNumber() throws(JSON5Scanner.Error) {
      let start = cursor
      // Optional sign.
      if source[cursor] == "+" || source[cursor] == "-" {
        cursor = source.index(after: cursor)
      }
      // Allow signed `Infinity` / `NaN` after a leading `+` or `-`.
      if cursor < source.endIndex, isIdentifierStart(source[cursor]) {
        while cursor < source.endIndex, isIdentifierPart(source[cursor]) {
          cursor = source.index(after: cursor)
        }
        current = Token(kind: .scalar, range: start..<cursor)
        return
      }
      // Hex literal: 0x... / 0X...
      if cursor < source.endIndex, source[cursor] == "0",
        source.index(after: cursor) < source.endIndex,
        let next = source[source.index(after: cursor)..<source.endIndex].first,
        next == "x" || next == "X"
      {
        cursor = source.index(after: source.index(after: cursor))
        while cursor < source.endIndex, source[cursor].isHexDigit {
          cursor = source.index(after: cursor)
        }
        if cursor == start { throw Error.invalidValue(at: start) }
        current = Token(kind: .scalar, range: start..<cursor)
        return
      }
      // Generic numeric scan: digits, dot, exponent.
      while cursor < source.endIndex {
        let c = source[cursor]
        if c.isASCIIDigit || c == "." || c == "e" || c == "E" || c == "+" || c == "-" {
          cursor = source.index(after: cursor)
        } else {
          break
        }
      }
      if cursor == start { throw Error.invalidValue(at: start) }
      current = Token(kind: .scalar, range: start..<cursor)
    }

    // MARK: - Char predicates

    private func isHorizontalWhitespace(_ c: Character) -> Bool {
      switch c {
      case " ", "\t", "\u{0B}", "\u{0C}", "\u{A0}", "\u{FEFF}",
        "\u{1680}", "\u{2028}", "\u{2029}", "\u{202F}", "\u{205F}", "\u{3000}":
        return true
      default:
        if let s = c.unicodeScalars.first, s.value >= 0x2000, s.value <= 0x200A {
          return true
        }
        return false
      }
    }

    private func isIdentifierStart(_ c: Character) -> Bool {
      if c == "$" || c == "_" { return true }
      if c.isLetter { return true }
      return false
    }

    private func isIdentifierPart(_ c: Character) -> Bool {
      if isIdentifierStart(c) { return true }
      if c.isASCIIDigit { return true }
      if let s = c.unicodeScalars.first, s.value == 0x200C || s.value == 0x200D {
        return true
      }
      return false
    }
  }
}

// MARK: - Char helpers

extension Character {
  fileprivate var isASCIIDigit: Bool {
    if let s = unicodeScalars.first, s.value >= 0x30, s.value <= 0x39 {
      return unicodeScalars.count == 1
    }
    return false
  }
}
