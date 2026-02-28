import Testing

@testable import Swiftiomatic

@Suite struct RedundantMemberwiseInitTests {
  @Test func removeRedundantMemberwiseInit() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    let output = """
      struct Person {
          var name: String
          var age: Int
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func removeRedundantMemberwiseInitWithLetProperties() {
    let input = """
      struct Point {
          let x: Double
          let y: Double

          init(x: Double, y: Double) {
              self.x = x
              self.y = y
          }
      }
      """
    let output = """
      struct Point {
          let x: Double
          let y: Double
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func removeRedundantMemberwiseInitFromPrivateType() {
    let input = """
      private struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    let output = """
      private struct Person {
          var name: String
          var age: Int
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func removeRedundantMemberwiseInitFromFileprivateType() {
    let input = """
      fileprivate struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    let output = """
      fileprivate struct Person {
          var name: String
          var age: Int
      }
      """
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit, exclude: [.redundantFileprivate])
  }

  @Test func removeRedundantMemberwiseInitMixedProperties() {
    let input = """
      struct User {
          let id: Int
          var name: String
          var email: String

          init(id: Int, name: String, email: String) {
              self.id = id
              self.name = name
              self.email = email
          }
      }
      """
    let output = """
      struct User {
          let id: Int
          var name: String
          var email: String
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveCustomInit() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name.uppercased()
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithAdditionalLogic() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
              print("Person created")
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithDifferentParameterNames() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(fullName: String, yearsOld: Int) {
              self.name = fullName
              self.age = yearsOld
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithDifferentParameterTypes() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Double) {
              self.name = name
              self.age = Int(age)
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemovePrivateInit() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          private init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func removeInitWithComputedProperties() {
    let input = """
      struct Person {
          var name: String
          var age: Int
          var isAdult: Bool {
              return age >= 18
          }

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    let output = """
      struct Person {
          var name: String
          var age: Int
          var isAdult: Bool {
              return age >= 18
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveInitWithComputedPropertyInitialization() {
    let input = """
      struct Person {
          var name: String
          var age: Int
          var isAdult: Bool

          init(name: String, age: Int) {
              self.name = name
              self.age = age
              self.isAdult = age >= 18
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func removeInitWithStaticProperties() {
    let input = """
      struct Person {
          var name: String
          var age: Int
          static var defaultAge = 0

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    let output = """
      struct Person {
          var name: String
          var age: Int
          static var defaultAge = 0
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, exclude: [.redundantSelf])
  }

  @Test func dontRemoveInitWithPrivateProperties() {
    let input = """
      struct Person {
          private var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithPartialParameterMatch() {
    let input = """
      struct Person {
          var name: String
          var age: Int
          var city: String

          init(name: String, age: Int) {
              self.name = name
              self.age = age
              self.city = "Unknown"
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontAffectClass() {
    let input = """
      class Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontAffectEnum() {
    let input = """
      enum Color {
          case red
          case blue

          init() {
              self = .red
          }
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.trailingSpace])
  }

  @Test func handleEmptyStruct() {
    let input = """
      struct Empty {
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.emptyBraces])
  }

  @Test func handleStructWithOnlyComputedProperties() {
    let input = """
      struct Calculator {
          var result: Int {
              return 42
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func removeRedundantInitWithComplexTypes() {
    let input = """
      struct Container {
          var items: [String]
          var metadata: [String: Any]

          init(items: [String], metadata: [String: Any]) {
              self.items = items
              self.metadata = metadata
          }
      }
      """
    let output = """
      struct Container {
          var items: [String]
          var metadata: [String: Any]
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func removeRedundantInitWithOptionalTypes() {
    let input = """
      struct Person {
          var name: String?
          var age: Int?

          init(name: String?, age: Int?) {
              self.name = name
              self.age = age
          }
      }
      """
    let output = """
      struct Person {
          var name: String?
          var age: Int?
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveInitWithMethodCall() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
              self.validate()
          }

          func validate() {}
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithMethodCallBefore() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              setupDefaults()
              self.name = name
              self.age = age
          }

          func setupDefaults() {}
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithPrintStatement() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              print("Creating person: \\(name)")
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithMultipleStatements() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
              print("Person created")
              NotificationCenter.default.post(name: .personCreated, object: nil)
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithGuardStatement() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              guard age >= 0 else { fatalError("Invalid age") }
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [
        .redundantSelf, .trailingSpace, .indent, .blankLinesAfterGuardStatements,
        .wrapConditionalBodies,
      ])
  }

  @Test func dontRemoveInitWithComments() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              // Initialize properties
              self.name = name
              self.age = age
              // Initialization complete
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithConditionalLogic() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              if age < 0 {
                  self.age = 0
              } else {
                  self.age = age
              }
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithDefaultArguments() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int = 0) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithMultipleDefaultArguments() {
    let input = """
      struct Person {
          var name: String
          var age: Int
          var city: String

          init(name: String, age: Int = 0, city: String = "Unknown") {
              self.name = name
              self.age = age
              self.city = city
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithDifferentExternalLabels() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(withName name: String, andAge age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithMixedExternalLabels() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, withAge age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithUnderscoreExternalLabel() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(_ name: String, _ age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func removeInternalInitFromPublicStruct() {
    let input = """
      public struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    let output = """
      public struct Person {
          var name: String
          var age: Int
      }
      """
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemovePublicInitFromPublicStruct() {
    let input = """
      public struct Person {
          var name: String
          var age: Int

          public init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemovePackageInitFromPublicStruct() {
    let input = """
      public struct Person {
          var name: String
          var age: Int

          package init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWhenMultipleInitsExist() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }

          init(name: String) {
              self.name = name
              self.age = 0
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWhenThreeInitsExist() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }

          init(name: String) {
              self.name = name
              self.age = 0
          }

          init() {
              self.name = "Unknown"
              self.age = 0
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func preserveInitWithAttributes() {
    // Inits with attributes like @inlinable can't be removed because
    // synthesized memberwise inits don't support these attributes
    let input = """
      struct Person {
          var name: String
          var age: Int

          @inlinable
          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveInitWithPrivateStoredProperty() {
    let input = """
      struct Person {
          var name: String
          var age: Int
          private var id: String

          init(name: String, age: Int, id: String) {
              self.name = name
              self.age = age
              self.id = id
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithFileprivateStoredProperty() {
    let input = """
      struct Person {
          var name: String
          var age: Int
          fileprivate var secret: String

          init(name: String, age: Int, secret: String) {
              self.name = name
              self.age = age
              self.secret = secret
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func removePrivateInitWithPrivateStoredProperty() {
    let input = """
      struct Person {
          var name: String
          var age: Int
          private var id: String

          private init(name: String, age: Int, id: String) {
              self.name = name
              self.age = age
              self.id = id
          }
      }
      """
    let output = """
      struct Person {
          var name: String
          var age: Int
          private var id: String
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemovePublicInitWithPrivateStoredProperty() {
    let input = """
      public struct Person {
          var name: String
          var age: Int
          private var id: String

          public init(name: String, age: Int, id: String) {
              self.name = name
              self.age = age
              self.id = id
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWhenPrivatePropertiesWithDefaultValues() {
    let input = """
      struct PayoutView {
          let dataModel: String
          private var style = DefaultStyle()

          init(dataModel: String) {
              self.dataModel = dataModel
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent, .propertyTypes])
  }

  @Test func dontRemoveInitWhenPropertyHasDefaultValueButInitTakesBothRequiredAndOptional() {
    let input = """
      struct Person {
          let name: String
          var age: Int = 25

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func removeInitWhenPropertyHasDefaultValueAndInitMatchesCompilerGenerated() {
    let input = """
      struct Person {
          let name: String
          var age: Int = 25

          init(name: String) {
              self.name = name
          }
      }
      """
    let output = """
      struct Person {
          let name: String
          var age: Int = 25
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveInitWhenPrivatePropertiesHaveNoDefaultValues() {
    let input = """
      struct PayoutView {
          let dataModel: String
          private var shadowedStyle: ShadowedStyle

          init(dataModel: String, shadowedStyle: ShadowedStyle) {
              self.dataModel = dataModel
              self.shadowedStyle = shadowedStyle
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWhenAllPropertiesInitialized() {
    let input = """
      struct Person {
          let name: String
          let age: Int
          private var id: String = "default"

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWhenPrivatePropertiesWithDefaultsMakesSynthesizedInitPrivate() {
    let input = """
      struct Person {
          let name: String
          let age: Int
          private var id: String = "default"

          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithDocumentationComments() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          /// Creates a Person with the specified name and age
          init(name: String, age: Int) {
              self.name = name  
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveInitWithMultiLineDocumentationComments() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          /**
           * Creates a Person with the specified name and age.
           * - Parameter name: The person's full name
           * - Parameter age: The person's age in years
           */
          init(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveRedundantPublicMemberwiseInitWithProperFormattingOfFirstProperty() {
    let input = """
      public struct CardViewAnimationState {
          public init(
          style: CardStyle,
          backgroundColor: UIColor?
          ) {
          self.style = style
          self.backgroundColor = backgroundColor
          }

          public let style: CardStyle
          public let backgroundColor: UIColor?
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent, .wrapArguments])
  }

  @Test func removeRedundantMemberwiseInitWithComplexStruct() {
    let input = """
      struct Foo {

        // MARK: Lifecycle

        init(
          name: String,
          value: Int,
          isEnabled: Bool
        ) {
          self.name = name
          self.value = value
          self.isEnabled = isEnabled
        }

        // MARK: Public

        let name: String
        let value: Int
        let isEnabled: Bool
      }

      struct Bar: Equatable {

        // MARK: Lifecycle

        init(
          id: String,
          count: Int
        ) {
          self.id = id
          self.count = count
        }

        // MARK: Public

        let id: String
        let count: Int
      }

      // MARK: - Baz

      struct Baz: Equatable {

        // MARK: Lifecycle

        init(
          title: String,
          subtitle: String?,
          data: [String]
        ) {
          self.title = title
          self.subtitle = subtitle
          self.data = data
        }

        // MARK: Public

        let title: String
        let subtitle: String?
        let data: [String]
      }

      // MARK: - Qux

      struct Qux: Equatable {

        // MARK: Lifecycle

        init(
          key: String,
          value: String?
        ) {
          self.key = key
          self.value = value
        }

        // MARK: Public

        let key: String
        let value: String?
      }

      // MARK: - Widget

      struct Widget: Equatable {

        // MARK: Lifecycle

        init(
          name: String,
          color: String,
          size: Int
        ) {
          self.name = name
          self.color = color
          self.size = size
        }

        // MARK: Public

        let name: String
        let color: String
        let size: Int
      }

      // MARK: - Item

      struct Item: Equatable {

        // MARK: Lifecycle

        init(
          identifier: String,
          label: String
        ) {
          self.identifier = identifier
          self.label = label
        }

        // MARK: Public

        let identifier: String
        let label: String
      }

      // MARK: - Component

      struct Component: Equatable {
        init(type: String, config: [String: Any]) {
          self.type = type
          self.config = config
        }

        let type: String
        let config: [String: Any]
      }

      // MARK: - Element

      struct Element: Equatable {

        // MARK: Lifecycle

        init(
          tag: String,
          attributes: [String]?,
          content: String
        ) {
          self.tag = tag
          self.attributes = attributes
          self.content = content
        }

        // MARK: Public

        let tag: String
        let attributes: [String]?
        let content: String
      }

      // MARK: - Node

      struct Node: Equatable {

        // MARK: Lifecycle

        init(id: String, parent: String?, children: [String]) {
          self.id = id
          self.parent = parent
          self.children = children
        }

        // MARK: Public

        let id: String
        let parent: String?
        let children: [String]
      }

      // MARK: - Record

      struct Record: Equatable {

        // MARK: Lifecycle

        init(
          timestamp: Double,
          message: String
        ) {
          self.timestamp = timestamp
          self.message = message
        }

        // MARK: Public

        let timestamp: Double
        let message: String
      }
      """
    let output = """
      struct Foo {

        // MARK: Public

        let name: String
        let value: Int
        let isEnabled: Bool
      }

      struct Bar: Equatable {

        // MARK: Public

        let id: String
        let count: Int
      }

      // MARK: - Baz

      struct Baz: Equatable {

        // MARK: Public

        let title: String
        let subtitle: String?
        let data: [String]
      }

      // MARK: - Qux

      struct Qux: Equatable {

        // MARK: Public

        let key: String
        let value: String?
      }

      // MARK: - Widget

      struct Widget: Equatable {

        // MARK: Public

        let name: String
        let color: String
        let size: Int
      }

      // MARK: - Item

      struct Item: Equatable {

        // MARK: Public

        let identifier: String
        let label: String
      }

      // MARK: - Component

      struct Component: Equatable {
        let type: String
        let config: [String: Any]
      }

      // MARK: - Element

      struct Element: Equatable {

        // MARK: Public

        let tag: String
        let attributes: [String]?
        let content: String
      }

      // MARK: - Node

      struct Node: Equatable {

        // MARK: Public

        let id: String
        let parent: String?
        let children: [String]
      }

      // MARK: - Record

      struct Record: Equatable {

        // MARK: Public

        let timestamp: Double
        let message: String
      }
      """
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit,
      exclude: [.indent, .acronyms, .blankLinesAtStartOfScope])
  }

  @Test func removeInternalInitFromPublicStructWithInternalProperties() {
    let input = """
      public struct Foo {
          init(a: Int, b: Bool) {
              self.a = a
              self.b = b
          }

          let a: Int
          let b: Bool
      }
      """
    let output = """
      public struct Foo {
          let a: Int
          let b: Bool
      }
      """
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemovePrivateInitFromInternalStruct() {
    let input = """
      struct Bar {
          private init(a: Int, b: Bool) {
              self.a = a
              self.b = b
          }

          let a: Int
          let b: Bool
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveFileprivateInitFromInternalStructWithInternalProperties() {
    // The synthesized init would be internal, which is broader than fileprivate
    let input = """
      struct Bar {
          fileprivate init(a: Int, b: Bool) {
              self.a = a
              self.b = b
          }

          let a: Int
          let b: Bool
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveFileprivateInitFromInternalStructWithPrivateProperties() {
    // The synthesized init would be private, which is lower than fileprivate
    let input = """
      struct Bar {
          fileprivate init(a: Int, b: Bool) {
              self.a = a
              self.b = b
          }

          let a: Int
          private let b: Bool
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveFailableInit() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init?(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveImplicitlyUnwrappedFailableInit() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init!(name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemoveFailableInitWithValidation() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init?(name: String, age: Int) {
              guard age >= 0 else { return nil }
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [
        .redundantSelf, .trailingSpace, .indent, .wrapConditionalBodies,
        .blankLinesAfterGuardStatements,
      ])
  }

  @Test func dontRemoveFailableInitWithSpacing() {
    let input = """
      struct Person {
          var name: String
          var age: Int

          init? (name: String, age: Int) {
              self.name = name
              self.age = age
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  // MARK: - preferSynthesizedInitForInternalTypes option

  @Test func removePrivateACLWhenOptionEnabled() {
    let input = """
      struct InternalSwiftUIView: View {
          init(foo: Foo, bar: Bar) {
              self.foo = foo
              self.bar = bar
          }

          private let foo: Foo
          private let bar: Bar

          var body: some View {}
      }
      """
    let output = """
      struct InternalSwiftUIView: View {
          let foo: Foo
          let bar: Bar

          var body: some View {}
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLFromSwiftUIView() {
    let input = """
      struct ProfileView: View {
          init(user: User, settings: Settings) {
              self.user = user
              self.settings = settings
          }

          private let user: User
          private let settings: Settings

          var body: some View {
              VStack {
                  Text(user.name)
                  if settings.showEmail {
                      Text(user.email)
                  }
              }
          }
      }
      """
    let output = """
      struct ProfileView: View {
          let user: User
          let settings: Settings

          var body: some View {
              VStack {
                  Text(user.name)
                  if settings.showEmail {
                      Text(user.email)
                  }
              }
          }
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeFileprivateACLWhenOptionEnabled() {
    let input = """
      struct MyView {
          init(value: Int) {
              self.value = value
          }

          fileprivate let value: Int
      }
      """
    let output = """
      struct MyView {
          let value: Int
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func dontRemovePrivateACLWhenOptionDisabled() {
    let input = """
      struct InternalSwiftUIView: View {
          init(foo: Foo, bar: Bar) {
              self.foo = foo
              self.bar = bar
          }

          private let foo: Foo
          private let bar: Bar

          var body: some View {}
      }
      """
    testFormatting(
      for: input, rule: .redundantMemberwiseInit,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemovePrivateACLForPublicStruct() {
    let input = """
      public struct PublicView {
          init(value: Int) {
              self.value = value
          }

          private let value: Int
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, rule: .redundantMemberwiseInit, options: options,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func dontRemovePrivateACLForPackageStruct() {
    let input = """
      package struct PackageView {
          init(value: Int) {
              self.value = value
          }

          private let value: Int
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, rule: .redundantMemberwiseInit, options: options,
      exclude: [.redundantSelf, .trailingSpace, .indent])
  }

  @Test func removePrivateACLFromMultipleProperties() {
    let input = """
      struct DataModel {
          init(id: String, name: String, value: Int) {
              self.id = id
              self.name = name
              self.value = value
          }

          private let id: String
          private var name: String
          private let value: Int
          private var variableWithDefault = false
          private let constantWithDefault = true
      }
      """
    let output = """
      struct DataModel {
          let id: String
          var name: String
          let value: Int
          var variableWithDefault = false
          private let constantWithDefault = true
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLWithMixedAccessLevels() {
    let input = """
      struct MixedView {
          init(publicValue: Int, privateValue: String, onTap: @escaping () -> Void) {
              self.publicValue = publicValue
              self.privateValue = privateValue
              self.onTap = onTap
          }

          let publicValue: Int
          private let privateValue: String
          private let onTap: () -> Void
      }
      """
    let output = """
      struct MixedView {
          let publicValue: Int
          let privateValue: String
          let onTap: () -> Void
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLPreservesPropertyOrder() {
    let input = """
      struct OrderedView {
          private let first: Int
          private let second: String
          private let third: Bool

          init(first: Int, second: String, third: Bool) {
              self.first = first
              self.second = second
              self.third = third
          }
      }
      """
    let output = """
      struct OrderedView {
          let first: Int
          let second: String
          let third: Bool
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func dontApplyOptionToClasses() {
    // Classes don't have synthesized memberwise inits, so the option should not apply
    let input = """
      class ProfileViewModel {
          init(user: User, settings: Settings) {
              self.user = user
              self.settings = settings
          }

          private let user: User
          private let settings: Settings
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, rule: .redundantMemberwiseInit, options: options, exclude: [.redundantSelf])
  }

  @Test func removePrivateACLForPrivateStruct() {
    let input = """
      private struct PrivateView {
          init(value: Int) {
              self.value = value
          }

          private let value: Int
      }
      """
    let output = """
      private struct PrivateView {
          let value: Int
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLForFileprivateStruct() {
    let input = """
      fileprivate struct FileprivateView {
          init(value: Int) {
              self.value = value
          }

          private let value: Int
      }
      """
    let output = """
      fileprivate struct FileprivateView {
          let value: Int
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit, options: options,
      exclude: [.redundantFileprivate])
  }

  @Test func preservePrivateOnPropertiesWithDefaultValues() {
    let input = """
      struct Foo: View {
          init(bar: Bar) {
              self.bar = bar
          }

          private let bar: Bar
          @State private let enabled = false
          private let baaz = Baaz()
      }
      """
    let output = """
      struct Foo: View {
          let bar: Bar
          @State private let enabled = false
          private let baaz = Baaz()
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit, options: options,
      exclude: [.propertyTypes])
  }

  @Test func preserveInitWhenPrivatePropertyWithStateAttributeInMemberwiseInit() {
    let input = """
      struct Foo: View {
          init(bar: Bar, enabled: Bool) {
              self.bar = bar
              self.enabled = enabled
          }

          private let bar: Bar
          @State private var enabled: Bool
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLFromPropertyWithCustomPropertyWrapper() {
    let input = """
      struct Foo {
          init(bar: Bar, value: String) {
              self.bar = bar
              self.value = value
          }

          private let bar: Bar
          @SomeCustomPropertyWrapper private var value: String
      }
      """
    let output = """
      struct Foo {
          let bar: Bar
          @SomeCustomPropertyWrapper var value: String
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func preserveInitWhenPrivateVarWithDefaultValue() {
    // private var with default value is still part of memberwise init (optional param),
    // so synthesized init would be private
    let input = """
      struct Foo {
          init(foo: String) {
              self.foo = foo
          }

          let foo: String
          private var bar = "bar"
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func removeInitWhenPrivateLetWithDefaultValue() {
    // private let with default value is NOT part of memberwise init,
    // so it doesn't affect synthesized init visibility
    let input = """
      struct Foo {
          init(foo: String) {
              self.foo = foo
          }

          let foo: String
          private let bar = "bar"
      }
      """
    let output = """
      struct Foo {
          let foo: String
          private let bar = "bar"
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func removePrivateACLWithOrganizeDeclarations() {
    let input = """
      struct ProfileView: View {
          // MARK: Lifecycle

          init(user: User, settings: Settings) {
              self.user = user
              self.settings = settings
          }

          // MARK: Internal

          var body: some View { fatalError() }

          // MARK: Private

          @Environment(\\.colorScheme) private var colorScheme
          @State private var foo = "default"
          private let user: User
          private let settings: Settings
      }
      """
    let output = """
      struct ProfileView: View {
          // MARK: Internal

          let user: User
          let settings: Settings

          var body: some View { fatalError() }

          // MARK: Private

          @Environment(\\.colorScheme) private var colorScheme
          @State private var foo = "default"
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, [output],
      rules: [
        .redundantMemberwiseInit, .organizeDeclarations, .blankLinesAtEndOfScope,
        .blankLinesAtStartOfScope,
      ], options: options, exclude: [.wrapPropertyBodies])
  }

  @Test func removeInitAndPrivateACLWhenPrivateVarWithDefaultValueAndOptionEnabled() {
    // With preferSynthesizedInitForInternalStructs enabled, we CAN remove the init
    // if there's a private var with default value, and we'll also remove its private ACL
    let input = """
      struct Foo {
          init(foo: String) {
              self.foo = foo
          }

          let foo: String
          private var bar = "default"
      }
      """
    let output = """
      struct Foo {
          let foo: String
          var bar = "default"
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWhenPrivateLetWithDefaultValueAndOptionEnabled() {
    // With preferSynthesizedInitForInternalStructs enabled, we CAN remove the init
    // if there's a private let with default value (not part of memberwise init)
    let input = """
      struct Foo {
          init(foo: String) {
              self.foo = foo
          }

          private let foo: String
          private let bar = "default"
      }
      """
    let output = """
      struct Foo {
          let foo: String
          private let bar = "default"
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func preserveInitWithUnusedParameters() {
    // Init has parameters with `_` internal labels that are ignored.
    // This is not a memberwise init - it takes extra parameters.
    let input = """
      struct Foo {
          init(
              loggingID _: String,
              viewModel: ViewModel,
              context _: Context
          ) {
              self.viewModel = viewModel
          }

          let viewModel: ViewModel
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  // MARK: - conformances mode

  @Test func removePrivateACLForConformingStruct() {
    let input = """
      struct ProfileView: View {
          init(user: User) {
              self.user = user
          }

          private let user: User

          var body: some View {}
      }
      """
    let output = """
      struct ProfileView: View {
          let user: User

          var body: some View {}
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .conformances(["View"]))
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func dontRemovePrivateACLForNonConformingStruct() {
    let input = """
      struct ProfileModel {
          init(user: User) {
              self.user = user
          }

          private let user: User
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .conformances(["View"]))
    testFormatting(for: input, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLForMultipleConformances() {
    let input = """
      struct ProfileView: View, Equatable {
          init(user: User) {
              self.user = user
          }

          private let user: User

          var body: some View {}
      }
      """
    let output = """
      struct ProfileView: View, Equatable {
          let user: User

          var body: some View {}
      }
      """
    let options = FormatOptions(
      preferSynthesizedInitForInternalStructs: .conformances(["View", "ViewModifier"]))
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLForViewModifierConformance() {
    let input = """
      struct MyModifier: ViewModifier {
          init(isEnabled: Bool) {
              self.isEnabled = isEnabled
          }

          private let isEnabled: Bool

          func body(content: Content) -> some View {
              content
          }
      }
      """
    let output = """
      struct MyModifier: ViewModifier {
          let isEnabled: Bool

          func body(content: Content) -> some View {
              content
          }
      }
      """
    let options = FormatOptions(
      preferSynthesizedInitForInternalStructs: .conformances(["View", "ViewModifier"]))
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  // MARK: - @ViewBuilder closure parameter handling

  @Test func removeInitWithViewBuilderClosureParameter() {
    let input = """
      struct MyView<Content: View>: View {
          let content: Content

          init(@ViewBuilder content: () -> Content) {
              self.content = content()
          }

          var body: some View {
              content
          }
      }
      """
    let output = """
      struct MyView<Content: View>: View {
          @ViewBuilder let content: Content

          var body: some View {
              content
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWithViewBuilderAndRegularParameters() {
    let input = """
      struct MyView<Content: View>: View {
          let title: String
          let content: Content

          init(title: String, @ViewBuilder content: () -> Content) {
              self.title = title
              self.content = content()
          }

          var body: some View {
              VStack {
                  Text(title)
                  content
              }
          }
      }
      """
    let output = """
      struct MyView<Content: View>: View {
          let title: String
          @ViewBuilder let content: Content

          var body: some View {
              VStack {
                  Text(title)
                  content
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWithPrivateViewBuilderProperty() {
    // When preferSynthesizedInitForInternalStructs is .always, private ACL is removed
    // so the synthesized init can have internal access
    let input = """
      struct MyView<Content: View>: View {
          private let content: Content

          init(@ViewBuilder content: () -> Content) {
              self.content = content()
          }

          var body: some View {
              content
          }
      }
      """
    let output = """
      struct MyView<Content: View>: View {
          @ViewBuilder let content: Content

          var body: some View {
              content
          }
      }
      """
    let options = FormatOptions(
      preferSynthesizedInitForInternalStructs: .always, swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func dontRemoveInitWithPrivateViewBuilderPropertyWithoutOption() {
    // Without preferSynthesizedInitForInternalStructs, we can't remove private ACL
    // so the synthesized init would be private, not matching the internal init
    let input = """
      struct MyView<Content: View>: View {
          private let content: Content

          init(@ViewBuilder content: () -> Content) {
              self.content = content()
          }

          var body: some View {
              content
          }
      }
      """
    // No options set, so init should be preserved
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func removeInitWithViewBuilderEscapingClosureParameter() {
    // When the init stores a closure directly (no invocation), we can still remove it
    // The @ViewBuilder attribute is transferred to the property
    let input = """
      struct MyView<Content: View>: View {
          let content: () -> Content

          init(@ViewBuilder content: @escaping () -> Content) {
              self.content = content
          }

          var body: some View {
              content()
          }
      }
      """
    let output = """
      struct MyView<Content: View>: View {
          @ViewBuilder let content: () -> Content

          var body: some View {
              content()
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveInitWithNonEmptyClosureParameter() {
    // Closures with parameters like (Int) -> Content are not handled
    let input = """
      struct MyView<Content: View>: View {
          let content: Content

          init(@ViewBuilder content: (Int) -> Content) {
              self.content = content(0)
          }

          var body: some View {
              content
          }
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveInitWithViewBuilderWhenParameterOrderDiffers() {
    // The synthesized init uses property declaration order, not init parameter order
    // So we can't remove an init where the order differs
    let input = """
      struct MyView<Content: View>: View {
          let title: String
          let content: Content

          init(@ViewBuilder content: () -> Content, title: String) {
              self.content = content()
              self.title = title
          }

          var body: some View {
              Text(title)
              content
          }
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func removeInitWithMultipleViewBuilderParameters() {
    let input = """
      struct TwoColumnView<Left: View, Right: View>: View {
          let left: Left
          let right: Right

          init(@ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
              self.left = left()
              self.right = right()
          }

          var body: some View {
              HStack {
                  left
                  right
              }
          }
      }
      """
    let output = """
      struct TwoColumnView<Left: View, Right: View>: View {
          @ViewBuilder let left: Left
          @ViewBuilder let right: Right

          var body: some View {
              HStack {
                  left
                  right
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWithCustomResultBuilder() {
    let input = """
      struct MyContainer<Content>: View {
          let content: Content

          init(@CustomBuilder content: () -> Content) {
              self.content = content()
          }

          var body: some View {
              // ...
          }
      }
      """
    let output = """
      struct MyContainer<Content>: View {
          @CustomBuilder let content: Content

          var body: some View {
              // ...
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit, options: options, exclude: [.docComments])
  }

  @Test func viewBuilderInitWithOrganizeDeclarationsPreservesPropertyOrder() {
    // When redundantMemberwiseInit removes an init with @ViewBuilder parameters,
    // the property order must be preserved so the synthesized init has the same API.
    // organizeDeclarations runs after redundantMemberwiseInit and should not reorder.
    let input = """
      struct Footer<ActionBar: View>: View {
          init(
              @ViewBuilder actionBar: () -> ActionBar,
              disclaimerText: String?,
              handler: Handler
          ) {
              self.actionBar = actionBar()
              self.disclaimerText = disclaimerText
              self.handler = handler
          }

          var body: some View {
              Text("test")
          }

          @Environment(\\.sizeClass) private var sizeClass

          private let actionBar: ActionBar
          private let disclaimerText: String?
          private let handler: Handler
      }
      """
    let output = """
      struct Footer<ActionBar: View>: View {
          // MARK: Internal

          @ViewBuilder let actionBar: ActionBar
          let disclaimerText: String?
          let handler: Handler

          var body: some View {
              Text("test")
          }

          // MARK: Private

          @Environment(\\.sizeClass) private var sizeClass
      }
      """
    let options = FormatOptions(
      markCategories: true,
      preferSynthesizedInitForInternalStructs: .conformances(["View"]),
      swiftVersion: "6.4"
    )
    testFormatting(
      for: input,
      [output],
      rules: [
        .redundantMemberwiseInit, .organizeDeclarations, .blankLinesAtStartOfScope,
        .blankLinesAtEndOfScope,
      ],
      options: options
    )
  }

  @Test func removeInitWithGenericResultBuilder() {
    let input = """
      struct ItemList {
          let items: [String]

          init(@ArrayBuilder<String> items: () -> [String]) {
              self.items = items()
          }
      }
      """
    let output = """
      struct ItemList {
          @ArrayBuilder<String> let items: [String]
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func doesntApplySynythesizedInitWithResultBuilderInNonGenericTypeSwift6_2() {
    // Result builder properties aren't supported properly in non-generic types before Swift 6.4:
    // https://github.com/swiftlang/swift/pull/86272
    let input = """
      struct ItemList {
          let items: [String]

          init(@ArrayBuilder<String> items: () -> [String]) {
              self.items = items()
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.2")
    testFormatting(for: input, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWithEscapingClosureParameter() {
    // Stored closure properties are implicitly escaping, so @escaping () -> Void parameter
    // is equivalent to () -> Void property.
    let input = """
      struct Button {
          let onTap: () -> Void

          init(onTap: @escaping () -> Void) {
              self.onTap = onTap
          }
      }
      """
    let output = """
      struct Button {
          let onTap: () -> Void
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }
}
