import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct TypeContentsOrderRuleTests {
  // MARK: - Default order — no violations

  @Test func defaultOrderNoViolation() async {
    await assertNoViolation(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
      \(TypeContentsOrderRule.defaultOrderParts.joined(separator: "\n\n"))
      }
      """)
  }

  @Test func availabilityMacroOrderNoViolation() async {
    await assertNoViolation(
      TypeContentsOrderRule.self,
      """
      struct ContentView: View {
          @available(SwiftUI_v5, *) // Availability macro syntax: https://github.com/swiftlang/swift/pull/65218
          var v5Body: some View { EmptyView() }
          var body: some View { EmptyView() }
      }
      """)
  }

  // MARK: - Default order — violations

  @Test func subtypeBeforeTypeAliasViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Subtypes
          1️⃣class TestClass {
              // 10 lines
          }

          // Type Aliases
          typealias CompletionHandler = ((TestEnum) -> Void)
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func typePropertyBeforeSubtypeViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Stored Type Properties
          1️⃣static let cellIdentifier: String = "AmazingCell"

          // Subtypes
          class TestClass {
              // 10 lines
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func instancePropertyBeforeTypePropertyViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Stored Instance Properties
          1️⃣var shouldLayoutView1: Bool!

          // Stored Type Properties
          static let cellIdentifier: String = "AmazingCell"
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ibOutletBeforeComputedPropertyViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // IBOutlets
          @IBOutlet private 1️⃣var view1: UIView!

          // Computed Instance Properties
          private var hasAnyLayoutedView: Bool {
               return hasLayoutedView1 || hasLayoutedView2
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func deinitBeforeInitViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {

          // deinitializer
          1️⃣deinit {
              log.debug("deinit")
          }

          // Initializers
          override 2️⃣init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
              super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
          }

          // IBOutlets
          @IBOutlet private var view1: UIView!
          @IBOutlet private var view2: UIView!
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  @Test func viewLifeCycleBeforeTypeMethodViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // View Life-Cycle Methods
          override 1️⃣func viewDidLoad() {
              super.viewDidLoad()

              view1.setNeedsLayout()
              view1.layoutIfNeeded()
              hasLayoutedView1 = true
          }

          // Type Methods
          static func makeViewController() -> TestViewController {
              // some code
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ibActionBeforeViewLifeCycleViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // IBActions
          @IBAction 1️⃣func goNextButtonPressed() {
              goToNextVc()
              delegate?.didPressTrackedButton()
          }

          // View Life-Cycle Methods
          override func viewDidLoad() {
              super.viewDidLoad()

              view1.setNeedsLayout()
              view1.layoutIfNeeded()
              hasLayoutedView1 = true
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func otherMethodBeforeIBActionViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Other Methods
          1️⃣func goToNextVc() { /* TODO */ }

          // IBActions
          @IBAction func goNextButtonPressed() {
              goToNextVc()
              delegate?.didPressTrackedButton()
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func subscriptBeforeOtherMethodViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Subscripts
          1️⃣subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
              get {
                  return "This is just a test"
              }

              set {
                  log.warning("Just a test", newValue)
              }
          }

          // MARK: Other Methods
          func goToNextVc() { /* TODO */ }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func associatedTypeAfterPropertyInProtocolViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      protocol P {
          1️⃣var x: U { get }
          @available(*, unavailable)
          2️⃣associatedtype T
          typealias U = Int
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: ["order": [["type_alias"], ["associated_type"]] as [any Sendable]])
  }

  @Test func caseAfterMethodInEnumViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      enum E {
          @available(*, unavailable)
          1️⃣case a
          func f() {}
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["order": [["other_method"], ["case"]] as [any Sendable]])
  }

  @Test func instancePropertyBeforeStaticPropertyViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      final class C {
          1️⃣var i = 1
          static var I = 2
          class var s: Int {
              struct S {}
              return 3
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func instancePropertyBeforeStaticInIfDefViolation() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      final class C {
          1️⃣var i = 1
          #if os(macOS)
          static var I = 2
          #endif
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func nestedIfDefMultipleViolations() async {
    await assertLint(
      TypeContentsOrderRule.self,
      """
      struct S {
          1️⃣var i = 1
          #if os(macOS)
              #if swift(>=5.3)
              2️⃣func f() {}
              #endif
          #else
              static var i = 3
          #endif
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  // MARK: - Reversed order configuration

  @Test func reversedOrderTypeAliasBeforeSubtypeViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Type Aliases
          1️⃣typealias CompletionHandler = ((TestEnum) -> Void)

          // Subtypes
          class TestClass {
              // 10 lines
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func reversedOrderSubtypeBeforeTypePropertyViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Subtypes
          1️⃣class TestClass {
              // 10 lines
          }

          // Stored Type Properties
          static let cellIdentifier: String = "AmazingCell"
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func reversedOrderTypePropertyBeforeInstancePropertyViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Stored Type Properties
          1️⃣static let cellIdentifier: String = "AmazingCell"

          // Stored Instance Properties
          var shouldLayoutView1: Bool!
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func reversedOrderComputedPropertyBeforeIBOutletViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Computed Instance Properties
          private 1️⃣var hasAnyLayoutedView: Bool {
               return hasLayoutedView1 || hasLayoutedView2
          }

          // IBOutlets
          @IBOutlet private var view1: UIView!
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func reversedOrderIBOutletBeforeInitViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // IBOutlets
          @IBOutlet private 1️⃣var view1: UIView!

          // Initializers
          override 2️⃣init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
              super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
          }

          // deinitializer
          deinit {
              log.debug("deinit")
          }
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: config)
  }

  @Test func reversedOrderTypeMethodBeforeViewLifeCycleViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Type Methods
          1️⃣static func makeViewController() -> TestViewController {
              // some code
          }

          // View Life-Cycle Methods
          override func viewDidLoad() {
              super.viewDidLoad()

              view1.setNeedsLayout()
              view1.layoutIfNeeded()
              hasLayoutedView1 = true
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func reversedOrderViewLifeCycleBeforeIBActionViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // View Life-Cycle Methods
          override 1️⃣func viewDidLoad() {
              super.viewDidLoad()

              view1.setNeedsLayout()
              view1.layoutIfNeeded()
              hasLayoutedView1 = true
          }

          // IBActions
          @IBAction func goNextButtonPressed() {
              goToNextVc()
              delegate?.didPressTrackedButton()
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func reversedOrderIBActionBeforeOtherMethodViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // IBActions
          @IBAction 1️⃣func goNextButtonPressed() {
              goToNextVc()
              delegate?.didPressTrackedButton()
          }

          // Other Methods
          func goToNextVc() { /* TODO */ }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func reversedOrderOtherMethodBeforeSubscriptViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        "deinitializer",
        "subscript",
        "other_method",
        "ib_action",
        "view_life_cycle_method",
        "type_method",
        "initializer",
        "ib_outlet",
        "ib_inspectable",
        "instance_property",
        "type_property",
        "subtype",
        ["type_alias", "associated_type"] as [any Sendable],
        "case",
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // MARK: Other Methods
          1️⃣func goToNextVc() { /* TODO */ }

          // Subscripts
          subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
              get {
                  return "This is just a test"
              }

              set {
                  log.warning("Just a test", newValue)
              }
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  // MARK: - Grouped order configuration — no violations

  @Test func groupedOrderNoViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        ["type_alias", "associated_type", "subtype"] as [any Sendable],
        ["type_property", "instance_property", "ib_inspectable", "ib_outlet"] as [any Sendable],
        ["initializer", "type_method", "deinitializer"] as [any Sendable],
        ["view_life_cycle_method", "ib_action", "other_method", "subscript"] as [any Sendable],
        ["ib_segue_action"] as [any Sendable],
      ] as [any Sendable]
    ]

    await assertNoViolation(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Type Alias
          typealias CompletionHandler = ((TestClass) -> Void)

          // Subtype
          class TestClass {
              // 10 lines
          }

          // Type Alias
          typealias CompletionHandler2 = ((TestStruct) -> Void)

          // Subtype
          struct TestStruct {
              // 3 lines
          }

          // Type Alias
          typealias CompletionHandler3 = ((TestEnum) -> Void)

          // Subtype
          enum TestEnum {
              // 5 lines
          }

          // Instance Property
          var shouldLayoutView1: Bool!

          // Type Property
          static let cellIdentifier: String = "AmazingCell"

          // Instance Property
          weak var delegate: TestViewControllerDelegate?

          // IBOutlet
          @IBOutlet private var view1: UIView!

          // Instance Property
          private var hasLayoutedView1: Bool = false

          // IBOutlet
          @IBOutlet private var view2: UIView!

          // Initializer
          override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
              super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
          }

          // Type Method
          static func makeViewController() -> TestViewController {
              // some code
          }

          // Initializer
          required init?(coder aDecoder: NSCoder) {
              fatalError("init(coder:) has not been implemented")
          }

          // deinitializer
          deinit {
              log.debug("deinit")
          }

          // View Life-Cycle Method
          override func viewDidLoad() {
              super.viewDidLoad()

              view1.setNeedsLayout()
              view1.layoutIfNeeded()
              hasLayoutedView1 = true
          }

          // Other Method
          func goToInfoVc() { /* TODO */ }

          // Other Method
          func initInfoVc () { /* TODO */ }

          // IBAction
          @IBAction func goNextButtonPressed() {
              goToNextVc()
              delegate?.didPressTrackedButton()
          }

          // Other Methods
          func goToNextVc() { /* TODO */ }

          // Subscript
          subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
              get {
                  return "This is just a test"
              }

              set {
                  log.warning("Just a test", newValue)
              }
          }

          // Other Method
          private func getRandomVc() -> UIViewController { return UIViewController() }

          /// View Life-Cycle Method
          override func viewDidLayoutSubviews() {
              super.viewDidLayoutSubviews()

              view2.setNeedsLayout()
              view2.layoutIfNeeded()
              hasLayoutedView2 = true
          }

          @IBSegueAction func prepareForNextVc(_ coder: NSCoder) -> UIViewController? {
              getRandomVc()
          }
      }
      """,
      configuration: config)
  }

  // MARK: - Grouped order configuration — violations

  @Test func groupedOrderInstancePropertyBeforeDeinitViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        ["type_alias", "associated_type", "subtype"] as [any Sendable],
        ["type_property", "instance_property", "ib_inspectable", "ib_outlet"] as [any Sendable],
        ["initializer", "type_method", "deinitializer"] as [any Sendable],
        ["view_life_cycle_method", "ib_action", "other_method", "subscript"] as [any Sendable],
        ["ib_segue_action"] as [any Sendable],
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Type Alias
          typealias CompletionHandler = ((TestClass) -> Void)

          // Instance Property
          1️⃣var shouldLayoutView1: Bool!

          // deinitializer
          2️⃣deinit {
              log.debug("deinit")
          }

          // Subtype
          class TestClass {
              // 10 lines
          }
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: config)
  }

  @Test func groupedOrderInitBeforeTypePropertyViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        ["type_alias", "associated_type", "subtype"] as [any Sendable],
        ["type_property", "instance_property", "ib_inspectable", "ib_outlet"] as [any Sendable],
        ["initializer", "type_method", "deinitializer"] as [any Sendable],
        ["view_life_cycle_method", "ib_action", "other_method", "subscript"] as [any Sendable],
        ["ib_segue_action"] as [any Sendable],
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Instance Property
          var shouldLayoutView1: Bool!

          // Initializer
          override 1️⃣init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
              super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
          }

          // Type Property
          static let cellIdentifier: String = "AmazingCell"
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func groupedOrderOtherMethodBeforeTypeMethodViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        ["type_alias", "associated_type", "subtype"] as [any Sendable],
        ["type_property", "instance_property", "ib_inspectable", "ib_outlet"] as [any Sendable],
        ["initializer", "type_method", "deinitializer"] as [any Sendable],
        ["view_life_cycle_method", "ib_action", "other_method", "subscript"] as [any Sendable],
        ["ib_segue_action"] as [any Sendable],
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
      class TestViewController: UIViewController {
          // Initializer
          override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
              super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
          }

          // Other Method
          private 1️⃣func getRandomVc() -> UIViewController { return UIViewController() }

          // Type Method
          static func makeViewController() -> TestViewController {
              // some code
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }

  @Test func groupedOrderIBSegueActionAfterMethodViolation() async {
    let config: [String: any Sendable] = [
      "order": [
        ["type_alias", "associated_type", "subtype"] as [any Sendable],
        ["type_property", "instance_property", "ib_inspectable", "ib_outlet"] as [any Sendable],
        ["initializer", "type_method", "deinitializer"] as [any Sendable],
        ["view_life_cycle_method", "ib_action", "other_method", "subscript"] as [any Sendable],
        ["ib_segue_action"] as [any Sendable],
      ] as [any Sendable]
    ]

    await assertLint(
      TypeContentsOrderRule.self,
      """
          class C {
              func f() {}

              @IBSegueAction 1️⃣func foo(_ coder: NSCoder) -> UIViewController? {
                  nil
              }

              @IBAction func bar() {}
          }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: config)
  }
}
