@_exported import SwiftiomaticCore

extension ConfigGroup: ConfigRepresentable {
  /// Non-rule settings owned by this group.
  public var configProperties: [ConfigProperty] {
    switch self {
    case .updateBlankLines: [
      .init("maximumBlankLines", .integer(description: "Maximum consecutive blank lines.", defaultValue: 1, minimum: 0)),
    ]
    case .updateLineBreak: [
      .init("beforeControlFlowKeywords", .bool(description: "Break before else/catch after closing brace.", defaultValue: false)),
      .init("beforeEachArgument", .bool(description: "Break before each argument when wrapping.", defaultValue: false)),
      .init("beforeEachGenericRequirement", .bool(description: "Break before each generic requirement when wrapping.", defaultValue: false)),
      .init("betweenDeclarationAttributes", .bool(description: "Break between adjacent attributes.", defaultValue: false)),
      .init("aroundMultilineExpressionChainComponents", .bool(description: "Break around multiline dot-chained components.", defaultValue: false)),
    ]
    default: []
    }
  }
}
