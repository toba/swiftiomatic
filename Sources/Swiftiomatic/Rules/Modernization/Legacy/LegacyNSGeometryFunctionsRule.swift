struct LegacyNSGeometryFunctionsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LegacyNSGeometryFunctionsConfiguration()

  private static let legacyFunctions: [String: LegacyFunctionRewriteStrategy] = [
    "NSHeight": .property(name: "height"),
    "NSIntegralRect": .property(name: "integral"),
    "NSIsEmptyRect": .property(name: "isEmpty"),
    "NSMaxX": .property(name: "maxX"),
    "NSMaxY": .property(name: "maxY"),
    "NSMidX": .property(name: "midX"),
    "NSMidY": .property(name: "midY"),
    "NSMinX": .property(name: "minX"),
    "NSMinY": .property(name: "minY"),
    "NSWidth": .property(name: "width"),
    "NSEqualPoints": .equal,
    "NSEqualSizes": .equal,
    "NSEqualRects": .equal,
    "NSEdgeInsetsEqual": .equal,
    "NSInsetRect": .function(name: "insetBy", argumentLabels: ["dx", "dy"]),
    "NSOffsetRect": .function(name: "offsetBy", argumentLabels: ["dx", "dy"]),
    "NSUnionRect": .function(name: "union", argumentLabels: [""]),
    "NSContainsRect": .function(name: "contains", argumentLabels: [""]),
    "NSIntersectsRect": .function(name: "intersects", argumentLabels: [""]),
    "NSIntersectionRect": .function(name: "intersection", argumentLabels: [""]),
    "NSPointInRect": .function(name: "contains", argumentLabels: [""], reversed: true),
  ]
}

extension LegacyNSGeometryFunctionsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension LegacyNSGeometryFunctionsRule {
  fileprivate final class Visitor: LegacyFunctionVisitor<OptionsType> {
    init(configuration: OptionsType, file: SwiftSource) {
      super.init(
        configuration: configuration, file: file,
        legacyFunctions: LegacyNSGeometryFunctionsRule.legacyFunctions,
      )
    }
  }

  fileprivate final class Rewriter: LegacyFunctionRewriter<OptionsType> {
    init(configuration: OptionsType, file: SwiftSource) {
      super.init(
        configuration: configuration, file: file,
        legacyFunctions: LegacyNSGeometryFunctionsRule.legacyFunctions,
      )
    }
  }
}
