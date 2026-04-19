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

extension Trivia {
    var hasAnyComments: Bool {
        return contains {
            switch $0 {
            case .lineComment, .docLineComment, .blockComment, .docBlockComment:
                return true
            default:
                return false
            }
        }
    }

    /// Returns whether the trivia contains at least 1 `lineComment`.
    var hasLineComment: Bool {
        return self.contains {
            if case .lineComment = $0 { return true }
            return false
        }
    }

    /// Returns this set of trivia, without any leading spaces.
    func withoutLeadingSpaces() -> Trivia {
        return Trivia(pieces: self.pieces.drop(while: \.isSpaceOrTab))
    }

    func withoutTrailingSpaces() -> Trivia {
        guard let lastNonSpaceIndex = self.pieces.lastIndex(where: \.isSpaceOrTab) else {
            return self
        }
        return Trivia(pieces: self[..<lastNonSpaceIndex])
    }

    /// Returns this trivia, excluding the last newline and anything following it.
    ///
    /// If there is no newline in the trivia, it is returned unmodified.
    func withoutLastLine() -> Trivia {
        var maybeLastNewlineOffset: Int? = nil
        for (offset, piece) in self.enumerated() {
            switch piece {
            case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                maybeLastNewlineOffset = offset
            default:
                break
            }
        }
        guard let lastNewlineOffset = maybeLastNewlineOffset else { return self }
        return Trivia(pieces: self.dropLast(self.count - lastNewlineOffset))
    }

    /// Returns `true` if this trivia contains any newlines.
    var containsNewlines: Bool {
        return contains(
            where: {
                if case .newlines = $0 { return true }
                return false
            })
    }

    /// Returns `true` if this trivia contains any spaces.
    var containsSpaces: Bool {
        return contains(
            where: {
                if case .spaces = $0 { return true }
                if case .tabs = $0 { return true }
                return false
            })
    }

    /// Returns the prefix of this trivia that corresponds to the backslash and pound signs used to
    /// represent a non-line-break continuation of a multiline string, or nil if the trivia does not
    /// represent such a continuation.
    var multilineStringContinuation: String? {
        var result = ""
        for piece in pieces {
            switch piece {
            case .backslashes, .pounds:
                piece.write(to: &result)
            default:
                break
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
            if case .newlines(let n) = piece {
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

    /// Returns a copy with multi-newline pieces collapsed to single newlines.
    var reducingToSingleNewlines: Trivia {
        var pieces = Array(self.pieces)
        for (i, piece) in pieces.enumerated() {
            if case .newlines(let n) = piece, n > 1 {
                pieces[i] = .newlines(1)
            }
        }
        return Trivia(pieces: pieces)
    }

    /// The total count of newline characters, including carriage returns and CR+LF.
    var totalNewlineCount: Int {
        pieces.reduce(0) { count, piece in
            switch piece {
            case .newlines(let n): count + n
            case .carriageReturns(let n): count + n
            case .carriageReturnLineFeeds(let n): count + n
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
        let pieces = self.indices.reduce([TriviaPiece]()) { (partialResult, index) in
            let piece = self[index]
            // Collapse consecutive newlines into a single one
            if case .newlines(let count) = piece {
                if fromClosingBrace {
                    if index == self.count - 1 {
                        // For the last index(newline right before the closing brace), collapse into a single newline
                        trimmed += count - 1
                        return partialResult + [.newlines(1)]
                    } else {
                        pendingNewlineCount += count
                        return partialResult
                    }
                } else {
                    if let last = partialResult.last, last.isNewline {
                        trimmed += count
                        return partialResult
                    } else if index == 0 {
                        // For leading trivia not associated with a closing brace, collapse the first newline into a single one
                        trimmed += count - 1
                        return partialResult + [.newlines(1)]
                    } else {
                        return partialResult + [piece]
                    }
                }
            }
            // Remove spaces/tabs surrounded by newlines
            if piece.isSpaceOrTab, index > 0, index < self.count - 1, self[index - 1].isNewline,
                self[index + 1].isNewline
            {
                return partialResult
            }
            // Handle pending newlines if there are any
            if pendingNewlineCount > 0 {
                if index < self.count - 1 {
                    let newlines = TriviaPiece.newlines(pendingNewlineCount)
                    pendingNewlineCount = 0
                    return partialResult + [newlines] + [piece]
                } else {
                    return partialResult + [.newlines(1)] + [piece]
                }
            }
            // Retain other trivia pieces
            return partialResult + [piece]
        }

        return (Trivia(pieces: pieces), trimmed)
    }

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
            if case .spaces = last {
                pieces.removeLast()
            } else if case .tabs = last {
                pieces.removeLast()
            } else {
                break
            }
        }
        return Trivia(pieces: pieces)
    }
}
