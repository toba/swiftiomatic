struct AttributesConfiguration: RuleConfiguration {
    let id = "attributes"
    let name = "Attributes"
    let summary = ""
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        AttributesRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        AttributesRuleExamples.triggeringExamples
    }
    let rationale: String? = """
      Erica Sadun says:

      > My take on things after the poll and after talking directly with a number of \
      developers is this: Placing attributes like `@objc`, `@testable`, `@available`, `@discardableResult` on \
      their own lines before a member declaration has become a conventional Swift style.

      > This approach limits declaration length. It allows a member to float below its attribute and supports \
      flush-left access modifiers, so `internal`, `public`, etc appear in the leftmost column. Many developers \
      mix-and-match styles for short Swift attributes like `@objc`

      See https://ericasadun.com/2016/10/02/quick-style-survey/ for discussion.

      Swiftiomatic's rule requires attributes to be on their own lines for functions and types, but on the same line \
      for variables and imports.
      """
}
