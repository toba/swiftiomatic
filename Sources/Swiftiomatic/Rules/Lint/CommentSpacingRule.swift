import Foundation
import SourceKittenFramework
import SwiftIDEUtils

struct CommentSpacingRule: SourceKitFreeRule, SubstitutionCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "comment_spacing",
        name: "Comment Spacing",
        description: "Prefer at least one space after slashes for comments",
        kind: .lint,
        nonTriggeringExamples: [
            Example(
                """
                // This is a comment
                """
            ),
            Example(
                """
                /// Triple slash comment
                """
            ),
            Example(
                """
                // Multiline double-slash
                // comment
                """
            ),
            Example(
                """
                /// Multiline triple-slash
                /// comment
                """
            ),
            Example(
                """
                /// Multiline triple-slash
                ///   - This is indented
                """
            ),
            Example(
                """
                // - MARK: Mark comment
                """
            ),
            Example(
                """
                //: Swift Playground prose section
                """
            ),
            Example(
                """
                ///////////////////////////////////////////////
                // Comment with some lines of slashes boxing it
                ///////////////////////////////////////////////
                """
            ),
            Example(
                """
                //:#localized(key: "SwiftPlaygroundLocalizedProse")
                """
            ),
            Example(
                """
                /* Asterisk comment */
                """
            ),
            Example(
                """
                /*
                    Multiline asterisk comment
                */
                """
            ),
            Example(
                """
                /*:
                    Multiline Swift Playground prose section
                */
                """
            ),
            Example(
                """
                /*#-editable-code Swift Playground editable area*/default/*#-end-editable-code*/
                """
            ),
        ],
        triggeringExamples: [
            Example(
                """
                //↓Something
                """
            ),
            Example(
                """
                //↓MARK
                """
            ),
            Example(
                """
                //↓👨‍👨‍👦‍👦Something
                """
            ),
            Example(
                """
                func a() {
                    //↓This needs refactoring
                    print("Something")
                }
                //↓We should improve above function
                """
            ),
            Example(
                """
                ///↓This is a comment
                """
            ),
            Example(
                """
                /// Multiline triple-slash
                ///↓This line is incorrect, though
                """
            ),
            Example(
                """
                //↓- MARK: Mark comment
                """
            ),
            Example(
                """
                //:↓Swift Playground prose section
                """
            ),
        ],
        corrections: [
            Example("//↓Something"): Example("// Something"),
            Example("//↓- MARK: Mark comment"): Example("// - MARK: Mark comment"),
            Example(
                """
                /// Multiline triple-slash
                ///↓This line is incorrect, though
                """
            ): Example(
                """
                /// Multiline triple-slash
                /// This line is incorrect, though
                """
            ),
            Example(
                """
                func a() {
                    //↓This needs refactoring
                    print("Something")
                }
                //↓We should improve above function
                """
            ): Example(
                """
                func a() {
                    // This needs refactoring
                    print("Something")
                }
                // We should improve above function
                """
            ),
        ]
    )

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        // Find all comment tokens in the file and regex search them for violations
        file.syntaxClassifications
            .filter(\.kind.isComment)
            .map { $0.range.toSourceKittenByteRange() }
            .compactMap { (range: ByteRange) -> [NSRange]? in
                file.stringView
                    .substringWithByteRange(range)
                    .map(StringView.init)
                    .map { commentBody in
                        // Look for 2+ slash characters followed immediately by
                        // a non-colon, non-whitespace character or by a colon
                        // followed by a non-whitespace character other than #
                        regex(#"^(?:\/){2,}+(?:[^\s:]|:[^\s#])"#).matches(in: commentBody, options: .anchored)
                            .compactMap { result in
                                // Set the location to be directly before the first non-slash,
                                // non-whitespace character which was matched
                                file.stringView.byteRangeToNSRange(
                                    ByteRange(
                                        // Safe to mix NSRange offsets with byte offsets here because the regex can't
                                        // contain multi-byte characters
                                        location: ByteCount(range.lowerBound.value + result.range.upperBound - 1),
                                        length: 0
                                    )
                                )
                            }
                    }
            }
            .flatMap(\.self)
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        violationRanges(in: file).map { range in
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }

    func substitution(for violationRange: NSRange, in _: SwiftLintFile) -> (NSRange, String)? {
        (violationRange, " ")
    }
}
