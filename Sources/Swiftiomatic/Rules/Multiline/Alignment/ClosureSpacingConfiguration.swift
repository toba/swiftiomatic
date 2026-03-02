struct ClosureSpacingConfiguration: RuleConfiguration {
    let id = "closure_spacing"
    let name = "Closure Spacing"
    let summary = "Closure expressions should have a single space inside each brace"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("[].map ({ $0.description })"),
              Example("[].filter { $0.contains(location) }"),
              Example("extension UITableViewCell: ReusableView { }"),
              Example("extension UITableViewCell: ReusableView {}"),
              Example(#"let r = /\{\}/"#, isExcludedFromDocumentation: true),
              Example(
                """
                var tapped: (UITapGestureRecognizer) -> Void = { _ in /* no-op */ }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                let test1 = func1(arg: { /* do nothing */ })
                let test2 = func1 { /* do nothing */ }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("[].filter↓{ $0.contains(location) }"),
              Example("[].filter(↓{$0.contains(location)})"),
              Example("[].map(↓{$0})"),
              Example("(↓{each in return result.contains(where: ↓{e in return e}) }).count"),
              Example("filter ↓{ sorted ↓{ $0 < $1}}"),
              Example(
                """
                var tapped: (UITapGestureRecognizer) -> Void = ↓{ _ in /* no-op */  }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("[].filter(↓{$0.contains(location) })"):
                Example("[].filter({ $0.contains(location) })"),
              Example("[].map(↓{$0})"):
                Example("[].map({ $0 })"),
              Example("filter ↓{sorted ↓{ $0 < $1}}"):
                Example("filter { sorted { $0 < $1 } }"),
              Example("(↓{each in return result.contains(where: ↓{e in return 0})}).count"):
                Example("({ each in return result.contains(where: { e in return 0 }) }).count"),
            ]
    }
}
