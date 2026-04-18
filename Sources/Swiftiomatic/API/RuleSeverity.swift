//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// The severity level for a lint or format rule.
///
/// Controls whether a rule is active and, if so, whether its findings are reported
/// as warnings or errors. This maps to Xcode's native diagnostic severity:
/// `file:line:column: warning:` vs `file:line:column: error:`.
public enum RuleSeverity: Hashable, Sendable {
  /// The rule is active and findings are reported as warnings.
  case warning
  /// The rule is active and findings are reported as errors.
  case error
  /// The rule is disabled.
  case off

  /// Whether the rule should run (i.e., is not `.off`).
  public var isActive: Bool { self != .off }

  /// The string used for JSON encoding.
  var encodedString: String {
    switch self {
    case .warning: "warn"
    case .error: "error"
    case .off: "off"
    }
  }
}

extension RuleSeverity: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    switch string {
    case "warn", "warning": self = .warning
    case "error": self = .error
    case "off": self = .off
    default:
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid rule severity '\(string)'. Expected 'warn', 'error', or 'off'."
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .warning: try container.encode("warn")
    case .error: try container.encode("error")
    case .off: try container.encode("off")
    }
  }
}
