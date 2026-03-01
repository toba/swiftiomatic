import Testing
@testable import Swiftiomatic

extension TrailingCommasTests {
    @Test func trailingCommasPreservedInOptionalClosureTypeInSwift6_1() {
        let input = """
        public func requestLocationAuthorizationAndAccuracy(completion _: (
            (
                _ authorizationStatus: CLAuthorizationStatus?,
                _ accuracyAuthorization: CLAccuracyAuthorization?,
                _ error: LocationServiceError?
            ) -> Void
        )?) {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasPreservedInClosureTupleTypealiasesInSwift6_1() {
        let input = """
        public typealias StringToInt = (
            String
        ) -> Int

        public enum Toster {
            public typealias StringToInt = ((
                String
            ) -> Int)?
        }

        public typealias Tuple = (
            foo: String,
            bar: Int
        )

        public typealias OptionalTuple = (
            foo: String,
            bar: Int,
            baaz: Bool
        )?
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToReturnTuple() {
        let input = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz
            )
        }
        """
        let output = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromReturnTuple() {
        let input = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz,
            )
        }
        """
        let output = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz
            )
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToThrow() {
        let input = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar
            )
        }
        """
        let output = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromThrow() {
        let input = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar,
            )
        }
        """
        let output = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar
            )
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToSwitch() {
        let input = """
        let foo = (
            bar: 0,
            baz: 1
        )
        switch (
            foo.bar,
            foo.baz
        ) {
        case (
            0,
            1
        ): break
        default: break
        }
        """
        let output = """
        let foo = (
            bar: 0,
            baz: 1,
        )
        switch (
            foo.bar,
            foo.baz,
        ) {
        case (
            0,
            1,
        ): break
        default: break
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasNotAddedToTypeAnnotation() {
        let input = """
        let foo: (
            bar: Int,
            baz: Int
        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromCaseLet() {
        let input = """
        let foo = (0, 1)
        switch foo {
        case let (
            bar,
            baz,
        ): break
        }
        """
        let output = """
        let foo = (0, 1)
        switch foo {
        case let (
            bar,
            baz
        ): break
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommaRemovedFromDestructuringLetTuple() {
        let input = """
        let (
            foo,
            bar,
        ) = (0, 1)
        """
        let output = """
        let (
            foo,
            bar
        ) = (0, 1)
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(
            for: input, output, rule: .trailingCommas, options: options,
            exclude: [.singlePropertyPerLine],
        )
    }

    @Test func trailingCommasNotAddedToEmptyParentheses() {
        let input = """
        let foo = (

        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(
            for: input, rule: .trailingCommas,
            options: options,
            exclude: [
                .blankLinesAtEndOfScope,
                .blankLinesAtStartOfScope,
            ],
        )
    }

    @Test func trailingCommasRemovedFromStringInterpolation() {
        let input = """
        let foo = \"""
        Foo: \\(
            1,
            2,
        )
        \"""
        """
        let output = """
        let foo = \"""
        Foo: \\(
            1,
            2
        )
        \"""
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToAttribute() {
        let input = """
        @Foo(
            "bar",
            "baz"
        )
        struct Qux {}
        """
        let output = """
        @Foo(
            "bar",
            "baz",
        )
        struct Qux {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasNotAddedToBuiltInAttributesInSwift6_1() {
        // Built-in attributes unexpectedly don't support trailing commas in Swift 6.1.
        // Property wrappers and macros are supported properly.
        // https://github.com/swiftlang/swift/issues/81475
        let input = """
        @available(
            *,
            deprecated,
            renamed: "bar"
        )
        func foo() {}

        @backDeployed(
            before: iOS 17 // trailing comma not allowed
        )
        public func foo() {}

        @objc(
            custom_objc_name
        )
        class MyClass: NSObject()

        @freestanding(
            declaration,
            names: named(CodingKeys)
        )
        macro FreestandingMacro() = #externalMacro(module: "Macros", type: "")

        @attached(
            extension,
            names: arbitrary
        )
        macro AttachedMacro() = #externalMacro(module: "Macros", type: "")

        @_originallyDefinedIn(
            module: "Foo",
            macOS 10.0
        )
        extension CoreFoundation.CGFloat: Swift.SignedNumeric {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasNotAddedToBuiltInAttributesInSwift6_1_multiElementList() {
        // Built-in attributes unexpectedly don't support trailing commas in Swift 6.1.
        // Property wrappers and macros are supported properly.
        // https://github.com/swiftlang/swift/issues/81475
        let input = """
        @available(
            *,
            deprecated,
            renamed: "bar"
        )
        func foo() {}

        @objc(
            custom_objc_name
        )
        class MyClass: NSObject()
        """

        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromAttribute() {
        let input = """
        @Foo(
            "bar",
            "baz",
        )
        struct Qux {}
        """
        let output = """
        @Foo(
            "bar",
            "baz"
        )
        struct Qux {}
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToMacro() {
        let input = """
        #foo(
            "bar",
            "baz"
        )
        """
        let output = """
        #foo(
            "bar",
            "baz",
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromMacro() {
        let input = """
        #foo(
            "bar",
            "baz",
        )
        """
        let output = """
        #foo(
            "bar",
            "baz"
        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToGenericList() {
        let input = """
        struct S<
            T1,
            T2,
            T3
        > {}

        typealias T<
            T1,
            T2
        > = S<T1, T2, Bool>

        func foo<
            T1,
            T2,
        >() -> (T1, T2) {}
        """
        let output = """
        struct S<
            T1,
            T2,
            T3,
        > {}

        typealias T<
            T1,
            T2,
        > = S<T1, T2, Bool>

        func foo<
            T1,
            T2,
        >() -> (T1, T2) {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasNotAddedToGenericTypesInSwift6_1() {
        // Trailing commas are not supported in types in Swift 6.1
        // https://github.com/swiftlang/swift/issues/81474
        let input = """
        public final class TestThing: GenericThing<
            Test1,
            Test2,
            Test3
        > {}

        func foo(_: GenericThing<
            Test1,
            Test2,
            Test3
        >) {}

        typealias T<
            T1,
            T2,
        > = S<
            T1,
            T2,
            Bool
        >

        extension Dictionary<
            String,
            Any
        > {}

        protocol MyProtocolWithAssociatedTypes<
            Foo,
            Bar
        > {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(
            for: input, rule: .trailingCommas, options: options, exclude: [
                .emptyExtensions,
                .typeSugar,
            ],
        )
    }

    @Test func trailingCommasRemovedFromGenericList() {
        let input = """
        struct S<
            T1,
            T2,
            T3,
        > {}
        """
        let output = """
        struct S<
            T1,
            T2,
            T3
        > {}
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromSingleLineGenericList() {
        let input = """
        struct S<T1, T2, T3,> {}
        """
        let output = """
        struct S<T1, T2, T3> {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToCaptureList() {
        let input = """
        { [
            capturedValue1,
            capturedValue2
        ] in
        }
        """
        let output = """
        { [
            capturedValue1,
            capturedValue2,
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromSingleElementCaptureList() {
        let input = """
        { [
            capturedValue1,
        ] in
        }
        """
        let output = """
        { [
            capturedValue1
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromCaptureList() {
        let input = """
        { [
            capturedValue1,
            capturedValue2,
        ] in
        }
        """
        let output = """
        { [
            capturedValue1,
            capturedValue2
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromSingleLineCaptureList() {
        let input = """
        { [capturedValue1, capturedValue2,] in
            print(capturedValue1, capturedValue2)
        }
        """
        let output = """
        { [capturedValue1, capturedValue2] in
            print(capturedValue1, capturedValue2)
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasAddedToSubscript() {
        let input = """
        let value = m[
            x,
            y
        ]
        """
        let output = """
        let value = m[
            x,
            y,
        ]
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemoveFromSubscriptWhenCollectionsOnly() {
        let input = """
        let value = m[
            x,
            y,
        ]
        """
        let output = """
        let value = m[
            x,
            y
        ]
        """
        let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromSubscript() {
        let input = """
        let value = m[
            x,
            y,
        ]
        """
        let output = """
        let value = m[
            x,
            y
        ]
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasRemovedFromSingleLineSubscript() {
        let input = """
        let value = m[x, y,]
        """
        let output = """
        let value = m[x, y]
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func addingTrailingCommaDoesNotConflictWithOpaqueGenericParametersRule() {
        let input = """
        private func foo<
            Foo: Bar,
            Bar: Baaz
        >(a: Foo, b: Foo)
            where Foo == Bar
        {
            print(a, b)
        }
        """

        let output = """
        private func foo<
            Foo: Bar,
            Bar: Baaz,
        >(a: Foo, b: Foo)
            where Foo == Bar
        {
            print(a, b)
        }
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func singleLineArrayWithMultipleElements() {
        let input = """
        for file in files where
            file != "build" && !file.hasPrefix(".") && ![
                ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
            ].contains(where: { file.hasSuffix($0) }) {}
        """

        let options = FormatOptions(trailingCommas: .always)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func singleLineArrayWithMultipleElementsFollowingNotOperator() {
        let input = """
        for file in files where
            file != "build" && !file.hasPrefix(".") && ![
                ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
            ].contains(where: { file.hasSuffix($0) }) {}
        """

        let options = FormatOptions(trailingCommas: .always)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func singleLineArrayWithMultipleElementsFollowingForceTry() {
        let input = """
        let foo = try! [
            ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
        ].throwingOperation()

        let bar = try? [
            ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
        ].throwingOperation()
        """

        let options = FormatOptions(trailingCommas: .always)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    @Test func collectionsOnlyAddsCollectionCommasAndRemovesNonCollectionCommas() {
        let input = """
        let array = [
            1,
            2
        ]

        func foo(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let output = """
        let array = [
            1,
            2,
        ]

        func foo(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    @Test func trailingCommasNotRemovedFromInitParametersWithAlwaysOption() {
        let input = """
        public init(
            parameter: Parameter,
        ) {
            // test
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(
            for: input,
            rule: .trailingCommas,
            options: options,
            exclude: [.unusedArguments],
        )
    }

}
