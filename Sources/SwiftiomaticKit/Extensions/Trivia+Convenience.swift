// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import SwiftSyntax

extension Trivia {
    var hasAnyComments: Bool { contains(where: Trivia.isCommentPiece) }

    /// Returns whether the trivia contains at least 1 `lineComment` .
    var hasLineComment: Bool {
        contains {
            if case .lineComment = $0 { return true }
            return false
        }
    }

    /// Returns this set of trivia, without any leading spaces.
    func withoutLeadingSpaces() -> Trivia { .init(pieces: pieces.drop(while: \.isSpaceOrTab)) }

    /// Returns whether the given trivia piece is a comment of any kind.
    private static func isCommentPiece(_ piece: TriviaPiece) -> Bool {
        switch piece {
            case .lineComment, .docLineComment, .blockComment, .docBlockComment: true
            default: false
        }
    }

    private static func isWhitespace(_ piece: TriviaPiece) -> Bool {
        switch piece {
            case .newlines, .carriageReturns, .carriageReturnLineFeeds, .formfeeds, .spaces, .tabs:
                true
            default: false
        }
    }

    /// Splits this trivia into the leading comments that should be hoisted ahead of a token and
    /// the remaining trivia that should stay with the token itself.
    ///
    /// All leading whitespace is discarded. If a comment is present, the returned `hoisted` trivia
    /// contains every comment up to and including the last one (along with any whitespace between
    /// them), with surrounding whitespace trimmed. The `remainder` is whatever followed the last
    /// comment, with its own leading whitespace removed. If there is no comment, `hoisted` is
    /// empty and `remainder` is the trivia with leading whitespace removed.
    func splittingLeadingComments() -> (hoisted: Trivia, remainder: Trivia) {
        let pieces = Array(self.pieces)
        guard let lastCommentIndex = pieces.lastIndex(where: Trivia.isCommentPiece) else {
            return (Trivia(pieces: []), Trivia(pieces: pieces.drop(while: Trivia.isWhitespace)))
        }

        let throughLastComment = pieces[...lastCommentIndex]
        let hoisted = throughLastComment.drop(while: Trivia.isWhitespace)
        let remainder = pieces[(lastCommentIndex + 1)...].drop(while: Trivia.isWhitespace)
        return (Trivia(pieces: Array(hoisted)), Trivia(pieces: Array(remainder)))
    }

    /// Returns this trivia, excluding the last newline and anything following it.
    ///
    /// If there is no newline in the trivia, it is returned unmodified.
    func withoutLastLine() -> Trivia {
        var maybeLastNewlineOffset: Int?

        for (offset, piece) in enumerated() {
            switch piece {
                case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                    maybeLastNewlineOffset = offset
                default: break
            }
        }
        guard let lastNewlineOffset = maybeLastNewlineOffset else { return self }
        return .init(pieces: dropLast(count - lastNewlineOffset))
    }

    /// Returns `true` if this trivia contains any newlines.
    var containsNewlines: Bool {
        contains(
            where: {
                if case .newlines = $0 { return true }
                return false
            })
    }

    /// Returns `true` if this trivia contains any spaces.
    var containsSpaces: Bool {
        contains(
            where: {
                if case .spaces = $0 { true } else if case .tabs = $0 { true } else { false }
            })
    }

    /// Returns the prefix of this trivia that corresponds to the backslash and pound signs used to
    /// represent a non-line-break continuation of a multiline string, or nil if the trivia does not
    /// represent such a continuation.
    var multilineStringContinuation: String? {
        var result = ""
        for piece in pieces {
            switch piece {
                case .backslashes, .pounds: piece.write(to: &result)
                default: break
            }
        }
        return result.isEmpty ? nil : result
    }

    /// The number of blank lines in the leading portion of this trivia (before the first comment or
    /// non-whitespace piece). A single newline separating lines counts as 0 blank lines; two
    /// consecutive newlines count as 1 blank line, etc.
    var blankLineCount: Int {
        var newlines = 0
        for piece in pieces {
            if case let .newlines(n) = piece {
                newlines += n
            } else if piece.isSpaceOrTab {
                continue
            } else {
                break
            }
        }
        return Swift.max(0, newlines - 1)
    }

    /// Whether this trivia contains at least one blank line (two or more newlines before any
    /// non-whitespace content).
    var hasBlankLine: Bool { blankLineCount > 0 }

    /// Whether this trivia starts with a comment (before any blank line).
    ///
    /// Returns `true` when the first non-whitespace piece in the trivia is a comment, which means
    /// `hasBlankLine` would return `false` even if blank lines follow.
    var startsWithComment: Bool {
        for piece in pieces {
            switch piece {
                case .lineComment, .docLineComment, .blockComment, .docBlockComment: return true
                case .newlines, .spaces, .tabs, .carriageReturns, .carriageReturnLineFeeds: continue
                default: return false
            }
        }
        return false
    }

    /// Returns a copy with multi-newline pieces collapsed to single newlines.
    var reducingToSingleNewlines: Trivia {
        var pieces = Array(self.pieces)
        for (i, piece) in pieces.enumerated() {
            if case let .newlines(n) = piece, n > 1 { pieces[i] = .newlines(1) }
        }
        return .init(pieces: pieces)
    }

    /// The total count of newline characters, including carriage returns and CR+LF.
    var totalNewlineCount: Int {
        pieces.reduce(0) { count, piece in
            switch piece {
                case let .newlines(n): count + n
                case let .carriageReturns(n): count + n
                case let .carriageReturnLineFeeds(n): count + n
                default: count
            }
        }
    }

    /// Returns a copy with the first `.newlines` piece replaced by the given count.
    func replacingFirstNewlines(with count: Int) -> Trivia {
        var pieces = Array(self.pieces)

        for (i, piece) in pieces.enumerated() {
            if case .newlines = piece {
                pieces[i] = .newlines(count)
                return Trivia(pieces: pieces)
            }
        }
        return self
    }

    func trimmingSuperfluousNewlines(fromClosingBrace: Bool) -> (Trivia, Int) {
        var trimmed = 0
        var pendingNewlineCount = 0
        let pieces = indices.reduce(into: [TriviaPiece]()) { partialResult, index in
            let piece = self[index]
            // Collapse consecutive newlines into a single one
            if case let .newlines(count) = piece {
                if fromClosingBrace {
                    if index == self.count - 1 {
                        // For the last index(newline right before the closing brace), collapse into
                        // a single newline
                        trimmed += count - 1
                        partialResult.append(.newlines(1))
                    } else {
                        pendingNewlineCount += count
                    }
                } else {
                    if let last = partialResult.last, last.isNewline {
                        trimmed += count
                    } else if index == 0 {
                        // For leading trivia not associated with a closing brace, collapse the
                        // first newline into a single one
                        trimmed += count - 1
                        partialResult.append(.newlines(1))
                    } else {
                        partialResult.append(piece)
                    }
                }
                return
            }
            // Remove spaces/tabs surrounded by newlines
            if piece.isSpaceOrTab,
               index > 0,
               index < self.count - 1,
               self[index - 1].isNewline,
               self[index + 1].isNewline
            {
                return
            }
            // Handle pending newlines if there are any
            if pendingNewlineCount > 0 {
                if index < self.count - 1 {
                    partialResult.append(.newlines(pendingNewlineCount))
                    pendingNewlineCount = 0
                    partialResult.append(piece)
                } else {
                    partialResult.append(.newlines(1))
                    partialResult.append(piece)
                }
                return
            }
            // Retain other trivia pieces
            partialResult.append(piece)
        }

        return (Trivia(pieces: pieces), trimmed)
    }

    /// Extracts the indentation string (spaces/tabs) after the last newline.
    var indentation: String {
        // Collect the run in reverse, then reverse once. Prepending to a string reallocates on
        // every piece.
        var reversedPieces: [String] = []
        var foundNewline = false

        for piece in pieces.reversed() {
            if foundNewline { break }

            switch piece {
                case let .spaces(n): reversedPieces.append(SpacePadding.spaces(n))
                case let .tabs(n): reversedPieces.append(String(repeating: "\t", count: n))
                case .newlines, .carriageReturns, .carriageReturnLineFeeds: foundNewline = true
                default: reversedPieces.removeAll()
            }
        }
        return reversedPieces.reversed().joined()
    }

    /// The character width of the indentation run `indentation` returns
    ///
    /// Use this in place of `indentation.count` . It counts the same run without building the
    /// string, so a caller that only compares a column pays no allocation.
    var indentationWidth: Int {
        var width = 0

        for piece in pieces.reversed() {
            switch piece {
                case let .spaces(n): width += n
                case let .tabs(n): width += n
                case .newlines, .carriageReturns, .carriageReturnLineFeeds: return width
                // a non-whitespace piece ends the run, so anything past it is not indentation
                default: width = 0
            }
        }
        return width
    }

    /// Returns a copy with trailing spaces and tabs removed.
    var trimmingTrailingWhitespace: Trivia {
        var pieces = Array(self.pieces)
        while let last = pieces.last {
            if case .spaces = last {
                pieces.removeLast()
            } else if case .tabs = last {
                pieces.removeLast()
            } else {
                break
            }
        }
        return .init(pieces: pieces)
    }
}
