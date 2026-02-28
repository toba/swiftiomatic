/// Classification of `Any`-family type annotations. Used by both
/// `AnyEliminationCheck` (suggest) and `AnyEliminationRule` (lint).
enum AnyTypeMatch {
    case any
    case anyObject
    case anyHashable

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

    var suggestion: String? {
        switch self {
            case .any:
                "Use a specific type, protocol, or generic parameter"
            case .anyObject, .anyHashable:
                nil
        }
    }
}

enum AnyTypeClassifier {
    /// Classify a type string as an `Any`-family type, or return `nil` if it isn't one.
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
