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

import SwiftSyntax

private let utf8Newline = UTF8.CodeUnit(ascii: "\n")
private let utf8Tab = UTF8.CodeUnit(ascii: "\t")

/// Emits linter errors for whitespace style violations by comparing the raw text of the input Swift
/// code with formatted text.
package final class WhitespaceLinter {
    /// The text of the input source code to be linted.
    private let userText: String

    /// The formatted version of `userText` .
    private let formattedText: String

    /// The Context object containing the DiagnosticEngine.
    private let context: Context

    /// The line length limit. It is read once, because each whitespace run at the start of a line
    /// uses it.
    private let lineLength: Int

    /// Creates a new WhitespaceLinter with the given context.
    ///
    /// - Parameters:
    ///   - user: The text of the Swift source code to be linted.
    ///   - formatted: The formatted text to compare to `user` .
    ///   - context: The context object containing the DiagnosticEngine instance we wish to use.
    package init(user: String, formatted: String, context: Context) {
        userText = user
        formattedText = formatted
        self.context = context
        lineLength = context.configuration[LineLength.self]
    }

    /// Perform whitespace linting.
    ///
    /// The scanner reads the UTF-8 bytes of both texts through borrowed spans. A native string
    /// gives its bytes in place, so no text is copied into an array.
    package func lint() {
        var user = userText
        var formatted = formattedText
        // No-ops for native strings. A bridged string gets contiguous UTF-8 storage once.
        user.makeContiguousUTF8()
        formatted.makeContiguousUTF8()
        let userBytes = user.utf8
        let formattedBytes = formatted.utf8

        var scanner = WhitespaceScanner(
            user: userBytes.span,
            formatted: formattedBytes.span,
            lineLength: lineLength,
            context: context
        )
        scanner.scan()
    }
}

/// Compares the whitespace of the user text with the whitespace of the formatted text.
///
/// The scanner borrows the bytes of both texts. It cannot outlive them, so it is `~Escapable` . A
/// whitespace run is a `Range<Int>` of byte offsets into one of the two spans.
private struct WhitespaceScanner: ~Copyable, ~Escapable {
    /// The UTF-8 bytes of the user text.
    let user: Span<UInt8>

    /// The UTF-8 bytes of the formatted text.
    let formatted: Span<UInt8>

    /// The line length limit.
    let lineLength: Int

    /// The Context object containing the DiagnosticEngine.
    let context: Context

    /// Is the current line too long?
    private var isLineTooLong = false

    @_lifetime(copy user, copy formatted)
    init(user: Span<UInt8>, formatted: Span<UInt8>, lineLength: Int, context: Context) {
        self.user = user
        self.formatted = formatted
        self.lineLength = lineLength
        self.context = context
    }

    /// Compares each whitespace run of the user text with the matching run of the formatted text.
    @_lifetime(self: copy self)
    mutating func scan() {
        var userIndex = 0
        var formattedIndex = 0
        var userWhitespace: Range<Int>

        repeat {
            userWhitespace = contiguousWhitespace(startingAt: userIndex, in: user)
            let formattedWhitespace = contiguousWhitespace(
                startingAt: formattedIndex,
                in: formatted
            )

            // `user` and `formatted` should only differ in their whitespace characters.
            assert(
                safeCodeUnit(at: userWhitespace.upperBound, in: user)
                    == safeCodeUnit(at: formattedWhitespace.upperBound, in: formatted),
                "Non-whitespace characters do not match"
            )

            compareWhitespace(
                userWhitespace: userWhitespace,
                formattedWhitespace: formattedWhitespace
            )

            userIndex = userWhitespace.upperBound + 1
            formattedIndex = formattedWhitespace.upperBound + 1
        } while userWhitespace.upperBound != user.count
    }

    /// Compare the whitespace buffers between the user text and formatted text, and emit linter
    /// errors accordingly.
    ///
    /// Note: properly formatted whitespace will always be some number of newline characters
    /// followed by some number of spaces in the absence of trailing whitespace (which the
    /// pretty-printer ensures). e.g. "\n ", "\n\n ", "\n", " ". The user's whitespace could have
    /// spaces and newlines in any order. e.g. " \n ", " \n", etc.
    ///
    /// - Parameters:
    ///   - userWhitespace: The byte range of the current span of contiguous whitespace in the user
    ///     text.
    ///   - formattedWhitespace: The byte range of the matching span of contiguous whitespace in the
    ///     formatted text.
    @_lifetime(self: copy self)
    private mutating func compareWhitespace(
        userWhitespace: Range<Int>,
        formattedWhitespace: Range<Int>
    ) {
        // The runs are the newline-separated parts of each whitespace span. `RunIterator` finds
        // them lazily and allocates no storage. The counts are computed first, in one pass.
        let userRunCount = runCount(of: userWhitespace, in: user)
        let formattedRunCount = runCount(of: formattedWhitespace, in: formatted)

        checkForLineLengthErrors(
            userWhitespace: userWhitespace,
            formattedWhitespace: formattedWhitespace,
            userRunCount: userRunCount,
            formattedRunCount: formattedRunCount
        )

        // No need to perform any further checks if the whitespace is identical.
        guard !bytesEqual(userWhitespace, formattedWhitespace) else { return }

        var userIndex = userWhitespace.lowerBound
        var userRuns = RunIterator(userWhitespace)
        var formattedRuns = RunIterator(formattedWhitespace)

        if userRunCount == 1, formattedRunCount == 1 {
            // If there was only a single whitespace run in each input, then that means there
            // weren't any newlines. Therefore, we're looking at inter-token spacing, unless the
            // whitespace runs preceded the first token in the file (i.e., offset == 0), in which
            // case we ignore it here and handle it as an indentation check below.
            if let userRun = userRuns.next(in: user),
               let formattedRun = formattedRuns.next(in: formatted),
               userIndex > 0
            {
                checkForSpacingErrors(
                    userIndex: userIndex,
                    userRun: userRun,
                    formattedRun: formattedRun
                )
            }
        } else {
            var runIndex = 0
            let excessUserLines = userRunCount - formattedRunCount

            while let userRun = userRuns.next(in: user) {
                let possibleFormattedRun = formattedRuns.next(in: formatted)

                if runIndex < excessUserLines {
                    // If there were excess newlines in the user input, tell the user to remove
                    // them. This short-circuits the trailing whitespace check below; we don't
                    // bother telling the user about trailing whitespace on a line that we're also
                    // telling them to delete.
                    diagnose(.removeLineError, category: .removeLine, utf8Offset: userIndex)
                    userIndex += userRun.count + 1
                } else if runIndex != userRunCount - 1 {
                    if let formattedRun = possibleFormattedRun {
                        // If this isn't the last whitespace run, then it must precede a newline, so
                        // we check for trailing whitespace violations.
                        checkForTrailingWhitespaceErrors(
                            userIndex: userIndex,
                            userRun: userRun,
                            formattedRun: formattedRun
                        )
                    }
                    userIndex += userRun.count + 1
                }
                runIndex += 1
            }
        }

        if userIndex == 0 || (userRunCount > 1 && formattedRunCount > 1) {
            // Advance to the last formatted whitespace run if we haven't already. This run precedes
            // a token, so we check it for leading indentation violations.
            while formattedRuns.next(in: formatted) != nil {}

            if let lastFormattedRun = formattedRuns.latestRun,
               let lastUserRun = userRuns.latestRun
            {
                checkForIndentationErrors(
                    userIndex: userIndex,
                    userRun: lastUserRun,
                    formattedRun: lastFormattedRun
                )
            }
        }

        // If there were more lines in the formatted output and the user's line did not exceed the
        // line length limit, tell the user to add the necessary blank lines.
        let excessFormattedLines = formattedRunCount - userRunCount

        if excessFormattedLines > 0, !isLineTooLong {
            diagnose(
                .addLinesError(excessFormattedLines),
                category: .addLines,
                utf8Offset: userWhitespace.lowerBound
            )
        }
    }

    /// Check the user text for line length violations.
    ///
    /// - Parameters:
    ///   - userWhitespace: The byte range of the current whitespace span in the user text.
    ///   - formattedWhitespace: The byte range of the current whitespace span in the formatted
    ///     text.
    ///   - userRunCount: The number of newline-separated runs in `userWhitespace` .
    ///   - formattedRunCount: The number of newline-separated runs in `formattedWhitespace` .
    @_lifetime(self: copy self)
    private mutating func checkForLineLengthErrors(
        userWhitespace: Range<Int>,
        formattedWhitespace: Range<Int>,
        userRunCount: Int,
        formattedRunCount: Int
    ) {
        // Only run this check at the start of a line.
        guard (userRunCount > 1 && formattedRunCount > 1)
            || (userRunCount == 1 && formattedRunCount == 1 && userWhitespace.lowerBound == 0)
        else { return }

        // Move the offset to the first byte of the last run, which is the indentation of the line.
        let lastUserRun = lastRun(of: userWhitespace, in: user)
        let adjustedUserIndex = lastUserRun.lowerBound

        // Calculate the length of the user's line.
        let userLength = lastUserRun.count + distanceToNewline(from: adjustedUserIndex, in: user)

        // Exit if the user's line is within limits
        if userLength <= lineLength {
            isLineTooLong = false
            return
        }

        // Calculate the length of the formatted line.
        let lastFormattedRun = lastRun(of: formattedWhitespace, in: formatted)
        let formattedLength = lastFormattedRun.count
            + distanceToNewline(from: lastFormattedRun.lowerBound, in: formatted)

        // If the formatted text produces a line that is too long, don't raise an error.
        if formattedLength > lineLength {
            isLineTooLong = false
            return
        }

        isLineTooLong = true
        diagnose(.lineLengthError, category: .lineLength, utf8Offset: adjustedUserIndex)
    }

    /// Compare user and formatted whitespace buffers, and check for indentation errors.
    ///
    /// Example:
    ///
    /// func myFun() { let a = 123 // Indentation error on this line }
    ///
    /// - Parameters:
    ///   - userIndex: The current character offset within the user text.
    ///   - userRun: A run of whitespace from the user text.
    ///   - formattedRun: A run of whitespace from the formatted text.
    private func checkForIndentationErrors(
        userIndex: Int,
        userRun: Range<Int>,
        formattedRun: Range<Int>
    ) {
        guard !bytesEqual(userRun, formattedRun) else { return }

        let actual = indentation(of: userRun, in: user)
        let expected = indentation(of: formattedRun, in: formatted)
        diagnose(
            .indentationError(expected: expected, actual: actual),
            category: .indentation,
            utf8Offset: userIndex
        )
    }

    /// Compare user and formatted whitespace buffers, and check for trailing whitespace.
    ///
    /// - Parameters:
    ///   - userIndex: The current character offset within the user text.
    ///   - userRun: The tokenized user whitespace buffer.
    ///   - formattedRun: The tokenized formatted whitespace buffer.
    private func checkForTrailingWhitespaceErrors(
        userIndex: Int,
        userRun: Range<Int>,
        formattedRun: Range<Int>
    ) {
        if !bytesEqual(userRun, formattedRun) {
            diagnose(.trailingWhitespaceError, category: .trailingWhitespace, utf8Offset: userIndex)
        }
    }

    /// Compare user and formatted whitespace buffers, and check for spacing errors.
    ///
    /// Example:
    ///
    /// let a : Int = 123 // Spacing error before the colon
    ///
    /// - Parameters:
    ///   - userIndex: The current character offset within the user text.
    ///   - userRun: The tokenized user whitespace buffer.
    ///   - formattedRun: The tokenized formatted whitespace buffer.
    private func checkForSpacingErrors(
        userIndex: Int,
        userRun: Range<Int>,
        formattedRun: Range<Int>
    ) {
        guard !bytesEqual(userRun, formattedRun) else { return }

        // This assumes tabs will always be forbidden for inter-token spacing (but not for leading
        // indentation).
        if contains(utf8Tab, in: userRun, of: user) {
            diagnose(.spacingCharError, category: .spacingCharacter, utf8Offset: userIndex)
        } else if formattedRun.count != userRun.count {
            let delta = formattedRun.count - userRun.count
            diagnose(.spacingError(delta), category: .spacing, utf8Offset: userIndex)
        }
    }

    /// Returns `true` when the user bytes in `userRange` equal the formatted bytes in
    /// `formattedRange` .
    private func bytesEqual(_ userRange: Range<Int>, _ formattedRange: Range<Int>) -> Bool {
        guard userRange.count == formattedRange.count else { return false }
        var formattedIndex = formattedRange.lowerBound

        for userIndex in userRange {
            if user[userIndex] != formatted[formattedIndex] { return false }
            formattedIndex += 1
        }
        return true
    }

    /// Emits a finding with the given message and category. The message will correspond to a
    /// specific location (line and column number) in the input Swift source file.
    ///
    /// - Parameters:
    ///   - message: The message we wish to emit.
    ///   - category: The category of the finding.
    ///   - utf8Offset: The UTF-8 offset location of the message.
    private func diagnose(
        _ message: Finding.Message,
        category: WhitespaceFindingCategory,
        utf8Offset: Int
    ) {
        let absolutePosition = AbsolutePosition(utf8Offset: utf8Offset)
        let sourceLocation = context.sourceLocationConverter.location(for: absolutePosition)

        context.findingEmitter.emit(
            message,
            category: category,
            location: Finding.Location(sourceLocation)
        )
    }
}

/// Finds the newline-separated runs of one whitespace range, one run for each call.
///
/// The iterator holds only byte offsets. Each call takes the bytes as an argument, so the iterator
/// does not borrow them and needs no lifetime.
private struct RunIterator {
    /// The start offset of the current run.
    private var runStart: Int

    /// The offset that the search has reached.
    private var position: Int

    /// The end offset of the whitespace range.
    private let end: Int

    /// Indicates whether the last run has been returned.
    private var done = false

    /// The run most recently returned by `next(in:)` . It keeps its value after the iterator is
    /// exhausted. It is `nil` only if `next(in:)` has returned no run.
    private(set) var latestRun: Range<Int>?

    init(_ range: Range<Int>) {
        runStart = range.lowerBound
        position = range.lowerBound
        end = range.upperBound
    }

    /// Returns the next run of the range, or `nil` after the last run.
    mutating func next(in bytes: Span<UInt8>) -> Range<Int>? {
        while position != end {
            if bytes[position] == utf8Newline {
                let run = runStart..<position
                position += 1
                runStart = position
                latestRun = run
                return run
            }
            position += 1
        }

        guard !done else { return nil }
        done = true
        let run = runStart..<end
        latestRun = run
        return run
    }
}

/// Returns the byte range of the contiguous whitespace that starts at the given offset.
///
/// - Parameters:
///   - offset: The byte offset where the whitespace starts.
///   - bytes: The UTF-8 bytes of the text.
private func contiguousWhitespace(startingAt offset: Int, in bytes: Span<UInt8>) -> Range<Int> {
    var end = offset
    while end < bytes.count, bytes[end].isWhitespace { end += 1 }
    return offset..<end
}

/// Returns the number of newline-separated runs in the range. The count is one more than the
/// number of newlines.
private func runCount(of range: Range<Int>, in bytes: Span<UInt8>) -> Int {
    var count = 1
    for index in range where bytes[index] == utf8Newline { count += 1 }
    return count
}

/// Returns the last newline-separated run of the range.
private func lastRun(of range: Range<Int>, in bytes: Span<UInt8>) -> Range<Int> {
    var start = range.upperBound
    while start > range.lowerBound, bytes[start - 1] != utf8Newline { start -= 1 }
    return start..<range.upperBound
}

/// Returns the number of bytes from the offset to the next newline or to the end of the text.
private func distanceToNewline(from offset: Int, in bytes: Span<UInt8>) -> Int {
    var index = offset
    while index < bytes.count, bytes[index] != utf8Newline { index += 1 }
    return index - offset
}

/// Returns `true` when the range of the bytes contains the given code unit.
private func contains(_ codeUnit: UInt8, in range: Range<Int>, of bytes: Span<UInt8>) -> Bool {
    for index in range where bytes[index] == codeUnit { return true }
    return false
}

/// Returns the code unit at the given index, or nil if the index is the end of the data.
///
/// This helper is only used in an assertion that verifies that the non-whitespace code units in
/// the text are identical, but is not evaluated in release builds.
private func safeCodeUnit(at index: Int, in bytes: Span<UInt8>) -> UTF8.CodeUnit? {
    index != bytes.count ? bytes[index] : nil
}

/// Returns the indentation that represents the indentation of the given whitespace, which is the
/// leading spacing for a line.
private func indentation(of whitespace: Range<Int>, in bytes: Span<UInt8>) -> WhitespaceIndentation {
    if whitespace.isEmpty { return .none }

    var orderedRuns: [(char: UTF8.CodeUnit, count: Int)] = []

    for index in whitespace {
        let char = bytes[index]

        if orderedRuns.last?.char == char {
            orderedRuns[orderedRuns.endIndex - 1].count += 1
        } else {
            orderedRuns.append((char, 1))
        }
    }

    let indents = orderedRuns.map { run in
        // Assumes any non-tab whitespace character is some type of space.
        run.char == utf8Tab ? Indent.tabs(run.count) : Indent.spaces(run.count)
    }
    if indents.count == 1, let onlyIndent = indents.first { return .homogeneous(onlyIndent) }

    return .heterogeneous(indents)
}

// MARK: - Support

/// Describes the composition of the whitespace that creates an indentation for a line of code.
enum WhitespaceIndentation: Equatable {
    /// The line has no preceding whitespace, meaning there's no indentation.
    case none

    /// The line's leading whitespace consists of a single run of one kind of whitespace character.
    case homogeneous(Indent)

    /// The line's leading whitespace consists of multiple runs of different kinds of whitespace
    /// characters.
    case heterogeneous([Indent])
}

fileprivate extension Indent {
    /// Returns a string that describes the indentation in a human readable format, which is
    /// appropriate for use in diagnostic messages.
    var diagnosticDescription: String {
        switch self {
            case let .spaces(count):
                let noun = count == 1 ? "space" : "spaces"
                return "\(count) \(noun)"
            case let .tabs(count):
                let noun = count == 1 ? "tab" : "tabs"
                return "\(count) \(noun)"
        }
    }
}

fileprivate extension WhitespaceIndentation {
    /// Returns a string that describes the whitespace in a human readable format, which is
    /// appropriate for use in diagnostic messages.
    var diagnosticDescription: String {
        switch self {
            case .none: return "no indentation"
            case let .heterogeneous(indents):
                guard let first = indents.first else { return "no indentation" }
                var description = first.diagnosticDescription

                for i in 1..<indents.count {
                    description += ", " + indents[i].diagnosticDescription
                }
                return description
            case let .homogeneous(indent): return indent.diagnosticDescription
        }
    }
}

fileprivate extension Finding.Message {
    static let trailingWhitespaceError: Finding.Message = "remove trailing whitespace"

    static func indentationError(
        expected expectedIndentation: WhitespaceIndentation,
        actual actualIndentation: WhitespaceIndentation
    ) -> Finding.Message {
        switch expectedIndentation {
            case .none: return "remove all leading whitespace"
            case .homogeneous, .heterogeneous:
                if case let .homogeneous(expectedIndent) = expectedIndentation,
                   case let .homogeneous(actualIndent) = actualIndentation
                {
                    if case let .spaces(expectedCount) = expectedIndent,
                       case let .spaces(actualCount) = actualIndent
                    {
                        let delta = expectedCount - actualCount
                        let verb = delta > 0 ? "indent" : "unindent"
                        return "\(verb) by \(abs(delta)) spaces"
                    }
                    if case let .tabs(expectedCount) = expectedIndent,
                       case let .tabs(actualCount) = actualIndent
                    {
                        let delta = expectedCount - actualCount
                        let verb = delta > 0 ? "indent" : "unindent"
                        return "\(verb) by \(abs(delta)) tabs"
                    }
                    // Intentionally fall-through to the heterogeneous indentation diagnostic below.
                }
                // Otherwise, the change can't be described by a simple add/remove N spaces/tabs.
                // It's easier to instruct the user to remove the existing whitespace and add the
                // appropriate sequence of indenting characters.
                let expectedDescription = expectedIndentation.diagnosticDescription

                return "replace leading whitespace with \(expectedDescription)"
        }
    }

    static func spacingError(_ spaces: Int) -> Finding.Message {
        let verb = spaces > 0 ? "add" : "remove"
        let noun = abs(spaces) == 1 ? "space" : "spaces"
        return "\(verb) \(abs(spaces)) \(noun)"
    }

    static let spacingCharError: Finding.Message = "use spaces for spacing"

    static let removeLineError: Finding.Message = "remove line break"

    static func addLinesError(_ lines: Int) -> Finding.Message {
        let noun = lines == 1 ? "break" : "breaks"
        return "add \(lines) line \(noun)"
    }

    static let lineLengthError: Finding.Message = "line is too long"
}
