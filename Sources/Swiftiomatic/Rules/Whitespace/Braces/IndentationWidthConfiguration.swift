struct IndentationWidthConfiguration: RuleConfiguration {
    let id = "indentation_width"
    let name = "Indentation Width"
    let summary = "Indent code using either one tab or the configured amount of spaces, unindent to match previous indentations. Don't indent the first line."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("firstLine\nsecondLine"),
              Example("firstLine\n    secondLine"),
              Example("firstLine\n\tsecondLine\n\t\tthirdLine\n\n\t\tfourthLine"),
              Example("firstLine\n\tsecondLine\n\t\tthirdLine\n\t//test\n\t\tfourthLine"),
              Example("firstLine\n    secondLine\n        thirdLine\nfourthLine"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓    firstLine", shouldTestMultiByteOffsets: false, shouldTestDisableCommand: false),
              Example("firstLine\n        secondLine"),
              Example("firstLine\n\tsecondLine\n\n↓\t\t\tfourthLine"),
              Example("firstLine\n    secondLine\n        thirdLine\n↓ fourthLine"),
            ]
    }
}
