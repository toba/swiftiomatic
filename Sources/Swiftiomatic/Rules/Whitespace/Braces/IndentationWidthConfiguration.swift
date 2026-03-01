struct IndentationWidthConfiguration: RuleConfiguration {
    let id = "indentation_width"
    let name = "Indentation Width"
    let summary = "Indent code using either one tab or the configured amount of spaces, unindent to match previous indentations. Don't indent the first line."
    let isOptIn = true
}
