/// Classification of `Any`-family type annotations
///
/// Used by both `AnyEliminationCheck` (suggest) and `AnyEliminationRule` (lint).
enum AnyTypeMatch {
  case any
  case anyObject
  case anyHashable

  /// A human-readable diagnostic message describing the type-safety concern
  var message: String {
    switch self {
    case .any:
      "Type 'Any' erases type safety"
    case .anyObject:
      "Type 'AnyObject' — consider a specific class type or protocol"
    case .anyHashable:
      "Type 'AnyHashable' — check if all elements share a common concrete type"
    }
  }

  /// An optional replacement suggestion, or `nil` when no single fix applies
  var suggestion: String? {
    switch self {
    case .any:
      "Use a specific type, protocol, or generic parameter"
    case .anyObject, .anyHashable:
      nil
    }
  }
}

/// Classifies type annotation strings as `Any`-family types
enum AnyTypeClassifier {
  /// Classifies a type string as an `Any`-family type
  ///
  /// - Parameters:
  ///   - typeStr: The type annotation text to classify.
  /// - Returns: The matching ``AnyTypeMatch`` case, or `nil` if the type is not an `Any`-family type.
  static func classifyAnyType(_ typeStr: String) -> AnyTypeMatch? {
    if typeStr == "Any" || typeStr == "Any?" {
      return .any
    } else if typeStr == "AnyObject" || typeStr == "AnyObject?" {
      return .anyObject
    } else if typeStr == "AnyHashable" {
      return .anyHashable
    }
    return nil
  }
}
