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

struct Verbatim: Sendable {
    /// One line of verbatim content.
    private struct Line: Sendable {
        /// The UTF-8 offset range of the line text in `text` , with leading and trailing spaces
        /// removed unless the indenting behavior is `none` .
        var range: Range<Int>

        /// The number of leading spaces to print before the line text, not including any
        /// additional indentation requested externally.
        var leadingSpaces: Int
    }

    /// The behavior used to adjust indentation when printing verbatim content.
    private let indentingBehavior: IndentingBehavior

    /// The owned text that holds every line.
    private let text: String

    /// The lines of verbatim text.
    private let lines: [Line]

    init(text: String, indentingBehavior: IndentingBehavior) {
        self.indentingBehavior = indentingBehavior
        self.text = text

        // Split at each line feed that is a `Character` of its own. A line feed after a carriage
        // return is part of one `Character` , so it does not split the line.
        let bytes = text.utf8.span
        var lines = [Line]()
        var lineStart = 0

        for index in bytes.indices where bytes[index] == UInt8(ascii: "\n") {
            if index > 0, bytes[index - 1] == UInt8(ascii: "\r") { continue }
            lines.append(Line(range: lineStart..<index, leadingSpaces: 0))
            lineStart = index + 1
        }
        lines.append(Line(range: lineStart..<bytes.count, leadingSpaces: 0))

        // Prevents an extra leading new line from being created.
        if lines[0].range.isEmpty { lines.removeFirst() }

        // If we have no lines left (or none with any content), just initialize everything empty and
        // exit.
        guard let index = lines.firstIndex(where: { !$0.range.isEmpty }) else {
            self.lines = []
            return
        }

        // If our indenting behavior is `none` , then keep the original lines _exactly_ as
        // is---don't attempt to calculate or trim their leading indentation.
        guard indentingBehavior != .none else {
            self.lines = lines
            return
        }

        // Otherwise, we're in one of the indentation compensating modes. Get the number of leading
        // whitespaces of the first line, and subtract this from the number of leading whitespaces
        // for subsequent lines (if possible). Record the new leading whitespaces counts, and trim
        // off spaces from the ends of the lines.
        let firstLineLeadingSpaceCount = Self.numberOfLeadingSpaces(in: lines[index].range, of: text)

        for i in lines.indices {
            let range = lines[i].range
            lines[i] = Line(
                range: Self.trimmingSpaces(range, in: bytes),
                leadingSpaces: max(
                    Self.numberOfLeadingSpaces(in: range, of: text) - firstLineLeadingSpaceCount, 0)
            )
        }
        self.lines = lines
    }

    /// Returns the length that the pretty printer should use when determining layout for this
    /// verbatim content.
    ///
    /// Specifically, multiline content should have a length equal to the maximum (to force
    /// breaking), while single-line content should have its natural length.
    func prettyPrintingLength(maximum: Int) -> Int {
        if lines.isEmpty { 0 } else if lines.count > 1 { maximum } else { lineText(lines[0]).count }
    }

    /// Writes the verbatim content to the given string with the given indentation.
    func print(into output: inout String, indentation: LayoutIndentation) {
        for i in lines.indices {
            let line = lines[i]

            if !line.range.isEmpty {
                switch indentingBehavior {
                    case .firstLine where i == 0, .allLines: indentation.append(to: &output)
                    case .none, .firstLine: break
                }
                appendSpaces(line.leadingSpaces, to: &output)
                output.append(contentsOf: lineText(line))
            }
            if i < lines.count - 1 { output.append("\n") }
        }
    }

    /// Returns the verbatim content with the given indentation.
    func print(indentation: LayoutIndentation) -> String {
        var output = ""
        print(into: &output, indentation: indentation)
        return output
    }

    private func lineText(_ line: Line) -> Substring {
        let utf8 = text.utf8
        let start = utf8.index(utf8.startIndex, offsetBy: line.range.lowerBound)
        let end = utf8.index(start, offsetBy: line.range.count)
        return text[start..<end]
    }

    /// Returns the number of leading `Character` values in the line that are a single space.
    private static func numberOfLeadingSpaces(in range: Range<Int>, of text: String) -> Int {
        let bytes = text.utf8.span
        var index = range.lowerBound

        while index < range.upperBound, bytes[index] == UInt8(ascii: " ") { index += 1 }

        // A non-ASCII scalar after the spaces can join the last space into one `Character` .
        guard index < range.upperBound, bytes[index] >= 0x80 else { return index - range.lowerBound }

        let utf8 = text.utf8
        let start = utf8.index(utf8.startIndex, offsetBy: range.lowerBound)
        let end = utf8.index(utf8.startIndex, offsetBy: range.upperBound)
        var count = 0
        for character in text[start..<end] { if character == " " { count += 1 } else { break } }
        return count
    }

    /// Returns the range without its leading and trailing U+0020 scalars. This matches
    /// `trimmingCharacters(in: CharacterSet(charactersIn: " "))` , which trims scalars.
    private static func trimmingSpaces(_ range: Range<Int>, in bytes: Span<UInt8>) -> Range<Int> {
        var lower = range.lowerBound
        var upper = range.upperBound
        while lower < upper, bytes[lower] == UInt8(ascii: " ") { lower += 1 }
        while upper > lower, bytes[upper - 1] == UInt8(ascii: " ") { upper -= 1 }
        return lower..<upper
    }
}

// MARK: - Support

/// Describes options for behavior when applying the indentation of the current context when
/// printing a verbatim token.
enum IndentingBehavior: Sendable { case none, allLines, firstLine }
