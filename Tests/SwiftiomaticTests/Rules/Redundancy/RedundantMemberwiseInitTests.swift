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
            for: input, output, rule: .redundantMemberwiseInit, exclude: [.redundantFileprivate],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
        testFormatting(
            for: input,
            output,
            rule: .redundantMemberwiseInit,
            exclude: [.redundantSelf],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            ],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
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
            exclude: [.redundantSelf, .trailingSpace, .indent],
        )
    }

}
