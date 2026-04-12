import SwiftiomaticSyntax

struct NoEmptyBlockOptions: SeverityBasedRuleOptions {
  enum CodeBlockType: String, AcceptableByOptionElement, CaseIterable {
    case functionBodies = "function_bodies"
    case initializerBodies = "initializer_bodies"
    case statementBlocks = "statement_blocks"
    case closureBlocks = "closure_blocks"

    static let all = Set(allCases)
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)

  @OptionElement(key: "disabled_block_types")
  private(set) var disabledBlockTypes: [CodeBlockType] = []

  var enabledBlockTypes: Set<CodeBlockType> {
    CodeBlockType.all.subtracting(disabledBlockTypes)
  }

  typealias Parent = NoEmptyBlockRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$disabledBlockTypes.key] {
      try disabledBlockTypes.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
