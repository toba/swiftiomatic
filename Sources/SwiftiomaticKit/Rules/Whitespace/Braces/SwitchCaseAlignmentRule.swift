import SwiftiomaticSyntax

struct SwitchCaseAlignmentRule {
    static let id = "switch_case_alignment"
    static let name = "Switch and Case Statement Alignment"
    static let summary = "Case statements should vertically align with their enclosing switch's closing brace"
    static let scope: Scope = .format
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        Examples(indentedCases: false).nonTriggeringExamples + [
            Example(
                """
                extension OSLogFloatFormatting {
                  /// Returns a fprintf-compatible length modifier for a given argument type
                  @_semantics("constant_evaluable")
                  @inlinable
                  @_optimize(none)
                  internal static func _formatStringLengthModifier<I: FloatingPoint>(
                    _ type: I.Type
                  ) -> String? {
                    switch type {
                    //   fprintf formatters promote Float to Double
                    case is Float.Type: return ""
                    case is Double.Type: return ""
                #if !os(Windows) && (arch(i386) || arch(x86_64))
                    //   fprintf formatters use L for Float80
                    case is Float80.Type: return "L"
                #endif
                    default: return nil
                    }
                  }
                }
                """, isExcludedFromDocumentation: true,
            )
        ]
    }

    static var triggeringExamples: [Example] {
        Examples(indentedCases: false).triggeringExamples
    }

    static var corrections: [Example: Example] {
        Examples(indentedCases: false).corrections
    }

    struct Examples {
        private let indentedCasesOption: Bool
        private let violationMarker = "↓"

        init(indentedCases: Bool) {
            indentedCasesOption = indentedCases
        }

        var triggeringExamples: [Example] {
            (indentedCasesOption ? nonIndentedCases : indentedCases)
                + invalidCases
                + invalidOneLiners
        }

        var nonTriggeringExamples: [Example] {
            indentedCasesOption ? indentedCases : nonIndentedCases + validOneLiners
        }

        var corrections: [Example: Example] {
            // Cases indented one level too deep → aligned with closing brace
            [
                Example(
                    """
                    switch someBool {
                        ↓case true:
                            print("red")
                        ↓case false:
                            print("blue")
                    }
                    """
                ): Example(
                    """
                    switch someBool {
                    case true:
                            print("red")
                    case false:
                            print("blue")
                    }
                    """
                ),
                Example(
                    """
                    switch someBool {
                    case true:
                        print('red')
                        ↓case false:
                            print('blue')
                    }
                    """
                ): Example(
                    """
                    switch someBool {
                    case true:
                        print('red')
                    case false:
                            print('blue')
                    }
                    """
                ),
            ]
        }

        private var indentedCases: [Example] {
            let violationMarker = indentedCasesOption ? "" : violationMarker

            return [
                Example(
                    """
                    switch someBool {
                        \(violationMarker)case true:
                            print("red")
                        \(violationMarker)case false:
                            print("blue")
                    }
                    """,
                ),
                Example(
                    """
                    if aBool {
                        switch someBool {
                            \(violationMarker)case true:
                                print('red')
                            \(violationMarker)case false:
                                print('blue')
                        }
                    }
                    """,
                ),
                Example(
                    """
                    switch someInt {
                        \(violationMarker)case 0:
                            print('Zero')
                        \(violationMarker)case 1:
                            print('One')
                        \(violationMarker)default:
                            print('Some other number')
                    }
                    """,
                ),
                Example(
                    """
                    let a = switch i {
                        \(violationMarker)case 1: 1
                        \(violationMarker)default: 2
                    }
                    """,
                ),
            ]
        }

        private var nonIndentedCases: [Example] {
            let violationMarker = indentedCasesOption ? violationMarker : ""

            return [
                Example(
                    """
                    switch someBool {
                    \(violationMarker)case true: // case 1
                        print('red')
                    \(violationMarker)case false:
                        /*
                        case 2
                        */
                        if case let .someEnum(val) = someFunc() {
                            print('blue')
                        }
                    }
                    enum SomeEnum {
                        case innocent
                    }
                    """,
                ),
                Example(
                    """
                    if aBool {
                        switch someBool {
                        \(violationMarker)case true:
                            print('red')
                        \(violationMarker)case false:
                            print('blue')
                        }
                    }
                    """,
                ),
                Example(
                    """
                    switch someInt {
                    // comments ignored
                    \(violationMarker)case 0:
                        // zero case
                        print('Zero')
                    \(violationMarker)case 1:
                        print('One')
                    \(violationMarker)default:
                        print('Some other number')
                    }
                    """,
                ),
                Example(
                    """
                    func f() -> Int {
                        return switch i {
                        \(violationMarker)case 1: 1
                        \(violationMarker)default: 2
                        }
                    }
                    """,
                ),
            ]
        }

        private var invalidCases: [Example] {
            let indentation = indentedCasesOption ? "    " : ""

            return [
                Example(
                    """
                    switch someBool {
                    \(indentation)case true:
                        \(indentation)print('red')
                        \(indentation)\(violationMarker)case false:
                            \(indentation)print('blue')
                    }
                    """,
                ),
                Example(
                    """
                    if aBool {
                        switch someBool {
                            \(indentation)\(indentedCasesOption ? "" : violationMarker)case true:
                            \(indentation)print('red')
                        \(indentation)\(indentedCasesOption ? violationMarker : "")case false:
                        \(indentation)print('blue')
                        }
                    }
                    """,
                ),
                Example(
                    """
                    let a = switch i {
                    \(indentation)case 1: 1
                        \(indentation)\(indentedCasesOption ? "" : violationMarker)default: 2
                    }
                    """,
                ),
            ]
        }

        private var validOneLiners: [Example] = [
            Example(
                "switch i { case .x: 1 default: 0 }",
                configuration: ["ignore_one_liners": true],
            ),
            Example(
                "let a = switch i { case .x: 1 default: 0 }",
                configuration: ["ignore_one_liners": true],
            ),
        ]

        private var invalidOneLiners: [Example] {
            [
                // Default configuration should not ignore one liners
                Example(
                    "switch i { \(violationMarker)case .x: 1 \(violationMarker)default: 0 }",
                ),
                Example(
                    """
                    switch i {
                    \(violationMarker)case .x: 1 \(violationMarker)default: 0 }
                    """, configuration: ["ignore_one_liners": true],
                ),
                Example(
                    """
                    switch i { \(violationMarker)case .x: 1 \(violationMarker)default: 0
                    }
                    """, configuration: ["ignore_one_liners": true],
                ),
                Example(
                    """
                    switch i
                    { \(violationMarker)case .x: 1 \(violationMarker)default: 0 }
                    """, configuration: ["ignore_one_liners": true],
                ),
                Example(
                    """
                    let a = switch i {
                    case .x: 1 \(violationMarker)default: 0
                    }
                    """, configuration: ["ignore_one_liners": true],
                ),
                Example(
                    """
                    let a = switch i {
                    \(violationMarker)case .x: 1 \(violationMarker)default: 0 }
                    """, configuration: ["ignore_one_liners": true],
                ),
            ]
        }
    }

    var options = SwitchCaseAlignmentOptions()
}

extension SwitchCaseAlignmentRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension SwitchCaseAlignmentRule {
    final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: SwitchExprSyntax) {
            guard node.cases.isNotEmpty,
                let firstCasePosition = node.cases.first?.positionAfterSkippingLeadingTrivia
            else {
                return
            }

            let closingBracePosition = node.rightBrace.positionAfterSkippingLeadingTrivia
            let closingBraceLocation = locationConverter.location(for: closingBracePosition)
            let switchKeywordPosition = node.switchKeyword.positionAfterSkippingLeadingTrivia
            let switchKeywordLocation = locationConverter.location(for: switchKeywordPosition)

            if configuration.ignoreOneLiners,
                switchKeywordLocation.line == closingBraceLocation.line
            {
                return
            }

            let closingBraceColumn = closingBraceLocation.column
            let firstCaseColumn = locationConverter.location(for: firstCasePosition).column

            for `case` in node.cases where `case`.is(SwitchCaseSyntax.self) {
                let casePosition = `case`.positionAfterSkippingLeadingTrivia
                let caseColumn = locationConverter.location(for: casePosition).column

                let hasViolation =
                    (configuration.indentedCases && caseColumn <= closingBraceColumn)
                    || (!configuration.indentedCases && caseColumn != closingBraceColumn)
                    || (configuration.indentedCases && caseColumn != firstCaseColumn)

                guard hasViolation else {
                    continue
                }

                let reason = """
                    Case statements should \
                    \(configuration.indentedCases ? "be indented within" : "vertically aligned with") \
                    their closing brace
                    """

                violations.append(SyntaxViolation(position: casePosition, reason: reason))
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            guard node.cases.isNotEmpty else {
                return super.visit(node)
            }

            let closingBracePosition = node.rightBrace.positionAfterSkippingLeadingTrivia
            let closingBraceLocation = locationConverter.location(for: closingBracePosition)
            let switchKeywordPosition = node.switchKeyword.positionAfterSkippingLeadingTrivia
            let switchKeywordLocation = locationConverter.location(for: switchKeywordPosition)

            if configuration.ignoreOneLiners,
                switchKeywordLocation.line == closingBraceLocation.line
            {
                return super.visit(node)
            }

            let targetColumn = configuration.indentedCases
                ? closingBraceLocation.column + 4
                : closingBraceLocation.column

            var newCases = node.cases
            for (index, `case`) in node.cases.enumerated() {
                guard let switchCase = `case`.as(SwitchCaseSyntax.self) else { continue }
                let casePosition = switchCase.positionAfterSkippingLeadingTrivia
                let caseColumn = locationConverter.location(for: casePosition).column

                let hasViolation =
                    (configuration.indentedCases && caseColumn <= closingBraceLocation.column)
                    || (!configuration.indentedCases && caseColumn != closingBraceLocation.column)
                    || (configuration.indentedCases && caseColumn != targetColumn)

                guard hasViolation else { continue }

                let leadingTrivia = switchCase.leadingTrivia
                let corrected = replaceIndentation(in: leadingTrivia, targetColumn: targetColumn)
                let caseIndex = node.cases.index(node.cases.startIndex, offsetBy: index)
                newCases[caseIndex] = SwitchCaseListSyntax.Element(
                    switchCase.with(\.leadingTrivia, corrected)
                )
                numberOfCorrections += 1
            }

            if numberOfCorrections > 0 {
                return super.visit(ExprSyntax(node.with(\.cases, newCases)))
            }
            return super.visit(node)
        }

        private func replaceIndentation(in trivia: Trivia, targetColumn: Int) -> Trivia {
            var pieces = Array(trivia.pieces)
            // Find the last newline and replace everything after it with correct indentation
            if let lastNewlineIndex = pieces.lastIndex(where: {
                if case .newlines = $0 { return true }
                if case .carriageReturns = $0 { return true }
                if case .carriageReturnLineFeeds = $0 { return true }
                return false
            }) {
                // Remove all whitespace pieces after the last newline
                let afterNewline = lastNewlineIndex + 1
                pieces.removeSubrange(afterNewline...)
                // Add correct indentation (target column is 1-based)
                if targetColumn > 1 {
                    pieces.append(.spaces(targetColumn - 1))
                }
            }
            return Trivia(pieces: pieces)
        }
    }
}

