import Foundation
import SwiftSyntax

struct MarkRule {
    static let id = "mark"
    static let name = "Mark"
    static let summary =
        "MARK comment should be in valid format. e.g. '// MARK: ...' or '// MARK: - ...'"
    static let isCorrectable = true
    var options = SeverityOption<Self>(.warning)
}

extension MarkRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension MarkRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: TokenSyntax) {
            for result in node.violationResults() {
                violations.append(result.position)
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ token: TokenSyntax) -> TokenSyntax {
            var pieces = token.leadingTrivia.pieces
            for result in token.violationResults() {
                numberOfCorrections += 1
                result.correct(&pieces)
            }
            return super.visit(token.with(\.leadingTrivia, Trivia(pieces: pieces)))
        }
    }
}

private struct ViolationResult {
    let position: AbsolutePosition
    let correct: (inout [TriviaPiece]) -> Void
}

extension TokenSyntax {
    private enum Mark {
        static func lint(in text: String) -> [() -> String] {
            regex(badPattern).matches(in: text, range: text.fullNSRange).compactMap { match in
                let matchNSRange = NSRange(match.range, in: text)
                if isIgnoredCases(text, range: matchNSRange) { return nil }
                let group1Range: NSRange =
                    match.output[1].substring.map {
                        NSRange($0.startIndex ..< $0.endIndex, in: text)
                    } ?? NSRange(location: NSNotFound, length: 0)
                let group2Range: NSRange =
                    match.output[2].substring.map {
                        NSRange($0.startIndex ..< $0.endIndex, in: text)
                    } ?? NSRange(location: NSNotFound, length: 0)
                return {
                    var corrected = replace(text, range: group2Range, to: "- ")
                    corrected = replace(corrected, range: group1Range, to: "// MARK: ")
                    if !text.hasSuffix(" "), corrected.hasSuffix(" ") {
                        corrected.removeLast()
                    }
                    return corrected
                }
            }
        }

        private static func isIgnoredCases(_ text: String, range: NSRange) -> Bool {
            range.lowerBound != 0
                || regex(goodPattern).firstMatch(in: text, range: text.fullNSRange) != nil
        }

        private static let goodPattern = [
            "^// MARK: \(oneOrMoreHyphen) \(anyText)$",
            "^// MARK: \(oneOrMoreHyphen) ?$",
            "^// MARK: \(nonSpaceOrHyphen)+ ?\(anyText)?$",
            "^// MARK:$",

            // comment start with `Mark ...` is ignored
            "^\(twoOrThreeSlashes) +[Mm]ark[^:]",
        ].map(nonCapturingGroup).joined(separator: "|")

        private static let badPattern =
            capturingGroup(
                [
                    "MARK[^\\s:]",
                    "[Mm]ark",
                    "MARK",
                ].map(basePattern).joined(separator: "|"),
            ) + capturingGroup(hyphenOrEmpty)

        private static let anySpace = " *"

        private static let anyText = "(?:\\S.*)"

        private static let oneOrMoreHyphen = "-+"
        private static let nonSpaceOrHyphen = "[^ -]"

        private static let twoOrThreeSlashes = "///?"
        private static let colonOrEmpty = ":?"
        private static let hyphenOrEmpty = "-? *"

        private static func nonCapturingGroup(_ pattern: String) -> String {
            "(?:\(pattern))"
        }

        private static func capturingGroup(_ pattern: String) -> String {
            "(\(pattern))"
        }

        private static func basePattern(_ pattern: String) -> String {
            nonCapturingGroup(
                "\(twoOrThreeSlashes)\(anySpace)\(pattern)\(anySpace)\(colonOrEmpty)\(anySpace)",
            )
        }

        private static func replace(
            _ target: String,
            range nsrange: NSRange,
            to replaceString: String,
        )
            -> String
        {
            guard nsrange.length > 0, let range = Range(nsrange, in: target) else {
                return target
            }
            return target.replacingCharacters(in: range, with: replaceString)
        }
    }

    fileprivate func violationResults() -> [ViolationResult] {
        var utf8Offset = 0
        var results: [ViolationResult] = []

        for index in leadingTrivia.pieces.indices {
            let piece = leadingTrivia.pieces[index]
            defer { utf8Offset += piece.sourceLength.utf8Length }

            switch piece {
                case let .lineComment(comment), let .docLineComment(comment):
                    for correct in Mark.lint(in: comment) {
                        let position = position.advanced(by: utf8Offset)
                        results.append(
                            ViolationResult(position: position) { pieces in
                                pieces[index] = .lineComment(correct())
                            },
                        )
                    }

                default:
                    break
            }
        }

        return results
    }
}
