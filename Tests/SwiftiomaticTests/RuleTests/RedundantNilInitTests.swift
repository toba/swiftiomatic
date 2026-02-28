import Testing
@testable import Swiftiomatic

@Suite struct RedundantNilInitTests {
    @Test func removeRedundantNilInit() {
        let input = """
        var foo: Int? = nil
        let bar: Int? = nil
        """
        let output = """
        var foo: Int?
        let bar: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveLetNilInitAfterVar() {
        let input = """
        var foo: Int
        let bar: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNonNilInit() {
        let input = """
        var foo: Int? = 0
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func removeRedundantImplicitUnwrapInit() {
        let input = """
        var foo: Int! = nil
        """
        let output = """
        var foo: Int!
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveLazyVarNilInit() {
        let input = """
        lazy var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveLazyPublicPrivateSetVarNilInit() {
        let input = """
        lazy private(set) public var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit, options: options,
            exclude: [.modifierOrder],
        )
    }

    @Test func noRemoveCodableNilInit() {
        let input = """
        struct Foo: Codable, Bar {
            enum CodingKeys: String, CodingKey {
                case bar = \"_bar\"
            }

            var bar: Int?
            var baz: String? = nil
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNilInitWithPropertyWrapper() {
        let input = """
        @Foo var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNilInitWithLowercasePropertyWrapper() {
        let input = """
        @foo var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNilInitWithPropertyWrapperWithArgument() {
        let input = """
        @Foo(bar: baz) var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNilInitWithLowercasePropertyWrapperWithArgument() {
        let input = """
        @foo(bar: baz) var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func removeNilInitWithObjcAttributes() {
        let input = """
        @objc var foo: Int? = nil
        """
        let output = """
        @objc var foo: Int?
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNilInitInStructWithDefaultInit() {
        let input = """
        struct Foo {
            var bar: String? = nil
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func removeNilInitInStructWithDefaultInitInSwiftVersion5_2() {
        let input = """
        struct Foo {
            var bar: String? = nil
        }
        """
        let output = """
        struct Foo {
            var bar: String?
        }
        """
        let options = FormatOptions(nilInit: .remove, swiftVersion: "5.2")
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func removeNilInitInStructWithCustomInit() {
        let input = """
        struct Foo {
            var bar: String? = nil
            init() {
                bar = "bar"
            }
        }
        """
        let output = """
        struct Foo {
            var bar: String?
            init() {
                bar = "bar"
            }
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNilInitInViewBuilder() {
        let input = """
        struct TestView: View {
            var body: some View {
                var foo: String? = nil
                Text(foo ?? "")
            }
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNilInitInIfStatementInViewBuilder() {
        let input = """
        struct TestView: View {
            var body: some View {
                if true {
                    var foo: String? = nil
                    Text(foo ?? "")
                } else {
                    EmptyView()
                }
            }
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noRemoveNilInitInSwitchStatementInViewBuilder() {
        let input = """
        struct TestView: View {
            var body: some View {
                switch foo {
                case .bar:
                    var foo: String? = nil
                    Text(foo ?? "")

                default:
                    EmptyView()
                }
            }
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    // --nilInit insert

    @Test func insertNilInit() {
        let input = """
        var foo: Int?
        let bar: Int? = nil
        """
        let output = """
        var foo: Int? = nil
        let bar: Int? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func insertNilInitBeforeLet() {
        let input = """
        var foo: Int?
        let bar: Int? = nil
        """
        let output = """
        var foo: Int? = nil
        let bar: Int? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func insertNilInitAfterLet() {
        let input = """
        let bar: Int? = nil
        var foo: Int?
        """
        let output = """
        let bar: Int? = nil
        var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNonNilInit() {
        let input = """
        var foo: Int? = 0
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func insertRedundantImplicitUnwrapInit() {
        let input = """
        var foo: Int!
        """
        let output = """
        var foo: Int! = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertLazyVarNilInit() {
        let input = """
        lazy var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertLazyPublicPrivateSetVarNilInit() {
        let input = """
        lazy private(set) public var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit, options: options,
            exclude: [.modifierOrder],
        )
    }

    @Test func noInsertCodableNilInit() {
        let input = """
        struct Foo: Codable, Bar {
            enum CodingKeys: String, CodingKey {
                case bar = \"_bar\"
            }

            var bar: Int?
            var baz: String? = nil
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitWithPropertyWrapper() {
        let input = """
        @Foo var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitWithLowercasePropertyWrapper() {
        let input = """
        @foo var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitWithPropertyWrapperWithArgument() {
        let input = """
        @Foo(bar: baz) var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitWithLowercasePropertyWrapperWithArgument() {
        let input = """
        @foo(bar: baz) var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func insertNilInitWithObjcAttributes() {
        let input = """
        @objc var foo: Int?
        """
        let output = """
        @objc var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitForClosureReturningOptional() {
        let input = """
        private var receiverSelector: @MainActor (IntrospectionPlatformViewController) -> Target?
        private var ancestorSelector: @MainActor (IntrospectionPlatformViewController) -> Target?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options)
    }

    @Test func noInsertNilInitForClosureReturningOptionalWithAsyncThrows() {
        let input = """
        var fetcher: () async throws -> Response?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options)
    }

    @Test func noInsertNilInitForClosureReturningOptionalWithGenericArgument() {
        let input = """
        var reducer: (Result<String, Error>) -> State?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options)
    }

    @Test func noInsertNilInitForClosureReturningOptionalWithNestedClosureParameter() {
        let input = """
        var completion: (@MainActor () async -> Void) -> Result<Void, Error>?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options)
    }

    @Test func insertNilInitForOptionalClosureProperty() {
        let input = """
        var handler: (() -> Void)?
        """
        let output = """
        var handler: (() -> Void)? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitInStructWithDefaultInit() {
        let input = """
        struct Foo {
            var bar: String?
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func insertNilInitInStructWithDefaultInitInSwiftVersion5_2() {
        let input = """
        struct Foo {
            var bar: String?
            var foo: String? = nil
        }
        """
        let output = """
        struct Foo {
            var bar: String? = nil
            var foo: String? = nil
        }
        """
        let options = FormatOptions(nilInit: .insert, swiftVersion: "5.2")
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func insertNilInitInStructWithCustomInit() {
        let input = """
        struct Foo {
            var bar: String?
            var foo: String? = nil
            init() {
                bar = "bar"
                foo = "foo"
            }
        }
        """
        let output = """
        struct Foo {
            var bar: String? = nil
            var foo: String? = nil
            init() {
                bar = "bar"
                foo = "foo"
            }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitInViewBuilder() {
        // Not insert `nil` in result builder
        let input = """
        struct TestView: View {
            var body: some View {
                var foo: String?
                Text(foo ?? "")
            }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitInIfStatementInViewBuilder() {
        // Not insert `nil` in result builder
        let input = """
        struct TestView: View {
            var body: some View {
                if true {
                    var foo: String?
                    Text(foo ?? "")
                } else {
                    EmptyView()
                }
            }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitInSwitchStatementInViewBuilder() {
        // Not insert `nil` in result builder
        let input = """
        struct TestView: View {
            var body: some View {
                switch foo {
                case .bar:
                    var foo: String?
                    Text(foo ?? "")

                default:
                    EmptyView()
                }
            }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitInSingleLineComputedProperty() {
        let input = """
        var bar: String? { "some string" }
        var foo: String? { nil }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options, exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func noInsertNilInitInMultilineComputedProperty() {
        let input = """
        var foo: String? {
            print("some")
        }

        var bar: String? {
            nil
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func noInsertNilInitInCustomGetterAndSetterProperty() {
        let input = """
        var _foo: String? = nil
        var foo: String? {
            set { _foo = newValue }
            get { newValue }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func insertNilInitInInstancePropertyWithBody() {
        let input = """
        var foo: String? {
            didSet { print(foo) }
        }
        """

        let output = """
        var foo: String? = nil {
            didSet { print(foo) }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options, exclude: [.wrapPropertyBodies],
        )
    }

    @Test func noInsertNilInitInAs() {
        let input = """
        let json: Any = ["key": 1]
        var jsonObject = json as? [String: Int]
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(
            for: input, rule: .redundantNilInit,
            options: options,
        )
    }

    @Test func removeRedundantNilInitInSubclass() {
        let input = """
        class SomeClass2: SomeClass {
            var optionalString2: String? = nil
        }
        """
        let output = """
        class SomeClass2: SomeClass {
            var optionalString2: String?
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(
            for: input, output, rule: .redundantNilInit,
            options: options,
        )
    }
}
