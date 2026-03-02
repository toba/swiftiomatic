struct LineLengthConfiguration: RuleConfiguration {
    let id = "line_length"
    let name = "Line Length"
    let summary = "Lines should not span too many characters."
    var nonTriggeringExamples: [Example] {
        [
              Example(String(repeating: "/", count: 120) + ""),
              Example(
                String(
                  repeating:
                    "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
                  count: 120,
                ) + "",
              ),
              Example(String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 120) + ""),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(String(repeating: "/", count: 121) + ""),
              Example(
                String(
                  repeating:
                    "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
                  count: 121,
                ) + "",
              ),
              Example(String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 121) + ""),
            ]
    }
}
