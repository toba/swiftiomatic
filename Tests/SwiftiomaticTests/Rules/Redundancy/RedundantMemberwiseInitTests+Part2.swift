import Testing
@testable import Swiftiomatic

extension RedundantMemberwiseInitTests {
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent, .propertyTypes],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent, .wrapArguments],
        )
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
            exclude: [.indent, .acronyms, .blankLinesAtStartOfScope],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            ],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
    }

}
