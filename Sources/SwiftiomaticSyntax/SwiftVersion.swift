import Foundation

/// A value describing the version of the Swift compiler.
public struct SwiftVersion: RawRepresentable, Codable, VersionComparable, Sendable {
  public typealias RawValue = String

  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension SwiftVersion {
  /// Swift 6
  public static let v6 = SwiftVersion(rawValue: "6.0.0")
  /// Swift 6.1
  public static let v6_1 = SwiftVersion(rawValue: "6.1.0")
  /// Swift 6.1.1
  public static let v6_1_1 = SwiftVersion(rawValue: "6.1.1")
  /// Swift 6.1.2
  public static let v6_1_2 = SwiftVersion(rawValue: "6.1.2")
  /// Swift 6.2
  public static let v6_2 = SwiftVersion(rawValue: "6.2.0")
  /// Swift 6.2.1
  public static let v6_2_1 = SwiftVersion(rawValue: "6.2.1")
  /// Swift 6.2.2
  public static let v6_2_2 = SwiftVersion(rawValue: "6.2.2")
  /// Swift 6.2.3
  public static let v6_2_3 = SwiftVersion(rawValue: "6.2.3")
  /// Swift 6.3
  public static let v6_3 = SwiftVersion(rawValue: "6.3.0")

  /// The current detected Swift compiler version
  ///
  /// Defaults to the compile-time version. SwiftiomaticKit overrides this
  /// with a SourceKit-detected version when available.
  ///
  /// - note: Override by setting the `SWIFTIOMATIC_SWIFT_VERSION` environment variable.
  nonisolated(unsafe) public static var current: SwiftVersion = {
    // Allow forcing the Swift version, useful in cases where SourceKit isn't available.
    if let envVersion = ProcessInfo.processInfo.environment["SWIFTIOMATIC_SWIFT_VERSION"] {
      return SwiftVersion(rawValue: envVersion)
    }
    return .compileTime
  }()

  /// Compile-time Swift version detected via `#if compiler()` directives.
  /// Used as a fallback when SourceKit is unavailable.
  public static let compileTime: SwiftVersion = {
    #if compiler(>=6.3.0)
      return SwiftVersion(rawValue: "6.3.0")
    #elseif compiler(>=6.2.4)
      return SwiftVersion(rawValue: "6.2.4")
    #elseif compiler(>=6.2.3)
      return SwiftVersion(rawValue: "6.2.3")
    #elseif compiler(>=6.2.2)
      return SwiftVersion(rawValue: "6.2.2")
    #elseif compiler(>=6.2.1)
      return SwiftVersion(rawValue: "6.2.1")
    #elseif compiler(>=6.2.0)
      return SwiftVersion(rawValue: "6.2.0")
    #elseif compiler(>=6.1.2)
      return SwiftVersion(rawValue: "6.1.2")
    #elseif compiler(>=6.1.1)
      return SwiftVersion(rawValue: "6.1.1")
    #elseif compiler(>=6.1.0)
      return SwiftVersion(rawValue: "6.1.0")
    #elseif compiler(>=6.0.0)
      return SwiftVersion(rawValue: "6.0.0")
    #else
      return .v6
    #endif
  }()
}
