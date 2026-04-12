/// The accessibility of a Swift source declaration.
///
/// - SeeAlso: https://github.com/apple/swift/blob/main/docs/AccessControl.md
package enum AccessControlLevel: String, CustomStringConvertible, Sendable {
  /// Accessible by the declaration's immediate lexical scope.
  case `private` = "source.lang.swift.accessibility.private"
  /// Accessible by the declaration's same file.
  case `fileprivate` = "source.lang.swift.accessibility.fileprivate"
  /// Accessible by the declaration's same module, or modules importing it with the `@testable` attribute.
  case `internal` = "source.lang.swift.accessibility.internal"
  /// Accessible by all the modules defined in the same Swift package.
  case package = "source.lang.swift.accessibility.package"
  /// Accessible by the declaration's same program.
  case `public` = "source.lang.swift.accessibility.public"
  /// Accessible and customizable (via subclassing or overrides) by the declaration's same program.
  case open = "source.lang.swift.accessibility.open"

  /// Initializes an access control level by its Swift source keyword value.
  ///
  /// - Parameters:
  ///   - value: The value used to describe this level in Swift source code.
  package init?(description value: String) {
    switch value {
    case "private": self = .private
    case "fileprivate": self = .fileprivate
    case "internal": self = .internal
    case "package": self = .package
    case "public": self = .public
    case "open": self = .open
    default: return nil
    }
  }

  /// Initializes an access control level by its SourceKit unique identifier.
  ///
  /// - Parameters:
  ///   - value: The value used by SourceKit to refer to this access control level.
  package init?(identifier value: String) {
    self.init(rawValue: value)
  }

  package var description: String {
    switch self {
    case .private: return "private"
    case .fileprivate: return "fileprivate"
    case .internal: return "internal"
    case .package: return "package"
    case .public: return "public"
    case .open: return "open"
    }
  }
}

extension AccessControlLevel: CaseIterable, Comparable {}
