struct OverriddenSuperCallConfiguration: SeverityBasedRuleConfiguration {
  private static let defaultIncluded = [
    // NSObject
    "awakeFromNib()",
    "prepareForInterfaceBuilder()",
    // UICollectionViewLayout
    "invalidateLayout()",
    "invalidateLayout(with:)",
    "invalidateLayoutWithContext(_:)",
    // UIView
    "prepareForReuse()",
    "updateConstraints()",
    // UIViewController
    "addChildViewController(_:)",
    "decodeRestorableState(with:)",
    "decodeRestorableStateWithCoder(_:)",
    "didReceiveMemoryWarning()",
    "encodeRestorableState(with:)",
    "encodeRestorableStateWithCoder(_:)",
    "removeFromParentViewController()",
    "setEditing(_:animated:)",
    "transition(from:to:duration:options:animations:completion:)",
    "transitionCoordinator()",
    "transitionFromViewController(_:toViewController:duration:options:animations:completion:)",
    "viewDidAppear(_:)",
    "viewDidDisappear(_:)",
    "viewDidLoad()",
    "viewWillAppear(_:)",
    "viewWillDisappear(_:)",
    // XCTestCase
    "invokeTest()",
  ]

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "excluded")
  private(set) var excluded = [String]()
  @ConfigurationElement(key: "included")
  private(set) var included = ["*"]

  var resolvedMethodNames: [String] {
    var names: [String] = []
    if included.contains("*"), !excluded.contains("*") {
      names += Self.defaultIncluded
    }
    names += included.filter { $0 != "*" }
    names = names.filter { !excluded.contains($0) }
    return names
  }

  typealias Parent = OverriddenSuperCallRule
  mutating func apply(configuration: Any) throws(Issue) {
    if $excluded.key.isEmpty {
      $excluded.key = "excluded"
    }
    if $included.key.isEmpty {
      $included.key = "included"
    }
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable. Continue.
    }
    guard let configuration = configuration as? [String: Any] else {
      return
    }
    if let value = configuration[$excluded.key] {
      try excluded.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$included.key] {
      try included.apply(value, ruleID: Parent.identifier)
    }
    if !supportedKeys.isSuperset(of: configuration.keys) {
      let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
      Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
    }
    try validate()
  }
}
