import Foundation

extension FormatRule {
  /// Ensure that an `else` statement following `if { ... }` appears on the same line
  /// as the closing brace. This has no effect on the `else` part of a `guard` statement.
  /// Also applies to `catch` after `try` and `while` after `repeat`.
  static let elseOnSameLine = FormatRule(
    help: """
      Place `else`, `catch` or `while` keyword in accordance with current style (same or
      next line).
      """,
    orderAfter: [.wrapMultilineStatementBraces],
    options: ["else-position", "guard-else"],
    sharedOptions: ["allman", "linebreaks"],
  ) { formatter in
    formatter.forEachToken { i, token in
      switch token {
      case .keyword("while"):
        if let endIndex = formatter.index(
          of: .nonSpaceOrCommentOrLineBreak, before: i,
          if: {
            $0 == .endOfScope("}")
          },
        ), let startIndex = formatter.index(of: .startOfScope("{"), before: endIndex),
          formatter
            .last(.nonSpaceOrCommentOrLineBreak, before: startIndex) == .keyword("repeat")
        {
          fallthrough
        }
      case .keyword("else"):
        guard var prevIndex = formatter.index(of: .nonSpace, before: i),
          let nextIndex = formatter.index(
            of: .nonSpaceOrLineBreak, after: i,
            if: {
              !$0.isComment
            },
          )
        else {
          return
        }
        let isOnNewLine = formatter.tokens[prevIndex].isLineBreak
        if isOnNewLine {
          prevIndex =
            formatter
            .index(of: .nonSpaceOrLineBreak, before: i) ?? prevIndex
        }
        if formatter.tokens[prevIndex] == .endOfScope("}"),
          !formatter.isGuardElse(at: i)
        {
          fallthrough
        }
        guard
          let guardIndex = formatter.indexOfLastSignificantKeyword(
            at: prevIndex + 1,
            excluding: [
              "var", "let", "case",
            ],
          ), formatter.tokens[guardIndex] == .keyword("guard")
        else {
          return
        }
        let shouldWrap: Bool
        switch formatter.options.guardElsePosition {
        case .auto:
          // Only wrap if else or following brace is on next line
          shouldWrap =
            isOnNewLine
            || formatter.tokens[i + 1..<nextIndex]
              .contains(where: \.isLineBreak)
        case .nextLine:
          // Only wrap if guard statement spans multiple lines
          shouldWrap =
            isOnNewLine
            || formatter.tokens[guardIndex + 1..<nextIndex]
              .contains(where: \.isLineBreak)
        case .sameLine:
          shouldWrap = false
        }
        if shouldWrap {
          if !formatter.options.allmanBraces {
            formatter.replaceTokens(in: i + 1..<nextIndex, with: .space(" "))
          }
          if !isOnNewLine {
            formatter.replaceTokens(
              in: prevIndex + 1..<i,
              with:
                formatter.linebreakToken(for: prevIndex + 1),
            )
            formatter.insertSpace(
              formatter.currentIndentForLine(at: guardIndex),
              at: prevIndex + 2,
            )
          }
        } else if isOnNewLine {
          formatter.replaceTokens(in: prevIndex + 1..<i, with: .space(" "))
        }
      case .keyword("catch"):
        guard let prevIndex = formatter.index(of: .nonSpace, before: i) else {
          return
        }

        let precededByBlankLine =
          formatter.tokens[prevIndex].isLineBreak
          && formatter.lastToken(
            before: prevIndex,
            where: { !$0.isSpaceOrComment },
          )?.isLineBreak
            == true

        if precededByBlankLine {
          return
        }

        let shouldWrap =
          formatter.options.allmanBraces
          || formatter.options
            .elsePosition == .nextLine
        if !shouldWrap, formatter.tokens[prevIndex].isLineBreak {
          if let prevBraceIndex = formatter.index(
            of: .nonSpaceOrLineBreak, before: prevIndex,
            if: {
              $0 == .endOfScope("}")
            },
          ), formatter.bracesContainLinebreak(prevBraceIndex) {
            formatter.replaceTokens(in: prevBraceIndex + 1..<i, with: .space(" "))
          }
        } else if shouldWrap, let token = formatter.token(at: prevIndex),
          !token.isLineBreak,
          let prevBraceIndex = (token == .endOfScope("}"))
            ? prevIndex
            : formatter.index(
              of: .nonSpaceOrCommentOrLineBreak, before: prevIndex,
              if: {
                $0 == .endOfScope("}")
              },
            ), formatter.bracesContainLinebreak(prevBraceIndex)
        {
          formatter.replaceTokens(
            in: prevIndex + 1..<i,
            with:
              formatter.linebreakToken(for: prevIndex + 1),
          )
          formatter.insertSpace(
            formatter.currentIndentForLine(at: prevIndex + 1), at: prevIndex + 2,
          )
        }
      default:
        break
      }
    }
  } examples: {
    """
    ```diff
      if x {
        // foo
    - }
    - else {
        // bar
      }

      if x {
        // foo
    + } else {
        // bar
      }
    ```

    ```diff
      do {
        // try foo
    - }
    - catch {
        // bar
      }

      do {
        // try foo
    + } catch {
        // bar
      }
    ```

    ```diff
      repeat {
        // foo
    - }
    - while {
        // bar
      }

      repeat {
        // foo
    + } while {
        // bar
      }
    ```
    """
  }
}

extension Formatter {
  func bracesContainLinebreak(_ endIndex: Int) -> Bool {
    guard let startIndex = index(of: .startOfScope("{"), before: endIndex) else {
      return false
    }
    return (startIndex..<endIndex).contains(where: { tokens[$0].isLineBreak })
  }
}
