struct DiscouragedObjectLiteralConfiguration: RuleConfiguration {
    let id = "discouraged_object_literal"
    let name = "Discouraged Object Literal"
    let summary = "Prefer initializers over object literals"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let image = UIImage(named: aVariable)"),
              Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
              Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
              Example("let image = NSImage(named: aVariable)"),
              Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
              Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let image = ↓#imageLiteral(resourceName: \"image.jpg\")"),
              Example(
                "let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
              ),
            ]
    }
}
