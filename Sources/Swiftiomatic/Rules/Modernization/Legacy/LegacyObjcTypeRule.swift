import SwiftSyntax

private let legacyObjcTypes = [
  "NSAffineTransform",
  "NSArray",
  "NSCalendar",
  "NSCharacterSet",
  "NSData",
  "NSDateComponents",
  "NSDateInterval",
  "NSDate",
  "NSDecimalNumber",
  "NSDictionary",
  "NSIndexPath",
  "NSIndexSet",
  "NSLocale",
  "NSMeasurement",
  "NSNotification",
  "NSNumber",
  "NSPersonNameComponents",
  "NSSet",
  "NSString",
  "NSTimeZone",
  "NSURL",
  "NSURLComponents",
  "NSURLQueryItem",
  "NSURLRequest",
  "NSUUID",
]

struct LegacyObjcTypeRule {
  var options = LegacyObjcTypeOptions()

  static let configuration = LegacyObjcTypeConfiguration()
}

extension LegacyObjcTypeRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LegacyObjcTypeRule {}

extension LegacyObjcTypeRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: IdentifierTypeSyntax) {
      if let name = node.typeName, isViolatingType(name) {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if isViolatingType(node.baseName.text) {
        violations.append(node.baseName.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: MemberTypeSyntax) {
      if node.baseType.as(IdentifierTypeSyntax.self)?.typeName == "Foundation",
        isViolatingType(node.name.text)
      {
        violations.append(node.name.positionAfterSkippingLeadingTrivia)
      }
    }

    private func isViolatingType(_ name: String) -> Bool {
      legacyObjcTypes.contains(name) && !configuration.allowedTypes.contains(name)
    }
  }
}
