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
                || ch == "\u{0B}" || ch == "\u{0C}" else { break }
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
                 0x0C:
                true
            default: false
        }
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
    var text: [String]
    var length: Int
    // what was the leading indentation, if any, that preceded this comment?
    var leadingIndent: Indent?

    init(kind: Kind, leadingIndent: Indent?, text: String) {
        self.kind = kind
        self.leadingIndent = leadingIndent

        switch kind {
            case .line, .docLine:
                length = text.count
                self.text = [text]
                self.text[0].removeFirst(kind.prefixLength)

            case .block, .docBlock:
                var fullText: String = text
                fullText.removeFirst(kind.prefixLength)
                fullText.removeLast(2)

                let lines = fullText.split(separator: "\n", omittingEmptySubsequences: false)

                // The last line in a block style comment contains the "*/" pattern to end the
                // comment. The trailing space(s) need to be kept in that line to have space between
                // text and "*/".
                var trimmedLines = lines.dropLast().map { $0.trimmingTrailingWhitespace() }
                if let lastLine = lines.last { trimmedLines.append(String(lastLine)) }
                self.text = trimmedLines
                length = self.text.reduce(0) { $0 + $1.count } + kind.prefixLength + 3
        }
    }

    func print(indent: [Indent], shouldIndentBlankLines: Bool = true) -> String {
        switch kind {
            case .line, .docLine:
                let separator = "\n" + indent.indentation() + kind.prefix
                let trimmedLines = text.map { $0.trimmingTrailingWhitespace() }
                return kind.prefix + trimmedLines.joined(separator: separator)
            case .block, .docBlock:
                let separator = "\n"

                // if all the lines after the first matching leadingIndent, replace that prefix with
                // the current indentation level
                if let leadingIndent {
                    let rest = text.dropFirst()
                    let hasLeading = rest.allSatisfy {
                        $0.hasPrefix(leadingIndent.text) || $0.isEmpty
                    }
                    if hasLeading, let first = text.first, !rest.isEmpty {
                        let indentation = indent.indentation()
                        let restStr = rest.map {
                            guard !$0.isEmpty else {
                                return shouldIndentBlankLines ? indentation : ""
                            }
                            let stripped = $0.dropFirst(leadingIndent.text.count)
                            return indentation + stripped
                        }.joined(separator: separator)
                        return kind.prefix + first + separator + restStr + "*/"
                    }
                }
                return kind.prefix + text.joined(separator: separator) + "*/"
        }
    }

    mutating func addText(_ text: [String]) {
        for line in text {
            self.text.append(line)
            length += line.count + kind.prefixLength + 1
        }
    }
}
