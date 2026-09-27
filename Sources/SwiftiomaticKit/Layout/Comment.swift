// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import Foundation
import SwiftSyntax

extension StringProtocol {
    /// Trims whitespace from the end of a string, returning a new string with no trailing
    /// whitespace.
    ///
    /// If the string is only whitespace, an empty string is returned.
    ///
    /// - Returns: The string with trailing whitespace removed.
    func trimmingTrailingWhitespace() -> String {
        if isEmpty { return String() }
        // Walk Characters from the end (StringProtocol is BidirectionalCollection) instead of
        // materializing `Array(utf8)` . The set of whitespace recognized here matches the prior
        // byte-level check: space, LF, tab, CR, VT, FF.
        var end = endIndex

        while end > startIndex {
            let prev = index(before: end)
            let ch = self[prev]
            guard ch == " " || ch == "\n" || ch == "\t" || ch == "\r"
                || ch == "\u{0B}" || ch == "\u{0C}"
            else { break }
            end = prev
        }
        return end == startIndex ? String() : String(self[..<end])
    }
}

extension UTF8.CodeUnit {
    /// Checks if the UTF-8 code unit represents a whitespace character.
    ///
    /// - Returns: `true` if the code unit represents a whitespace character, otherwise `false` .
    var isWhitespace: Bool {
        switch self {
            case UInt8(ascii: " "),
                 UInt8(ascii: "\n"),
                 UInt8(ascii: "\t"),
                 UInt8(ascii: "\r"), /*VT*/
                 0x0B, /*FF*/
                 0x0C: true
            default: false
        }
    }
}

extension Substring {
    /// Drops the trailing whitespace. This matches `trimmingTrailingWhitespace()` but returns a
    /// slice of the same storage.
    fileprivate func droppingTrailingWhitespace() -> Substring {
        var end = endIndex

        while end > startIndex {
            let prev = index(before: end)
            let ch = self[prev]
            guard ch == " " || ch == "\n" || ch == "\t" || ch == "\r"
                || ch == "\u{0B}" || ch == "\u{0C}"
            else { break }
            end = prev
        }
        return self[..<end]
    }

    /// Whether the slice starts with `count` copies of the given character. This matches
    /// `hasPrefix` with a string of `count` copies of `character` .
    fileprivate func starts(with character: Character, count: Int) -> Bool {
        var remaining = count

        for ch in self {
            guard remaining > 0 else { return true }
            guard ch == character else { return false }
            remaining -= 1
        }
        return remaining == 0
    }
}

struct Comment: Sendable {
    enum Kind: Sendable {
        case line, docLine, block, docBlock

        /// The length of the characters starting the comment.
        var prefixLength: Int {
            switch self {
                // `//` , `/*`
                case .line, .block: 2
                // `///` , `/**`
                case .docLine, .docBlock: 3
            }
        }

        var prefix: String {
            switch self {
                case .line: "//"
                case .block: "/*"
                case .docBlock: "/**"
                case .docLine: "///"
            }
        }
    }

    let kind: Kind

    /// The owned text that holds every line. Merged `//` lines are appended to it, each after a
    /// newline, so that a line never shares a grapheme cluster with the line before it.
    private var storage: String

    /// The UTF-8 offset range of each line in `storage` . A line holds the text after the comment
    /// prefix. The lines of a block comment have their trailing whitespace removed, except the
    /// last line.
    private var lineRanges: [Range<Int>]

    var length: Int
    // what was the leading indentation, if any, that preceded this comment?
    var leadingIndent: Indent?
    // A regular `//` comment that directly follows a `///` doc comment is indented one extra space
    // so its body aligns with the doc comment body (whose `///` prefix is one character wider than
    // `//`).
    var alignsWithPrecedingDocLine = false

    init(kind: Kind, leadingIndent: Indent?, text: String) {
        self.kind = kind
        self.leadingIndent = leadingIndent
        storage = text

        let bodyStart = text.index(text.startIndex, offsetBy: kind.prefixLength)

        switch kind {
            case .line, .docLine:
                length = text.count
                lineRanges = [Self.offset(of: bodyStart, in: text)..<text.utf8.count]

            case .block, .docBlock:
                let bodyEnd = text.index(text.endIndex, offsetBy: -2)
                let lines = text[bodyStart..<bodyEnd]
                    .split(separator: "\n", omittingEmptySubsequences: false)

                // The last line in a block style comment contains the "*/" pattern to end the
                // comment. The trailing space(s) need to be kept in that line to have space between
                // text and "*/".
                var ranges = [Range<Int>]()
                ranges.reserveCapacity(lines.count)
                var total = 0

                for (index, line) in lines.enumerated() {
                    let kept = index == lines.count - 1 ? line : line.droppingTrailingWhitespace()
                    total += kept.count
                    ranges.append(
                        Self.offset(of: kept.startIndex, in: text)
                            ..< Self.offset(of: kept.endIndex, in: text))
                }
                lineRanges = ranges
                length = total + kind.prefixLength + 3
        }
    }

    /// The first line, after the comment prefix.
    var firstLine: Substring? { lineRanges.first.map(lineText(at:)) }

    /// Writes the comment to the given string. Each line after the first starts with the given
    /// indentation.
    func print(
        into output: inout String,
        indentation: LayoutIndentation,
        shouldIndentBlankLines: Bool = true
    ) {
        switch kind {
            case .line, .docLine:
                for (index, range) in lineRanges.enumerated() {
                    if index > 0 {
                        output.append("\n")
                        indentation.append(to: &output)
                    }
                    output.append(kind.prefix)

                    let line = lineText(at: range).droppingTrailingWhitespace()

                    // Indent the body one extra space so it aligns with the `///` body. A standard
                    // `// ` body has a single leading space; bump it to two. Lines that already
                    // have two leading spaces are left untouched, which keeps the transform a fixed
                    // point (idempotent) when re-formatting already-aligned input.
                    if alignsWithPrecedingDocLine, line.hasPrefix(" "), !line.hasPrefix("  ") {
                        output.append(" ")
                    }
                    output.append(contentsOf: line)
                }
            case .block, .docBlock:
                output.append(kind.prefix)

                // if all the lines after the first matching leadingIndent, replace that prefix with
                // the current indentation level
                if let leadingIndent, lineRanges.count > 1 {
                    let indentCharacter = leadingIndent.character
                    let indentCount = leadingIndent.count
                    let rest = lineRanges.dropFirst()
                    let hasLeading = rest.allSatisfy {
                        let line = lineText(at: $0)
                        return line.isEmpty
                            || line.starts(with: indentCharacter, count: indentCount)
                    }

                    if hasLeading {
                        output.append(contentsOf: lineText(at: lineRanges[0]))

                        for range in rest {
                            output.append("\n")
                            let line = lineText(at: range)

                            guard !line.isEmpty else {
                                if shouldIndentBlankLines { indentation.append(to: &output) }
                                continue
                            }
                            indentation.append(to: &output)
                            output.append(contentsOf: line.dropFirst(indentCount))
                        }
                        output.append("*/")
                        return
                    }
                }
                for (index, range) in lineRanges.enumerated() {
                    if index > 0 { output.append("\n") }
                    output.append(contentsOf: lineText(at: range))
                }
                output.append("*/")
        }
    }

    /// Returns the comment text with the given indentation.
    func print(indentation: LayoutIndentation, shouldIndentBlankLines: Bool = true) -> String {
        var output = ""
        print(into: &output, indentation: indentation, shouldIndentBlankLines: shouldIndentBlankLines)
        return output
    }

    /// Appends the lines of another comment of the same kind.
    mutating func addLines(of other: Comment) {
        for range in other.lineRanges {
            let line = other.lineText(at: range)
            storage.append("\n")
            let start = storage.utf8.count
            storage.append(contentsOf: line)
            lineRanges.append(start..<storage.utf8.count)
            length += line.count + kind.prefixLength + 1
        }
    }

    private func lineText(at range: Range<Int>) -> Substring {
        let utf8 = storage.utf8
        let start = utf8.index(utf8.startIndex, offsetBy: range.lowerBound)
        let end = utf8.index(start, offsetBy: range.count)
        return storage[start..<end]
    }

    private static func offset(of index: String.Index, in text: String) -> Int {
        text.utf8.distance(from: text.utf8.startIndex, to: index)
    }
}
