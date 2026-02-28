import Testing
@testable import Swiftiomatic

@Suite struct HoistTryTests {
    @Test func hoistTry() {
        let input = """
        greet(try name(), try surname())
        """
        let output = """
        try greet(name(), surname())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryWithOptionalTry() {
        let input = """
        greet(try name(), try? surname())
        """
        let output = """
        try greet(name(), try? surname())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideStringInterpolation() {
        let input = """
        \"\\(replace(regex: try something()))\"
        """
        let output = """
        try \"\\(replace(regex: something()))\"
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideStringInterpolation2() {
        let input = """
        "Hello \\(try await someValue())"
        """
        let output = """
        try "Hello \\(await someValue())"
        """
        testFormatting(for: input, output, rule: .hoistTry,
                       options: FormatOptions(swiftVersion: "5.5"),
                       exclude: [.hoistAwait])
    }

    @Test func hoistTryInsideStringInterpolation3() {
        let input = """
        let text = "\""
        abc
        \\(try bar())
        xyz
        "\""
        """
        let output = """
        let text = try "\""
        abc
        \\(bar())
        xyz
        "\""
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideStringInterpolation4() {
        let input = """
        let str = "&enrolments[\\(index)][userid]=\\(try Foo.tryMe())"
        """
        let output = """
        let str = try "&enrolments[\\(index)][userid]=\\(Foo.tryMe())"
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideStringInterpolation5() {
        let input = """
        return str +
            "&enrolments[\\(index)][roleid]=\\(MoodleRoles.studentRole.rawValue)" +
            "&enrolments[\\(index)][userid]=\\(try user.requireMoodleID())"
        """
        let output = """
        return try str +
            "&enrolments[\\(index)][roleid]=\\(MoodleRoles.studentRole.rawValue)" +
            "&enrolments[\\(index)][userid]=\\(user.requireMoodleID())"
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideStringInterpolation6() {
        let input = #"""
        """
        let \(object.varName) =
        \(tripleQuote)
        \(try encode(object.object))
        \(tripleQuote)
        """
        """#
        let output = #"""
        try """
        let \(object.varName) =
        \(tripleQuote)
        \(encode(object.object))
        \(tripleQuote)
        """
        """#
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideArgument() {
        let input = """
        array.append(contentsOf: try await asyncFunction(param1: param1))
        """
        let output = """
        try array.append(contentsOf: await asyncFunction(param1: param1))
        """
        testFormatting(for: input, output, rule: .hoistTry, exclude: [.hoistAwait])
    }

    @Test func noHoistTryInsideExpect() {
        let input = """
        #expect(!(try foo()))
        """
        testFormatting(for: input, rule: .hoistTry)
    }

    @Test func noHoistTryInsideRequire() {
        let input = """
        let foo = try #require(try expression() as? Bar, message, file: file, line: line)
        """
        testFormatting(for: input, rule: .hoistTry)
    }

    @Test func noMergeTrysInsideExpect() {
        let input = """
        #expect(try foo() == try bar())
        """
        testFormatting(for: input, rule: .hoistTry)
    }

    @Test func noHoistTryInsideDo() {
        let input = """
        do { rg.box.seal(.fulfilled(try body(error))) }
        """
        let output = """
        do { try rg.box.seal(.fulfilled(body(error))) }
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func noHoistTryInsideDoThrows() {
        let input = """
        do throws(Foo) { rg.box.seal(.fulfilled(try body(error))) }
        """
        let output = """
        do throws(Foo) { try rg.box.seal(.fulfilled(body(error))) }
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func noHoistTryInsideMultilineDo() {
        let input = """
        do {
            rg.box.seal(.fulfilled(try body(error)))
        }
        """
        let output = """
        do {
            try rg.box.seal(.fulfilled(body(error)))
        }
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistedTryPlacedBeforeAwait() {
        let input = """
        let foo = await bar(contentsOf: try baz())
        """
        let output = """
        let foo = try await bar(contentsOf: baz())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInExpressionWithNoSpaces() {
        let input = """
        let foo=bar(contentsOf:try baz())
        """
        let output = """
        let foo=try bar(contentsOf:baz())
        """
        testFormatting(for: input, output, rule: .hoistTry,
                       exclude: [.spaceAroundOperators])
    }

    @Test func hoistTryInExpressionWithExcessSpaces() {
        let input = """
        let foo = bar ( contentsOf: try baz() )
        """
        let output = """
        let foo = try bar ( contentsOf: baz() )
        """
        testFormatting(for: input, output, rule: .hoistTry,
                       exclude: [.spaceAroundParens, .spaceInsideParens])
    }

    @Test func hoistTryWithReturn() {
        let input = """
        return .enumCase(try await service.greet())
        """
        let output = """
        return try .enumCase(await service.greet())
        """
        testFormatting(for: input, output, rule: .hoistTry,
                       exclude: [.hoistAwait])
    }

    @Test func hoistDeeplyNestedTrys() {
        let input = """
        let foo = (bar: (5, (try quux(), 6)), baz: (7, quux: try quux()))
        """
        let output = """
        let foo = try (bar: (5, (quux(), 6)), baz: (7, quux: quux()))
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func tryNotHoistedOutOfClosure() {
        let input = """
        let foo = { (try bar(), 5) }
        """
        let output = """
        let foo = { try (bar(), 5) }
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func tryNotHoistedOutOfClosureWithArguments() {
        let input = """
        let foo = { bar in (try baz(bar), 5) }
        """
        let output = """
        let foo = { bar in try (baz(bar), 5) }
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func tryNotHoistedOutOfForCondition() {
        let input = """
        for foo in bar(try baz()) {}
        """
        let output = """
        for foo in try bar(baz()) {}
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryWithInitAssignment() {
        let input = """
        let variable = String(try await asyncFunction())
        """
        let output = """
        let variable = try String(await asyncFunction())
        """
        testFormatting(for: input, output, rule: .hoistTry,
                       exclude: [.hoistAwait])
    }

    @Test func hoistTryWithAssignment() {
        let input = """
        let variable = (try await asyncFunction())
        """
        let output = """
        let variable = try (await asyncFunction())
        """
        testFormatting(for: input, output, rule: .hoistTry,
                       exclude: [.hoistAwait])
    }

    @Test func hoistTryOnlyOne() {
        let input = """
        greet(name, try surname())
        """
        let output = """
        try greet(name, surname())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryRedundantTry() {
        let input = """
        try greet(try name(), try surname())
        """
        let output = """
        try greet(name(), surname())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryWithAwaitOnDifferentStatement() {
        let input = """
        let asyncVariable = try await performSomething()
        return Foo(param1: try param1())
        """
        let output = """
        let asyncVariable = try await performSomething()
        return try Foo(param1: param1())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryDoubleParens() {
        let input = """
        array.append((value: try compute()))
        """
        let output = """
        try array.append((value: compute()))
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryDoesNothing() {
        let input = """
        try greet(name, surname)
        """
        testFormatting(for: input, rule: .hoistTry)
    }

    @Test func hoistOptionalTryDoesNothing() {
        let input = """
        try? greet(name, surname)
        """
        testFormatting(for: input, rule: .hoistTry)
    }

    @Test func hoistedTryOnLineBeginningWithInfixDot() {
        let input = """
        let foo = bar()
            .baz(try quux())
        """
        let output = """
        let foo = try bar()
            .baz(quux())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistedTryOnLineBeginningWithInfixPlus() {
        let input = """
        let foo = bar()
            + baz(try quux())
        """
        let output = """
        let foo = try bar()
            + baz(quux())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistedTryOnLineBeginningWithPrefixOperator() {
        let input = """
        foo()
        !bar(try quux())
        """
        let output = """
        foo()
        try !bar(quux())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func noHoistTryIntoPreviousLineEndingWithPostfixOperator() {
        let input = """
        let foo = bar!
        (try baz(), quux()).foo()
        """
        let output = """
        let foo = bar!
        try (baz(), quux()).foo()
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func noHoistTryInCapturingFunction() {
        let input = """
        foo(try bar)
        """
        testFormatting(for: input, rule: .hoistTry,
                       options: FormatOptions(throwCapturing: ["foo"]))
    }

    @Test func noHoistSecondArgumentTryInCapturingFunction() {
        let input = """
        foo(bar, try baz)
        """
        testFormatting(for: input, rule: .hoistTry,
                       options: FormatOptions(throwCapturing: ["foo"]))
    }

    @Test func noHoistFailToTerminate() {
        let input = """
        return ManyInitExample(
            a: try Example(string: try throwingExample()),
            b: try throwingExample(),
            c: try throwingExample(),
            d: try throwingExample(),
            e: try throwingExample(),
            f: try throwingExample(),
            g: try throwingExample(),
            h: try throwingExample(),
            i: try throwingExample()
        )
        """
        let output = """
        return try ManyInitExample(
            a: Example(string: throwingExample()),
            b: throwingExample(),
            c: throwingExample(),
            d: throwingExample(),
            e: throwingExample(),
            f: throwingExample(),
            g: throwingExample(),
            h: throwingExample(),
            i: throwingExample()
        )
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideOptionalFunction() {
        let input = """
        foo?(try bar())
        """
        let output = """
        try foo?(bar())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func noHoistTryAfterOptionalTry() {
        let input = """
        let foo = try? bar(try baz())
        """
        testFormatting(for: input, rule: .hoistTry)
    }

    @Test func hoistTryInsideOptionalSubscript() {
        let input = """
        foo?[try bar()]
        """
        let output = """
        try foo?[bar()]
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryAfterGenericType() {
        let input = """
        let foo = Tree<T>.Foo(bar: try baz())
        """
        let output = """
        let foo = try Tree<T>.Foo(bar: baz())
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryAfterArrayLiteral() {
        let input = """
        if [.first, .second].contains(try foo()) {}
        """
        let output = """
        if try [.first, .second].contains(foo()) {}
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryAfterSubscript() {
        let input = """
        if foo[5].bar(try baz()) {}
        """
        let output = """
        if try foo[5].bar(baz()) {}
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideGenericInit() {
        let input = """
        return Target<T>(
            file: try parseFile(path: $0)
        )
        """
        let output = """
        return try Target<T>(
            file: parseFile(path: $0)
        )
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryInsideArrayClosure() {
        let input = """
        foo[bar](try parseFile(path: $0))
        """
        let output = """
        try foo[bar](parseFile(path: $0))
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryAfterString() {
        let input = """
        let json = "{}"

        someFunction(try parse(json), "someKey")
        """
        let output = """
        let json = "{}"

        try someFunction(parse(json), "someKey")
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func hoistTryAfterMultilineString() {
        let input = #"""
        let json = """
        {
          "foo": "bar"
        }
        """

        someFunction(try parse(json), "someKey")
        """#
        let output = #"""
        let json = """
        {
          "foo": "bar"
        }
        """

        try someFunction(parse(json), "someKey")
        """#
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func noHoistTryInTestAttribute() {
        let input = """
        @Test(arguments: [try Identifier(101), nil])
        func testFunction() {}
        """

        let output = """
        @Test(arguments: try [Identifier(101), nil])
        func testFunction() {}
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }

    @Test func correctTryPlacementForWrappedAssert() {
        let input = """
        XCTAssertEqual(Consumer<String>
            .character(in: try foo()))
        """
        let output = """
        XCTAssertEqual(try Consumer<String>
            .character(in: foo()))
        """
        testFormatting(for: input, output, rule: .hoistTry)
    }
}
