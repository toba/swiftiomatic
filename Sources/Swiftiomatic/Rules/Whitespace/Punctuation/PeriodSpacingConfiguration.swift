struct PeriodSpacingConfiguration: RuleConfiguration {
    let id = "period_spacing"
    let name = "Period Spacing"
    let summary = "Periods should not be followed by more than one space"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let pi = 3.2"),
              Example("let pi = Double.pi"),
              Example("let pi = Double. pi"),
              Example("let pi = Double.  pi"),
              Example("// A. Single."),
              Example("///   - code: Identifier of the error. Integer."),
              Example(
                """
                // value: Multiline.
                //        Comment.
                """,
              ),
              Example(
                """
                /**
                Sentence ended in period.

                - Sentence 2 new line characters after.
                **/
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                "/* Only god knows why. ↓ This symbol does nothing. */",
                shouldTestWrappingInComment: false,
              ),
              Example(
                "// Only god knows why. ↓ This symbol does nothing.",
                shouldTestWrappingInComment: false,
              ),
              Example("// Single. Double. ↓ End.", shouldTestWrappingInComment: false),
              Example("// Single. Double. ↓ Triple. ↓  End.", shouldTestWrappingInComment: false),
              Example("// Triple. ↓  Quad. ↓   End.", shouldTestWrappingInComment: false),
              Example(
                "///   - code: Identifier of the error. ↓ Integer.",
                shouldTestWrappingInComment: false,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("/* Why. ↓ Symbol does nothing. */"): Example(
                "/* Why. Symbol does nothing. */",
              ),
              Example("// Why. ↓ Symbol does nothing."): Example("// Why. Symbol does nothing."),
              Example("// Single. Double. ↓ End."): Example("// Single. Double. End."),
              Example("// Single. Double. ↓ Triple. ↓  End."): Example(
                "// Single. Double. Triple. End.",
              ),
              Example("// Triple. ↓  Quad. ↓   End."): Example("// Triple. Quad. End."),
              Example("///   - code: Identifier. ↓ Integer."): Example(
                "///   - code: Identifier. Integer.",
              ),
            ]
    }
}
