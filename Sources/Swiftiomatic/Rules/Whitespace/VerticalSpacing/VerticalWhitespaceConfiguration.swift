struct VerticalWhitespaceConfiguration: RuleConfiguration {
    let id = "vertical_whitespace"
    let name = "Vertical Whitespace"
    let summary = "Limit vertical whitespace to a single empty line"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let abc = 0\n"),
              Example("let abc = 0\n\n"),
              Example("/* bcs \n\n\n\n*/"),
              Example("// bca \n\n"),
              Example("class CCCC {\n  \n}"),
              Example(
                """
                // comment

                import Foundation
                """,
              ),
              Example(
                """

                // comment

                import Foundation
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let aaaa = 0\n\n\n"),
              Example("struct AAAA {}\n\n\n\n"),
              Example("class BBBB {}\n\n\n"),
              Example("class CCCC {\n  \n  \n}"),
              Example(
                """


                import Foundation
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let b = 0\n\n\nclass AAA {}\n"): Example("let b = 0\n\nclass AAA {}\n"),
              Example("let c = 0\n\n\nlet num = 1\n"): Example("let c = 0\n\nlet num = 1\n"),
              Example("// bca \n\n\n"): Example("// bca \n\n"),
              Example("class CCCC {\n  \n  \n  \n}"): Example("class CCCC {\n  \n}"),
            ]
    }
}
