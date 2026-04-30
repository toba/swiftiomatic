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

import Foundation

struct Verbatim: Sendable {
    /// Hoisted to avoid rebuilding a `CharacterSet` per line during init.
    private static let spacesOnly = CharacterSet(charactersIn: " ")

    /// The behavior used to adjust indentation when printing verbatim content.
    private let indentingBehavior: IndentingBehavior

    /// The lines of verbatim text.
    private let lines: [String]

    /// The number of leading whitespaces to print for each line of verbatim content, not including
    /// any additional indentation requested externally.
    private let leadingWhitespaceCounts: [Int]

    init(text: String, indentingBehavior: IndentingBehavior) {
        self.indentingBehavior = indentingBehavior

        var originalLines = text.split(separator: "\n", omittingEmptySubsequences: false)

        // Prevents an extra leading new line from being created.
        if originalLines[0].isEmpty { originalLines.remove(at: 0) }

        // If we have no lines left (or none with any content), just initialize everything empty and
        // exit.
        guard !originalLines.isEmpty,
              let index = originalLines.firstIndex(where: { !$0.isEmpty })
        else {
            lines = []
            leadingWhitespaceCounts = []
            return
        }

        // If our indenting behavior is `none` , then keep the original lines _exactly_ as
        // is---don't attempt to calculate or trim their leading indentation.
        guard indentingBehavior != .none else {
            lines = originalLines.map(String.init)
            leadingWhitespaceCounts = [Int](repeating: 0, count: originalLines.count)
            return
        }

        // Otherwise, we're in one of the indentation compensating modes. Get the number of leading
        // whitespaces of the first line, and subtract this from the number of leading whitespaces
        // for subsequent lines (if possible). Record the new leading whitespaces counts, and trim
        // off whitespace from the ends of the strings.
        let firstLineLeadingSpaceCount = numberOfLeadingSpaces(in: originalLines[index])

        leadingWhitespaceCounts = originalLines.map {
            max(numberOfLeadingSpaces(in: $0) - firstLineLeadingSpaceCount, 0)
        }
        lines = originalLines.map {
            $0.trimmingCharacters(in: Self.spacesOnly)
        }
    }

    /// Returns the length that the pretty printer should use when determining layout for this
    /// verbatim content.
    ///
    /// Specifically, multiline content should have a length equal to the maximum (to force
    /// breaking), while single-line content should have its natural length.
    func prettyPrintingLength(maximum: Int) -> Int {
        if lines.isEmpty { 0 } else if lines.count > 1 { maximum } else { lines[0].count }
    }

    func print(indent: [Indent]) -> String {
        // Hoist the indentation string and pre-compute the output capacity so the writer doesn't
        // reallocate while concatenating each line.
        let indentation = indent.indentation()
        var capacity = 0

        for i in 0..<lines.count {
            let line = lines[i]

            if !line.isEmpty {
                switch indentingBehavior {
                    case .firstLine where i == 0, .allLines: capacity += indentation.utf8.count
                    case .none, .firstLine: break
                }
                capacity += leadingWhitespaceCounts[i] + line.utf8.count
            }
            if i < lines.count - 1 { capacity += 1 }
        }

        var output = ""
        output.reserveCapacity(capacity)

        for i in 0..<lines.count {
            if !lines[i].isEmpty {
                switch indentingBehavior {
                    case .firstLine where i == 0, .allLines: output += indentation
                    case .none, .firstLine: break
                }
                if leadingWhitespaceCounts[i] > 0 {
                    output += SpacePadding.spaces(leadingWhitespaceCounts[i])
                }
                output += lines[i]
            }
            if i < lines.count - 1 { output += "\n" }
        }
        return output
    }
}

// MARK: - Support

/// Describes options for behavior when applying the indentation of the current context when
/// printing a verbatim token.
enum IndentingBehavior: Sendable { case none, allLines, firstLine }

/// Returns the leading number of spaces in the given string.
private func numberOfLeadingSpaces(in text: Substring) -> Int {
    var count = 0
    for char in text { if char == " " { count += 1 } else { break } }
    return count
}
