public import Foundation
import Synchronization

/// Thread-safe container to register and look up Swiftiomatic rules
public final class RuleRegistry: Sendable {
  private struct State: Sendable {
    var registeredRules = [any Rule.Type]()
    var isRegistered = false
    var list: RuleList?
  }

  private let state = Mutex(State())

  /// Shared rule registry instance
  public static let shared = RuleRegistry()

  /// Rule list associated with this registry, lazily created after registration.
  ///
  /// If accessed before ``registerAllRulesOnce()`` has been called, triggers
  /// registration automatically to prevent returning an empty list.
  var list: RuleList {
    // Check if registration is needed WITHOUT holding the lock
    let needsRegistration = state.withLock { !$0.isRegistered }
    if needsRegistration {
      RuleRegistry.registerAllRulesOnce()
    }
    return state.withLock { state in
      if let list = state.list { return list }
      let list = RuleList(rules: state.registeredRules)
      state.list = list
      return list
    }
  }

  /// The number of registered rules
  public var ruleCount: Int {
    list.rules.count
  }

  private init() { /* To guarantee that this is singleton. */  }

  /// Register rules
  ///
  /// - Parameters:
  ///   - rules: The rules to register.
  func register(rules: [any Rule.Type]) {
    state.withLock {
      $0.registeredRules.append(contentsOf: rules)
      $0.isRegistered = true
      $0.list = nil  // Invalidate cached list
    }
  }

  /// Look up a rule for a given ID
  ///
  /// - Parameters:
  ///   - id: The ID for the rule to look up.
  /// - Returns: The rule matching the specified ID, if one was found.
  func rule(forID id: String) -> (any Rule.Type)? {
    list.rules[id]
  }

  /// Generate rule documentation to the specified directory
  ///
  /// - Parameters:
  ///   - url: The directory URL where documentation files will be written.
  public func generateDocs(to url: URL) throws {
    let docs = RuleListDocumentation(list)
    try docs.write(to: url)
  }
}
