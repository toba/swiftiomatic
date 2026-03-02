struct PreferZeroOverExplicitInitConfiguration: RuleConfiguration {
    let id = "prefer_zero_over_explicit_init"
    let name = "Prefer Zero Over Explicit Init"
    let summary = "Prefer `.zero` over explicit init with zero parameters (e.g. `CGPoint(x: 0, y: 0)`)"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("CGRect(x: 0, y: 0, width: 0, height: 1)"),
              Example("CGPoint(x: 0, y: -1)"),
              Example("CGSize(width: 2, height: 4)"),
              Example("CGVector(dx: -5, dy: 0)"),
              Example("UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓CGPoint(x: 0, y: 0)"),
              Example("↓CGPoint(x: 0.000000, y: 0)"),
              Example("↓CGPoint(x: 0.000000, y: 0.000)"),
              Example("↓CGRect(x: 0, y: 0, width: 0, height: 0)"),
              Example("↓CGSize(width: 0, height: 0)"),
              Example("↓CGVector(dx: 0, dy: 0)"),
              Example("↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓CGPoint(x: 0, y: 0)"): Example("CGPoint.zero"),
              Example("(↓CGPoint(x: 0, y: 0))"): Example("(CGPoint.zero)"),
              Example("↓CGRect(x: 0, y: 0, width: 0, height: 0)"): Example("CGRect.zero"),
              Example("↓CGSize(width: 0, height: 0.000)"): Example("CGSize.zero"),
              Example("↓CGVector(dx: 0, dy: 0)"): Example("CGVector.zero"),
              Example("↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)"): Example(
                "UIEdgeInsets.zero",
              ),
            ]
    }
}
