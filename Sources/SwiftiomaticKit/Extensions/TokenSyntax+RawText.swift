import Foundation
@_spi(RawSyntax) import SwiftSyntax

// This file holds every `@_spi(RawSyntax)` use in the rule code. Other files must not import the
// SPI. They call the helpers below.
//
// Why: `TokenSyntax.text` builds a new `String` on each call. The `String` allocates when the text
// is longer than 15 bytes. `rawText` gives the token bytes in the syntax arena as a borrowed
// `SyntaxText`, so a compare against a literal allocates nothing.
//
// Risk: `rawText` and `SyntaxText` are SPI. swift-syntax can change or remove them in a release
// without notice. The compare semantics are the same as `text`: both give the token text as
// written, backticks included, with no trivia.
//
// `withUTF8Buffer` is used in place of `SyntaxText(StaticString)`, because a one-scalar literal
// such as `"!"` can have no pointer representation, and `utf8Start` traps for it.
//
// Migration path: if a swift-syntax update breaks this file, change the bodies below to compare
// `text` with `literal.description`. The call sites do not change. If swift-syntax makes a public
// borrowed-text API, move the bodies to that API.

extension TokenSyntax {
    /// Tells if the token text, without trivia, is equal to `literal`.
    ///
    /// The result is the same as `text == "literal"`, but the compare allocates no `String`.
    @inline(__always)
    func hasText(_ literal: StaticString) -> Bool {
        literal.withUTF8Buffer { unsafe rawText == SyntaxText(baseAddress: $0.baseAddress, count: $0.count) }
    }

    /// Tells if the token text, without trivia, starts with `literal`.
    ///
    /// The result is the same as `text.hasPrefix("literal")`, but the compare allocates no
    /// `String`.
    @inline(__always)
    func hasTextPrefix(_ literal: StaticString) -> Bool {
        literal.withUTF8Buffer {
            unsafe rawText.hasPrefix(SyntaxText(baseAddress: $0.baseAddress, count: $0.count))
        }
    }
}

extension SyntaxProtocol {
    /// Tells if `description.contains("\n")` is true, but builds no `String`.
    ///
    /// The scan reads the source bytes of the node, trivia included, in place.
    func descriptionContainsLineFeed() -> Bool {
        rawTextContainsLineFeed(skippingLeading: 0, skippingTrailing: 0)
    }

    /// Tells if `trimmedDescription.contains("\n")` is true, but builds no `String`.
    ///
    /// The scan skips the leading trivia of the first token and the trailing trivia of the last
    /// token, as `trimmedDescription` does.
    func trimmedDescriptionContainsLineFeed() -> Bool {
        rawTextContainsLineFeed(
            skippingLeading: leadingTriviaLength.utf8Length,
            skippingTrailing: trailingTriviaLength.utf8Length
        )
    }

    /// Scans the source bytes between the two skipped ends for a line feed.
    ///
    /// `String.contains("\n")` compares characters. A carriage return and a line feed together
    /// make one character that is not equal to `"\n"`. Thus a line feed counts only when the byte
    /// before it in the scanned range is not a carriage return.
    private func rawTextContainsLineFeed(skippingLeading: Int, skippingTrailing: Int) -> Bool {
        let end = totalLength.utf8Length - skippingTrailing
        guard end > skippingLeading else { return false }
        var offset = 0
        var previous: UInt8 = 0
        var found = false
        var done = false
        raw.withEachSyntaxText { text, _ in
            guard !done else { return }
            for unsafe byte in text {
                defer { offset += 1 }
                guard offset >= skippingLeading else { continue }
                guard offset < end else {
                    done = true
                    return
                }
                if byte == UInt8(ascii: "\n"), previous != UInt8(ascii: "\r") {
                    found = true
                    done = true
                    return
                }
                previous = byte
            }
        }
        return found
    }
}
