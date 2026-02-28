import Testing
@testable import Swiftiomatic

@Suite struct RedundantReturnTests {
    @Test func removeRedundantReturnInClosure() {
        let input = """
        foo(with: { return 5 })
        """
        let output = """
        foo(with: { 5 })
        """
        testFormatting(for: input, output, rule: .redundantReturn, exclude: [.trailingClosures])
    }

    @Test func removeRedundantReturnInClosureWithArgs() {
        let input = """
        foo(with: { foo in return foo })
        """
        let output = """
        foo(with: { foo in foo })
        """
        testFormatting(for: input, output, rule: .redundantReturn, exclude: [.trailingClosures])
    }

    @Test func removeRedundantReturnInMap() {
        let input = """
        let foo = bar.map { return 1 }
        """
        let output = """
        let foo = bar.map { 1 }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    @Test func noRemoveReturnInComputedVar() {
        let input = """
        var foo: Int { return 5 }
        """
        testFormatting(
            for: input, rule: .redundantReturn, exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func removeReturnInComputedVar() {
        let input = """
        var foo: Int { return 5 }
        """
        let output = """
        var foo: Int { 5 }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, output, rule: .redundantReturn, options: options,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func noRemoveReturnInGet() {
        let input = """
        var foo: Int {
            get { return 5 }
            set { _foo = newValue }
        }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    @Test func removeReturnInGet() {
        let input = """
        var foo: Int {
            get { return 5 }
            set { _foo = newValue }
        }
        """
        let output = """
        var foo: Int {
            get { 5 }
            set { _foo = newValue }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    @Test func noRemoveReturnInGetClosure() {
        let input = """
        let foo = get { return 5 }
        """
        let output = """
        let foo = get { 5 }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    @Test func removeReturnInVarClosure() {
        let input = """
        var foo = { return 5 }()
        """
        let output = """
        var foo = { 5 }()
        """
        testFormatting(for: input, output, rule: .redundantReturn, exclude: [.redundantClosure])
    }

    @Test func removeReturnInParenthesizedClosure() {
        let input = """
        var foo = ({ return 5 }())
        """
        let output = """
        var foo = ({ 5 }())
        """
        testFormatting(
            for: input, output, rule: .redundantReturn, exclude: [
                .redundantParens,
                .redundantClosure,
            ],
        )
    }

    @Test func noRemoveReturnInFunction() {
        let input = """
        func foo() -> Int { return 5 }
        """
        testFormatting(
            for: input, rule: .redundantReturn, exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func removeReturnInFunction() {
        let input = """
        func foo() -> Int { return 5 }
        """
        let output = """
        func foo() -> Int { 5 }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, output, rule: .redundantReturn, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noRemoveReturnInOperatorFunction() {
        let input = """
        func + (lhs: Int, rhs: Int) -> Int { return 5 }
        """
        testFormatting(
            for: input, rule: .redundantReturn, exclude: [.unusedArguments, .wrapFunctionBodies],
        )
    }

    @Test func removeReturnInOperatorFunction() {
        let input = """
        func + (lhs: Int, rhs: Int) -> Int { return 5 }
        """
        let output = """
        func + (lhs: Int, rhs: Int) -> Int { 5 }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, output, rule: .redundantReturn, options: options,
            exclude: [.unusedArguments, .wrapFunctionBodies],
        )
    }

    @Test func noRemoveReturnInFailableInit() {
        let input = """
        init?() { return nil }
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.wrapFunctionBodies])
    }

    @Test func noRemoveReturnInFailableInitWithConditional() {
        let input = """
        init?(optionalHex: String?) {
            if let optionalHex {
                self.init(hex: optionalHex)
            } else {
                return nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func noRemoveReturnInFailableInitWithNestedConditional() {
        let input = """
        init?(optionalHex: String?) {
            if let optionalHex {
                self.init(hex: optionalHex)
            } else {
                switch foo {
                case .foo:
                    self.init()
                case .bar:
                    return nil
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func removeReturnInFailableInit() {
        let input = """
        init?() { return nil }
        """
        let output = """
        init?() { nil }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, output, rule: .redundantReturn, options: options,
            exclude: [.wrapFunctionBodies],
        )
    }

    @Test func noRemoveReturnInSubscript() {
        let input = """
        subscript(index: Int) -> String { return nil }
        """
        testFormatting(
            for: input, rule: .redundantReturn, exclude: [.unusedArguments, .wrapFunctionBodies],
        )
    }

    @Test func removeReturnInSubscript() {
        let input = """
        subscript(index: Int) -> String { return nil }
        """
        let output = """
        subscript(index: Int) -> String { nil }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, output, rule: .redundantReturn, options: options,
            exclude: [.unusedArguments, .wrapFunctionBodies],
        )
    }

    @Test func noRemoveReturnInDoCatch() {
        let input = """
        func foo() -> Int {
            do {
                return try Bar()
            } catch {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func noRemoveReturnInDoThrowsCatch() {
        let input = """
        func foo() -> Int {
            do throws(Foo) {
                return try Bar()
            } catch {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func noRemoveReturnInDoCatchLet() {
        let input = """
        func foo() -> Int {
            do {
                return try Bar()
            } catch let e as Error {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func noRemoveReturnInDoThrowsCatchLet() {
        let input = """
        func foo() -> Int {
            do throws(Foo) {
                return try Bar()
            } catch let e as Error {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func noRemoveReturnInForIn() {
        let input = """
        for foo in bar { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.wrapLoopBodies])
    }

    @Test func noRemoveReturnInForWhere() {
        let input = """
        for foo in bar where baz { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.wrapLoopBodies])
    }

    @Test func noRemoveReturnInIfLetTry() {
        let input = """
        if let foo = try? bar() { return 5 }
        """
        testFormatting(
            for: input, rule: .redundantReturn,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func noRemoveReturnInMultiIfLetTry() {
        let input = """
        if let foo = bar, let bar = baz { return 5 }
        """
        testFormatting(
            for: input, rule: .redundantReturn,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func noRemoveReturnAfterMultipleAs() {
        let input = """
        if foo as? bar as? baz { return 5 }
        """
        testFormatting(
            for: input, rule: .redundantReturn,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func removeVoidReturn() {
        let input = """
        { _ in return }
        """
        let output = """
        { _ in }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    @Test func noRemoveReturnAfterKeyPath() {
        let input = """
        func foo() { if bar == #keyPath(baz) { return 5 } }
        """
        testFormatting(
            for: input, rule: .redundantReturn,
            exclude: [.wrapConditionalBodies, .wrapFunctionBodies],
        )
    }

    @Test func noRemoveReturnAfterParentheses() {
        let input = """
        if let foo = (bar as? String) { return foo }
        """
        testFormatting(
            for: input, rule: .redundantReturn,
            exclude: [.redundantParens, .wrapConditionalBodies],
        )
    }

    @Test func removeReturnInTupleVarGetter() {
        let input = """
        var foo: (Int, Int) { return (1, 2) }
        """
        let output = """
        var foo: (Int, Int) { (1, 2) }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, output, rule: .redundantReturn, options: options,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func noRemoveReturnInIfLetWithNoSpaceAfterParen() {
        let input = """
        var foo: String? {
            if let bar = baz(){
                return bar
            } else {
                return nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, rule: .redundantReturn, options: options,
            exclude: [.spaceAroundBraces, .spaceAroundParens],
        )
    }

    @Test func noRemoveReturnInIfWithUnParenthesizedClosure() {
        let input = """
        if foo { $0.bar } {
            return true
        }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    @Test func removeBlankLineWithReturn() {
        let input = """
        foo {
            return
                bar
        }
        """
        let output = """
        foo {
            bar
        }
        """
        testFormatting(
            for: input, output, rule: .redundantReturn,
            exclude: [.indent],
        )
    }

    @Test func removeRedundantReturnInFunctionWithWhereClause() {
        let input = """
        func foo<T>(_ name: String) -> T where T: Equatable {
            return name
        }
        """
        let output = """
        func foo<T>(_ name: String) -> T where T: Equatable {
            name
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, output, rule: .redundantReturn,
            options: options, exclude: [.simplifyGenericConstraints],
        )
    }

    @Test func removeRedundantReturnInSubscriptWithWhereClause() {
        let input = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            return name
        }
        """
        let output = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            name
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(
            for: input, output, rule: .redundantReturn,
            options: options, exclude: [.simplifyGenericConstraints],
        )
    }

    @Test func noRemoveReturnFollowedByMoreCode() {
        let input = """
        var foo: Bar = {
            return foo
            let bar = baz
            return bar
        }()
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.redundantProperty])
    }

    @Test func noRemoveReturnInForWhereLoop() {
        let input = """
        func foo() -> Bool {
            for bar in baz where !bar {
                return false
            }
            return true
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func redundantReturnInVoidFunction() {
        let input = """
        func foo() {
            return
        }
        """
        let output = """
        func foo() {
        }
        """
        testFormatting(
            for: input, output, rule: .redundantReturn,
            exclude: [.emptyBraces],
        )
    }

    @Test func redundantReturnInVoidFunction2() {
        let input = """
        func foo() {
            print("")
            return
        }
        """
        let output = """
        func foo() {
            print("")
        }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    @Test func redundantReturnInVoidFunction3() {
        let input = """
        func foo() {
            // empty
            return
        }
        """
        let output = """
        func foo() {
            // empty
        }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    @Test func redundantReturnInVoidFunction4() {
        let input = """
        func foo() {
            return // empty
        }
        """
        let output = """
        func foo() {
            // empty
        }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    @Test func noRemoveVoidReturnInCatch() {
        let input = """
        func foo() {
            do {
                try Foo()
            } catch Feature.error {
                print("feature error")
                return
            }
            print("foo")
        }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    @Test func noRemoveReturnInIfCase() {
        let input = """
        var isSessionDeinitializedError: Bool {
            if case .sessionDeinitialized = self { return true }
            return false
        }
        """
        testFormatting(
            for: input, rule: .redundantReturn,
            options: FormatOptions(swiftVersion: "5.1"),
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func noRemoveReturnInForCasewhere() {
        let input = """
        for case let .identifier(name) in formatter.tokens[startIndex ..< endIndex]
            where names.contains(name)
        {
            return true
        }
        """
        testFormatting(
            for: input, rule: .redundantReturn,
            options: FormatOptions(swiftVersion: "5.1"),
        )
    }

    @Test func noRemoveRequiredReturnInFunctionInsideClosure() {
        let input = """
        foo {
            func bar() -> Bar {
                let bar = Bar()
                return bar
            }
        }
        """
        testFormatting(
            for: input, rule: .redundantReturn,
            options: FormatOptions(swiftVersion: "5.1"), exclude: [.redundantProperty],
        )
    }

    @Test func noRemoveRequiredReturnInIfClosure() {
        let input = """
        func findButton() -> Button? {
            let btns = [top, content, bottom]
            if let btn = btns.first { !$0.isHidden && $0.alpha > 0.01 } {
                return btn
            }
            return btns.first
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func noRemoveRequiredReturnInIfClosure2() {
        let input = """
        func findButton() -> Button? {
            let btns = [top, content, bottom]
            if let foo, let btn = btns.first { !$0.isHidden && $0.alpha > 0.01 } {
                return btn
            }
            return btns.first
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func removeRedundantReturnInIfClosure() {
        let input = """
        func findButton() -> Button? {
            let btns = [top, content, bottom]
            if let btn = btns.first { return !$0.isHidden && $0.alpha > 0.01 } {
                print("hello")
            }
            return btns.first
        }
        """
        let output = """
        func findButton() -> Button? {
            let btns = [top, content, bottom]
            if let btn = btns.first { !$0.isHidden && $0.alpha > 0.01 } {
                print("hello")
            }
            return btns.first
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    @Test func disableNextRedundantReturn() {
        let input = """
        func foo() -> Foo {
            // sm:disable:next redundantReturn
            return Foo()
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func redundantIfStatementReturnSwift5_8() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition {
                return "foo"
            } else {
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(
            for: input, rule: .redundantReturn,
            options: options,
        )
    }

    @Test func redundantIfStatementWithClosureCondition() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition, { true }(), { false }() {
                return "foo"
            } else {
                return "bar"
            }
        }
        """

        let output = """
        func foo(condition: Bool) -> String {
            if condition, { true }(), { false }() {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output], rules: [.redundantReturn, .conditionalAssignment],
            options: options,
            exclude: [.redundantClosure],
        )
    }

    @Test func nonRedundantIfStatementReturnSwift5_9() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition {
                return "foo"
            } else if !condition {
                return "bar"
            }
            return "baaz"
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    @Test func redundantIfStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition {
                return "foo"
            } else if otherCondition {
                if anotherCondition {
                    return "bar"
                } else {
                    return "baaz"
                }
            } else {
                return "quux"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            if condition {
                "foo"
            } else if otherCondition {
                if anotherCondition {
                    "bar"
                } else {
                    "baaz"
                }
            } else {
                "quux"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, [output],
            rules: [.redundantReturn, .conditionalAssignment],
            options: options,
        )
    }

    @Test func noRemoveRedundantIfStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition {
                return "foo"
            } else if otherCondition {
                if anotherCondition {
                    return "bar"
                } else {
                    return "baaz"
                }
            } else {
                return "quux"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(
            for: input, rule: .redundantReturn, options: options,
            exclude: [.conditionalAssignment],
        )
    }

}
