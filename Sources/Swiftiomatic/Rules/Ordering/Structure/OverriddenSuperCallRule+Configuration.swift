struct OverriddenSuperCallConfiguration: SeverityBasedRuleOptions {
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
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
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
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$excluded.key] {
      try excluded.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$included.key] {
      try included.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
