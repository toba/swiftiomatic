@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct EnvironmentEntryTests: RuleTesting {

  @Test func basicKeyBeforeExtension() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }

        extension EnvironmentValues {
            1️⃣var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry var screenName: Identifier? = .init("undefined")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func keyAfterExtension() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        extension EnvironmentValues {
            1️⃣var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }

        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry var screenName: Identifier? = .init("undefined")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func multipleKeysAndExtensions() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        extension EnvironmentValues {
            1️⃣var isSelected: Bool {
                get { self[IsSelectedEnvironmentKey.self] }
                set { self[IsSelectedEnvironmentKey.self] = newValue }
            }
        }

        struct IsSelectedEnvironmentKey: EnvironmentKey {
            static var defaultValue: Bool { false }
        }

        extension EnvironmentValues {
            2️⃣var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }

        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry var isSelected: Bool = false
        }

        extension EnvironmentValues {
            @Entry var screenName: Identifier? = .init("undefined")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
        FindingSpec("2️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func multiplePropertiesInSameExtension() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        extension EnvironmentValues {
            1️⃣var isSelected: Bool {
                get { self[IsSelectedEnvironmentKey.self] }
                set { self[IsSelectedEnvironmentKey.self] = newValue }
            }

            2️⃣var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }

        struct IsSelectedEnvironmentKey: EnvironmentKey {
            static var defaultValue: Bool { false }
        }

        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry var isSelected: Bool = false

            @Entry var screenName: Identifier? = .init("undefined")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
        FindingSpec("2️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func keyNameDoesNotMatch() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        extension EnvironmentValues {
            var isSelected: Bool {
                get { self[IsSelectedEnvironmentKey.self] }
                set { self[IsSelectedEnvironmentKey.self] = newValue }
            }
        }

        struct SelectedEnvironmentKey: EnvironmentKey {
            static var defaultValue: Bool { false }
        }
        """,
      expected: """
        extension EnvironmentValues {
            var isSelected: Bool {
                get { self[IsSelectedEnvironmentKey.self] }
                set { self[IsSelectedEnvironmentKey.self] = newValue }
            }
        }

        struct SelectedEnvironmentKey: EnvironmentKey {
            static var defaultValue: Bool { false }
        }
        """,
      findings: []
    )
  }

  @Test func multiLineDefaultValueWrappedInClosure() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                let domain = "com.mycompany.myapp"
                let base = "undefined"
                return .init("\\(domain).\\(base)")
            }
        }

        extension EnvironmentValues {
            1️⃣var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry var screenName: Identifier? = {
                let domain = "com.mycompany.myapp"
                let base = "undefined"
                return .init("\\(domain).\\(base)")
            }()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func implicitNilDefaultValue() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier?
        }

        extension EnvironmentValues {
            1️⃣var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry var screenName: Identifier?
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func commentsOnPropertyPreserved() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }

        extension EnvironmentValues {
            /// The name provided to the outer most view representing a full screen width
            1️⃣var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            /// The name provided to the outer most view representing a full screen width
            @Entry var screenName: Identifier? = .init("undefined")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func nonComputedDefaultValue() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        struct ScreenStyleEnvironmentKey: EnvironmentKey {
            static var defaultValue: ScreenStyle = ScreenStyle()
        }

        extension EnvironmentValues {
            1️⃣var screenStyle: ScreenStyle {
                get { self[ScreenStyleEnvironmentKey.self] }
                set { self[ScreenStyleEnvironmentKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry var screenStyle: ScreenStyle = ScreenStyle()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func publicAccessModifierPreserved() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        struct ScreenStyleEnvironmentKey: EnvironmentKey {
            static var defaultValue: ScreenStyle { .init() }
        }

        extension EnvironmentValues {
            1️⃣public var screenStyle: ScreenStyle {
                get { self[ScreenStyleEnvironmentKey.self] }
                set { self[ScreenStyleEnvironmentKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry public var screenStyle: ScreenStyle = .init()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func keyWithoutEnvironmentKeySuffix() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        struct ScreenStyle: EnvironmentKey {
            static var defaultValue: Style { .init() }
        }

        extension EnvironmentValues {
            1️⃣public var screenStyle: Style {
                get { self[ScreenStyle.self] }
                set { self[ScreenStyle.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry public var screenStyle: Style = .init()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func enumEnvironmentKey() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        private enum InputShouldChangeKey: EnvironmentKey {
            static var defaultValue: InputShouldChangeHandler { nil }
        }

        extension EnvironmentValues {
            1️⃣public var inputShouldChange: InputShouldChangeHandler {
                get { self[InputShouldChangeKey.self] }
                set { self[InputShouldChangeKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry public var inputShouldChange: InputShouldChangeHandler = nil
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func letDefaultValue() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        private struct ScreenStyleKey: EnvironmentKey {
            static let defaultValue: Style = .init()
        }

        extension EnvironmentValues {
            1️⃣public var screenStyle: Style {
                get { self[ScreenStyleKey.self] }
                set { self[ScreenStyleKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry public var screenStyle: Style = .init()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func defaultValueWithoutExplicitType() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        private struct ScreenStyleKey: EnvironmentKey {
            static let defaultValue = Style()
        }

        extension EnvironmentValues {
            1️⃣public var screenStyle: Style {
                get { self[ScreenStyleKey.self] }
                set { self[ScreenStyleKey.self] = newValue }
            }
        }
        """,
      expected: """
        extension EnvironmentValues {
            @Entry public var screenStyle: Style = Style()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"),
      ]
    )
  }

  @Test func propertyWithoutSetterNotModified() {
    assertFormatting(
      PreferEnvironmentEntry.self,
      input: """
        struct AEnvironmentKey: EnvironmentKey {
            static var defaultValue: A = .default
        }

        extension EnvironmentValues {
            public var fallbackA: A {
                if self[AEnvironmentKey.self] {
                    A()
                } else {
                    something()
                }
            }
        }
        """,
      expected: """
        struct AEnvironmentKey: EnvironmentKey {
            static var defaultValue: A = .default
        }

        extension EnvironmentValues {
            public var fallbackA: A {
                if self[AEnvironmentKey.self] {
                    A()
                } else {
                    something()
                }
            }
        }
        """,
      findings: []
    )
  }
}
