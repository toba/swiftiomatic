import Testing
@testable import Swiftiomatic

extension TrailingCommasTests {
    @Test func trailingCommasAddedToInitParametersWithAlwaysOption() {
        let input = """
        public init(
            parameter: Parameter
        ) {
            // test
        }
        """
        let output = """
        public init(
            parameter: Parameter,
        ) {
            // test
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(
            for: input, output, rule: .trailingCommas, options: options,
            exclude: [.unusedArguments],
        )
    }

    // MARK: - Multi-element lists tests

    @Test func multiElementListsAddsCommaToMultiElementArray() {
        let input = """
        let array = [
            1,
            2
        ]
        """
        let output = """
        let array = [
            1,
            2,
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsDoesNotAddCommaToSingleElementArray() {
        let input = """
        let array = [
            1
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsAddsCommaToMultiElementFunction() {
        let input = """
        func foo(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let output = """
        func foo(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsDoesNotAddCommaToSingleElementFunction() {
        let input = """
        func foo(
            a: Int
        ) {
            print(a)
        }

        init(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsAddsCommaToMultiElementFunctionCall() {
        let input = """
        foo(
            a: 1,
            b: 2
        )
        """
        let output = """
        foo(
            a: 1,
            b: 2,
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsDoesNotAddCommaToSingleElementFunctionCall() {
        let input = """
        foo(
            a: 1
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsAddsCommaToMultiElementGenericList() {
        let input = """
        struct Foo<
            T,
            U
        > {}
        """
        let output = """
        struct Foo<
            T,
            U,
        > {}
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsDoesNotAddCommaToSingleElementGenericList() {
        let input = """
        struct Foo<
            T
        > {}
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsRemovesCommaFromSingleElementArray() {
        let input = """
        let array = [
            1,
        ]
        """
        let output = """
        let array = [
            1
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsRemovesCommaFromSingleElementFunction() {
        let input = """
        func foo(
            a: Int,
        ) {
            print(a)
        }
        """
        let output = """
        func foo(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsRemovesCommaFromSingleElementInit() {
        let input = """
        public init(
            a: Int,
        ) {
            print(a)
        }
        """
        let output = """
        public init(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsAddCommaToInit() {
        let input = """
        public init(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let output = """
        public init(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommaNotRemovedFromTupleAndClosureTypesSwift6_1() {
        let input = """
        let foo: (
            bar: String,
            quux: String,
        )

        let bar: (
            bar: String,
            baaz: String,
        ) -> Void

        public @Test func closureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommaNotAddedToTupleAndClosureTypesSwift6_1() {
        let input = """
        let foo: (
            bar: String,
            quux: String
        )

        let bar: (
            bar: String,
            baaz: String
        ) -> Void

        public @Test func closureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsTrailingCommaNotRemovedFromClosureTypeSwift6_1() {
        let input = """
        let foo: (
            bar: String,
        ) -> Void

        let foo: (
            bar: String,
            baaz: String,
        ) -> Void
        """
        let output = """
        let foo: (
            bar: String
        ) -> Void

        let foo: (
            bar: String,
            baaz: String,
        ) -> Void
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func multiElementListsTrailingCommaNotAddedToTupleAndClosureTypesSwift6_1() {
        let input = """
        let bar: (
            bar: String,
            baaz: String
        )

        let bar: (
            bar: String,
            baaz: String
        ) -> Void
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToOptionalClosureCall() {
        let input = """
        myClosure?(
            foo: 5,
            bar: 10
        )
        """
        let output = """
        myClosure?(
            foo: 5,
            bar: 10,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromOptionalClosureCall() {
        let input = """
        myClosure!(
            foo: 5,
            bar: 10,
        )
        """
        let output = """
        myClosure!(
            foo: 5,
            bar: 10
        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToOptionalClosureCallSingleParameter() {
        let input = """
        myClosure?(
            foo: 5
        )
        """
        let output = """
        myClosure?(
            foo: 5,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasMultiElementListsOptionalClosureCall() {
        let input = """
        myClosure?(
            foo: 5,
        )

        otherClosure?(
            foo: 5,
            bar: 10
        )
        """
        let output = """
        myClosure?(
            foo: 5
        )

        otherClosure?(
            foo: 5,
            bar: 10,
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasInTupleTypeCastNotRemovedSwift6_1() {
        // Unexpectedly not supported in Swift 6.1
        let input = """
        let foo = bar as? (
            Foo,
            Bar
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func issue2142() {
        let input = """
        public func bindExitButton<T: Presenter>(
            action: T.Action,
            withIdentifier identifier: UIAction.Identifier? = nil,
            on controlEvents: UIControl.Event = .primaryActionTriggered,
            to presenter: T,
        ) {
            _ = action
            _ = identifier
            _ = controlEvents
            _ = presenter
        }

        let setModeSwizzle = Swizzle<AVAudioSession>(
            instance: instance,
            original: #selector(AVAudioSession.setMode(_:)),
            swizzled: #selector(AVAudioSession.swizzled_setMode(_:)),
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(
            for: input,
            rule: .trailingCommas,
            options: options,
            exclude: [.propertyTypes],
        )
    }

    @Test func issue2143() {
        let input = """
        public @Test func closureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToFunctionParametersSwift6_2() {
        let input = """
        struct Foo {
            func foo(
                bar: Int,
                baaz: Int
            ) -> Int {
                bar + baaz
            }
        }
        """
        let output = """
        struct Foo {
            func foo(
                bar: Int,
                baaz: Int,
            ) -> Int {
                bar + baaz
            }
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToGenericFunctionParametersSwift6_2() {
        let input = """
        struct Foo {
            func foo<
                Bar,
                Baaz
            >(
                bar: Bar,
                baaz: Baaz
            ) -> Int {
                bar + baaz
            }
        }
        """
        let output = """
        struct Foo {
            func foo<
                Bar,
                Baaz,
            >(
                bar: Bar,
                baaz: Baaz,
            ) -> Int {
                bar + baaz
            }
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(
            for: input, output, rule: .trailingCommas, options: options,
            exclude: [.opaqueGenericParameters],
        )
    }

    @Test func trailingCommasAddedToFunctionArgumentsSwift6_2() {
        let input = """
        foo(
            bar _: Int
        ) {}
        """
        let output = """
        foo(
            bar _: Int,
        ) {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

}
