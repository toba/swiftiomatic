struct LegacyCGGeometryFunctionsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LegacyCGGeometryFunctionsConfiguration()

  private static let legacyFunctions: [String: LegacyFunctionRewriteStrategy] = [
    "CGRectGetWidth": .property(name: "width"),
    "CGRectGetHeight": .property(name: "height"),
    "CGRectGetMinX": .property(name: "minX"),
    "CGRectGetMidX": .property(name: "midX"),
    "CGRectGetMaxX": .property(name: "maxX"),
    "CGRectGetMinY": .property(name: "minY"),
    "CGRectGetMidY": .property(name: "midY"),
    "CGRectGetMaxY": .property(name: "maxY"),
    "CGRectIsNull": .property(name: "isNull"),
    "CGRectIsEmpty": .property(name: "isEmpty"),
    "CGRectIsInfinite": .property(name: "isInfinite"),
    "CGRectStandardize": .property(name: "standardized"),
    "CGRectIntegral": .property(name: "integral"),
    "CGRectInset": .function(name: "insetBy", argumentLabels: ["dx", "dy"]),
    "CGRectOffset": .function(name: "offsetBy", argumentLabels: ["dx", "dy"]),
    "CGRectUnion": .function(name: "union", argumentLabels: [""]),
    "CGRectContainsRect": .function(name: "contains", argumentLabels: [""]),
    "CGRectContainsPoint": .function(name: "contains", argumentLabels: [""]),
    "CGRectIntersectsRect": .function(name: "intersects", argumentLabels: [""]),
    "CGRectIntersection": .function(name: "intersection", argumentLabels: [""]),
  ]
}

extension LegacyCGGeometryFunctionsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension LegacyCGGeometryFunctionsRule {
  fileprivate final class Visitor: LegacyFunctionVisitor<OptionsType> {
    init(configuration: OptionsType, file: SwiftSource) {
      super.init(
        configuration: configuration, file: file,
        legacyFunctions: LegacyCGGeometryFunctionsRule.legacyFunctions,
      )
    }
  }

  fileprivate final class Rewriter: LegacyFunctionRewriter<OptionsType> {
    init(configuration: OptionsType, file: SwiftSource) {
      super.init(
        configuration: configuration, file: file,
        legacyFunctions: LegacyCGGeometryFunctionsRule.legacyFunctions,
      )
    }
  }
}
