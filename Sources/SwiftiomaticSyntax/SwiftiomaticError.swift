public import Foundation
import Synchronization

/// All possible issues which are printed as warnings by default.
public enum SwiftiomaticError: LocalizedError, Equatable {
  /// The configuration didn't match internal expectations.
  case invalidConfiguration(ruleID: String, message: String? = nil)

  /// Issued when a regular expression pattern is invalid.
  case invalidRegexPattern(ruleID: String, pattern: String)

  /// Issued when an option is deprecated. Suggests an alternative optionally.
  case deprecatedConfigurationOption(ruleID: String, key: String, alternative: String? = nil)

  /// Used in configuration parsing when no changes have been applied. Use only internally!
  case nothingApplied(ruleID: String)

  /// Rule is listed multiple times in the configuration.
  case listedMultipleTime(ruleID: String, times: Int)

  /// An identifier `old` has been renamed to `new`.
  case renamedIdentifier(old: String, new: String)

  /// Some configuration keys are invalid.
  case invalidConfigurationKeys(ruleID: String, keys: Set<String>)

  /// The configuration is inconsistent, that is options are mutually exclusive or one drives other values
  /// irrelevant.
  case inconsistentConfiguration(ruleID: String, message: String)

  /// Used rule IDs are invalid.
  case invalidRuleIDs(Set<String>)

  /// Found a rule configuration for a rule that is not present in `only_rules`.
  case ruleNotPresentInOnlyRules(ruleID: String)

  /// Found a rule configuration for a rule that is disabled.
  case ruleDisabledInDisabledRules(ruleID: String)

  /// Found a rule configuration for a rule that is not enabled in `opt_in_rules`.
  case ruleNotEnabledInOptInRules(ruleID: String)

  /// A generic warning specified by a string.
  case genericWarning(String)

  /// A generic error specified by a string.
  case genericError(String)

  /// A deprecation warning for a rule.
  case ruleDeprecated(ruleID: String)

  /// The initial configuration file was not found.
  case initialFileNotFound(path: String)

  /// A file at specified path was not found.
  case fileNotFound(path: String)

  /// The file at `path` is not readable or cannot be opened.
  case fileNotReadable(path: String?, ruleID: String)

  /// The file at `path` is not writable.
  case fileNotWritable(path: String)

  /// The file at `path` cannot be indexed by a specific rule.
  case indexingError(path: String?, ruleID: String)

  /// No arguments were provided to compile a file at `path` within a specific rule.
  case missingCompilerArguments(path: String?, ruleID: String)

  /// Cursor information cannot be extracted from a specific location.
  case missingCursorInfo(path: String?, ruleID: String)

  /// An error that occurred when parsing YAML.
  case yamlParsing(String)

  /// Flag to enable warnings for deprecations being printed to the console. Printing is enabled by default.
  private static let _printDeprecationWarnings = Mutex(true)
  public static var printDeprecationWarnings: Bool {
    get { _printDeprecationWarnings.withLock { $0 } }
    set { _printDeprecationWarnings.withLock { $0 = newValue } }
  }

  /// Wraps any `Error` into a `SwiftiomaticError.genericWarning` if it is not already one.
  ///
  /// - Parameters:
  ///   - error: Any `Error`.
  ///
  /// - returns: A `Issue.genericWarning` containing the message of the `error` argument.
  public static func wrap(error: some Error) -> Self {
    error as? Self ?? genericWarning(error.localizedDescription)
  }

  /// Make this issue an error.
  public var asError: Self {
    Self.genericError(message)
  }

  /// The issues description which is ready to be printed to the console.
  public var errorDescription: String? {
    switch self {
    case .genericError:
      return "error: \(message)"
    case .genericWarning:
      return "warning: \(message)"
    default:
      return Self.genericWarning(message).errorDescription
    }
  }

  /// Print the issue to the console.
  package func print() {
    if case .ruleDeprecated = self, !Self.printDeprecationWarnings {
      return
    }
    Console.captureContinuation?.yield(localizedDescription)
    Console.printError(localizedDescription)
  }

  private var message: String {
    switch self {
    case .invalidConfiguration(let id, let message):
      let message = if let message { ": \(message)" } else { "." }
      return "Invalid configuration for '\(id)' rule\(message) Falling back to default."
    case .invalidRegexPattern(let id, let pattern):
      return "Invalid regular expression pattern '\(pattern)' used to configure '\(id)' rule."
    case .deprecatedConfigurationOption(let id, let key, let alternative):
      let baseMessage = "Configuration option '\(key)' in '\(id)' rule is deprecated."
      if let alternative {
        return baseMessage + " Use the option '\(alternative)' instead."
      }
      return baseMessage
    case .nothingApplied(ruleID: let id):
      return Self.invalidConfiguration(ruleID: id).message
    case .listedMultipleTime(let id, let times):
      return "'\(id)' is listed \(times) times in the configuration."
    case .renamedIdentifier(let old, let new):
      return
        "'\(old)' has been renamed to '\(new)' and will be completely removed in a future release."
    case .invalidConfigurationKeys(let id, let keys):
      return "Configuration for '\(id)' rule contains the invalid key(s) \(keys.formatted)."
    case .inconsistentConfiguration(let id, let message):
      return "Inconsistent configuration for '\(id)' rule: \(message)"
    case .invalidRuleIDs(let ruleIDs):
      return "The key(s) \(ruleIDs.formatted) used as rule identifier(s) is/are invalid."
    case .ruleNotPresentInOnlyRules(let id):
      return "Found a configuration for '\(id)' rule, but it is not present in 'only_rules'."
    case .ruleDisabledInDisabledRules(let id):
      return "Found a configuration for '\(id)' rule, but it is disabled in 'disabled_rules'."
    case .ruleNotEnabledInOptInRules(let id):
      return "Found a configuration for '\(id)' rule, but it is not enabled in 'opt_in_rules'."
    case .genericWarning(let message), .genericError(let message):
      return message
    case .ruleDeprecated(let id):
      return """
        The `\(id)` rule is now deprecated and will be \
        completely removed in a future release.
        """
    case .initialFileNotFound(let path):
      return "Could not read file at path '\(path)'."
    case .fileNotFound(let path):
      return "File at path '\(path)' not found."
    case .fileNotReadable(let path, let id):
      return "Cannot open or read file at path '\(path ?? "...")' within '\(id)' rule."
    case .fileNotWritable(let path):
      return "Cannot write to file at path '\(path)'."
    case .indexingError(let path, let id):
      return "Cannot index file at path '\(path ?? "...")' within '\(id)' rule."
    case .missingCompilerArguments(let path, let id):
      return """
        Attempted to lint file at path '\(path ?? "...")' within '\(id)' rule \
        without any compiler arguments.
        """
    case .missingCursorInfo(let path, let id):
      return "Cannot get cursor info from file at path '\(path ?? "...")' within '\(id)' rule."
    case .yamlParsing(let message):
      return "Cannot parse YAML file: \(message)"
    }
  }
}

extension Set<String> {
  fileprivate var formatted: String {
    sorted()
      .map { "'\($0)'" }
      .joined(separator: ", ")
  }
}
