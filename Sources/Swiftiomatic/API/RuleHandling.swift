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

/// How a rule should be handled when encountered during linting or formatting.
///
/// Controls whether a rule is active and, if so, how its findings are reported
/// and whether it auto-fixes code. This maps to Xcode's native diagnostic severity:
/// `file:line:column: warning:` vs `file:line:column: error:`.
public enum RuleHandling: Hashable, Sendable {
  /// The rule auto-fixes code and findings are reported as warnings.
  /// Only meaningful for format rules; lint-only rules treat this as `.warning`.
  case fix
  /// The rule is active and findings are reported as warnings (no auto-fix).
  case warning
  /// The rule is active and findings are reported as errors (no auto-fix).
  case error
  /// The rule is disabled.
  case off

  /// Whether the rule should run (i.e., is not `.off`).
  public var isActive: Bool { self != .off }

  /// Whether the rule should rewrite the AST (only meaningful for format rules).
  public var shouldFix: Bool { self == .fix }

  /// The diagnostic severity for finding emission.
  /// `.fix` maps to `.warning` for diagnostic purposes.
  public var diagnosticSeverity: Self { self == .fix ? .warning : self }

  /// The string used for JSON encoding.
  var encodedString: String {
    switch self {
    case .fix: "fix"
    case .warning: "warn"
    case .error: "error"
    case .off: "off"
    }
  }
}

extension RuleHandling: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    switch string {
    case "fix": self = .fix
    case "warn", "warning": self = .warning
    case "error": self = .error
    case "off": self = .off
    default:
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid rule handling '\(string)'. Expected 'fix', 'warn', 'error', or 'off'."
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .fix: try container.encode("fix")
    case .warning: try container.encode("warn")
    case .error: try container.encode("error")
    case .off: try container.encode("off")
    }
  }
}
