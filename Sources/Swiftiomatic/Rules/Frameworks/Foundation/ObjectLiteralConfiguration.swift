struct ObjectLiteralConfiguration: RuleConfiguration {
    let id = "object_literal"
    let name = "Object Literal"
    let summary = "Prefer object literals over image and color inits"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let image = #imageLiteral(resourceName: \"image.jpg\")"),
              Example(
                "let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
              ),
              Example("let image = UIImage(named: aVariable)"),
              Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
              Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
              Example("let image = NSImage(named: aVariable)"),
              Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
              Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)"),
            ]
    }
    var triggeringExamples: [Example] {
        ["", ".init"].flatMap { (method: String) -> [Example] in
            ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
                [
                    Example("let image = ↓\(prefix)Image\(method)(named: \"foo\")"),
                    Example(
                        "let color = ↓\(prefix)Color\(method)(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)"
                    ),
                    Example(
                        "let color = ↓\(prefix)Color\(method)(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)"
                    ),
                    Example("let color = ↓\(prefix)Color\(method)(white: 0.5, alpha: 1)"),
                ]
            }
        }
    }
}
