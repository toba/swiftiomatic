import Testing
@testable import Swiftiomatic

extension RedundantSelfTests {
    @Test func redundantSelfRuleFailsInInitOnlyMode2() {
        let input = """
        struct Mesh {
            var storage: Storage
            init(vertices: [Vertex]) {
                let isConvex = pointsAreConvex(vertices)
                storage = Storage(vertices: vertices)
            }
        }
        """
        let output = """
        struct Mesh {
            var storage: Storage
            init(vertices: [Vertex]) {
                let isConvex = pointsAreConvex(vertices)
                self.storage = Storage(vertices: vertices)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(
            for: input, output, rule: .redundantSelf,
            options: options,
        )
    }

    @Test func selfNotRemovedInInitForSwift5_4() {
        let input = """
        init() {
            let foo = 1234
            self.bar = foo
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly, swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func propertyInitNotInterpretedAsTypeInit() {
        let input = """
        struct MyStruct {
            private var __myVar: String
            var myVar: String {
                @storageRestrictions(initializes: __myVar)
                init(initialValue) {
                    __myVar = initialValue
                }
                set {
                    __myVar = newValue
                }
                get {
                    __myVar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func propertyInitNotInterpretedAsTypeInit2() {
        let input = """
        struct MyStruct {
            private var __myVar: String
            var myVar: String {
                @storageRestrictions(initializes: __myVar)
                init {
                    __myVar = newValue
                }
                set {
                    __myVar = newValue
                }
                get {
                    __myVar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    // parsing bugs

    @Test func selfRemovalParsingBug() {
        let input = """
        extension Dictionary where Key == String {
            func requiredValue<T>(for keyPath: String) throws -> T {
                return keyPath as! T
            }

            func optionalValue<T>(for keyPath: String) throws -> T? {
                guard let anyValue = self[keyPath] else {
                    return nil
                }
                guard let value = anyValue as? T else {
                    return nil
                }
                return value
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.blankLinesAfterGuardStatements])
    }

    @Test func selfRemovalParsingBug2() {
        let input = """
        if let test = value()["hi"] {
            print("hi")
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfRemovalParsingBug3() {
        let input = """
        func handleGenericError(_ error: Error) {
            if let requestableError = error as? RequestableError,
               case let .underlying(error as NSError) = requestableError,
               error.code == NSURLErrorNotConnectedToInternet
            {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfRemovalParsingBug4() {
        let input = """
        struct Foo {
            func bar() {
                for flag in [] where [].filter({ true }) {}
            }

            static func baz() {}
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfRemovalParsingBug5() {
        let input = """
        extension Foo {
            func method(foo: Bar) {
                self.foo = foo

                switch foo {
                case let .foo(bar):
                    closure {
                        Foo.draw()
                    }
                }
            }

            private static func draw() {}
        }
        """

        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfRemovalParsingBug6() {
        let input = """
        something.do(onSuccess: { result in
            if case .success((let d, _)) = result {
                self.relay.onNext(d)
            }
        })
        """
        testFormatting(
            for: input, rule: .redundantSelf,
            exclude: [.hoistPatternLet],
        )
    }

    @Test func selfRemovalParsingBug7() {
        let input = """
        extension Dictionary where Key == String {
            func requiredValue<T>(for keyPath: String) throws(Foo) -> T {
                return keyPath as! T
            }

            func optionalValue<T>(for keyPath: String) throws(Foo) -> T? {
                guard let anyValue = self[keyPath] else {
                    return nil
                }
                guard let value = anyValue as? T else {
                    return nil
                }
                return value
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.blankLinesAfterGuardStatements])
    }

    @Test func selfNotRemovedInCaseIfElse() {
        let input = """
        class Foo {
            let bar = true
            let someOptionalBar: String? = "bar"

            func test() {
                guard let bar: String = someOptionalBar else {
                    return
                }

                let result = Result<Any, Error>.success(bar)
                switch result {
                case let .success(value):
                    if self.bar {
                        if self.bar {
                            print(self.bar)
                        }
                    } else {
                        if self.bar {
                            print(self.bar)
                        }
                    }

                case .failure:
                    if self.bar {
                        print(self.bar)
                    }
                }
            }
        }
        """

        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func selfCallAfterIfStatementInSwitchStatement() {
        let input = """
        closure { [weak self] in
            guard let self else {
                return
            }

            switch result {
            case let .success(value):
                if value != nil {
                    if value != nil {
                        self.method()
                    }
                }
                self.method()

            case .failure:
                break
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func selfNotRemovedFollowingNestedSwitchStatements() {
        let input = """
        class Foo {
            let bar = true
            let someOptionalBar: String? = "bar"

            func test() {
                guard let bar: String = someOptionalBar else {
                    return
                }

                let result = Result<Any, Error>.success(bar)
                switch result {
                case let .success(value):
                    switch result {
                    case .success:
                        print("success")
                    case .value:
                        print("value")
                    }

                case .failure:
                    guard self.bar else {
                        print(self.bar)
                        return
                    }

                    print(self.bar)
                }
            }
        }
        """

        testFormatting(for: input, rule: .redundantSelf)
    }

    @Test func redundantSelfWithStaticAsyncSendableClosureFunction() {
        let input = """
        class Foo: Bar {
            static func bar(
                _ closure: @escaping @Sendable () async -> Foo
            ) -> @Sendable () async -> Foo {
                self.foo = closure
                return closure
            }

            static func bar() {}
        }
        """
        let output = """
        class Foo: Bar {
            static func bar(
                _ closure: @escaping @Sendable () async -> Foo
            ) -> @Sendable () async -> Foo {
                foo = closure
                return closure
            }

            static func bar() {}
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    // enable/disable

    @Test func disableRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // sm:disable redundantSelf
                self.bar = 1
                // sm:enable redundantSelf
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // sm:disable redundantSelf
                self.bar = 1
                // sm:enable redundantSelf
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func disableRemoveSelfCaseInsensitive() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // sm:disable redundantself
                self.bar = 1
                // sm:enable RedundantSelf
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // sm:disable redundantself
                self.bar = 1
                // sm:enable RedundantSelf
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func disableNextRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // sm:disable:next redundantSelf
                self.bar = 1
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // sm:disable:next redundantSelf
                self.bar = 1
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func multilineDisableRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                /* sm:disable redundantSelf */ self.bar = 1 /* sm:enable all */
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                /* sm:disable redundantSelf */ self.bar = 1 /* sm:enable all */
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func multilineDisableNextRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                /* sm:disable:next redundantSelf */
                self.bar = 1
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                /* sm:disable:next redundantSelf */
                self.bar = 1
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func removesSelfInNestedFunctionInStrongSelfClosure() {
        let input = """
        class Test {
            func doWork(_ escaping: @escaping () -> Void) {
                escaping()
            }

            func test() {
                doWork { [self] in
                    doWork {
                        // Not allowed. Warning in Swift 5 and error in Swift 6.
                        self.test()
                    }

                    func innerFunc() {
                        // Allowed: https://forums.swift.org/t/why-does-se-0269-have-different-rules-for-inner-closures-vs-inner-functions/64334/2
                        self.test()
                    }

                    innerFunc()
                }
            }
        }
        """

        let output = """
        class Test {
            func doWork(_ escaping: @escaping () -> Void) {
                escaping()
            }

            func test() {
                doWork { [self] in
                    doWork {
                        // Not allowed. Warning in Swift 5 and error in Swift 6.
                        self.test()
                    }

                    func innerFunc() {
                        // Allowed: https://forums.swift.org/t/why-does-se-0269-have-different-rules-for-inner-closures-vs-inner-functions/64334/2
                        test()
                    }

                    innerFunc()
                }
            }
        }
        """
        testFormatting(
            for: input, output, rule: .redundantSelf, options: FormatOptions(swiftVersion: "5.8"),
        )
    }

    @Test func preservesSelfInNestedFunctionInWeakSelfClosure() {
        let input = """
        class Test {
            func doWork(_ escaping: @escaping () -> Void) {
                escaping()
            }

            func test() {
                doWork { [weak self] in
                    func innerFunc() {
                        self?.test()
                    }

                    guard let self else {
                        return
                    }

                    self.test()

                    func innerFunc() {
                        self.test()
                    }

                    self.test()
                }
            }
        }
        """

        let output = """
        class Test {
            func doWork(_ escaping: @escaping () -> Void) {
                escaping()
            }

            func test() {
                doWork { [weak self] in
                    func innerFunc() {
                        self?.test()
                    }

                    guard let self else {
                        return
                    }

                    test()

                    func innerFunc() {
                        self.test()
                    }

                    test()
                }
            }
        }
        """

        testFormatting(
            for: input, output, rule: .redundantSelf,
            options: FormatOptions(swiftVersion: "5.8"),
        )
    }

    @Test func redundantSelfAfterScopedImport() {
        let input = """
        import struct Foundation.Date

        struct Foo {
            let foo: String
            init(bar: String) {
                self.foo = bar
            }
        }
        """
        let output = """
        import struct Foundation.Date

        struct Foo {
            let foo: String
            init(bar: String) {
                foo = bar
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    @Test func redundantSelfNotConfusedByParameterPack() {
        let input = """
        func pairUp<each T, each U>(firstPeople: repeat each T, secondPeople: repeat each U) -> (repeat (first: each T, second: each U)) {
            (repeat (each firstPeople, each secondPeople))
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func redundantSelfNotConfusedByStaticAfterSwitch() {
        let input = """
        public final class MyClass {
            private static func privateStaticFunction1() -> Bool {
                switch Result(catching: { try someThrowingFunction() }) {
                case .success:
                    return true
                case .failure:
                    return false
                }
            }

            private static func privateStaticFunction2() -> Bool {
                return false
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(
            for: input,
            rule: .redundantSelf,
            options: options,
            exclude: [.enumNamespaces],
        )
    }

    @Test func redundantSelfNotConfusedByMainActor() {
        let input = """
        class Test {
            private var p: Int

            func f() {
                self.f2(
                    closure: { @MainActor [weak self] p in
                        print(p)
                    }
                )
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    @Test func noMistakeProtocolClassModifierForClassFunction() throws {
        let input = """
        protocol Foo: class {}
        func bar() {}
        """
        _ = try format(input, rules: [.redundantSelf])
        _ = try format(input, rules: FormatRules.all)
    }

    @Test func redundantSelfParsingBug3() throws {
        let input = """
        final class ViewController {
          private func bottomBarModels() -> [BarModeling] {
            if let url = URL(string: "..."){
              // ...
            }

            models.append(
              Footer.barModel(
                content: FooterContent(
                  primaryTitleText: "..."),
                style: style)
                .setBehaviors { context in
                  context.view.primaryButtonState = self.isLoading ? .waiting : .normal
                  context.view.primaryActionHandler = { [weak self] _ in
                    self?.acceptButtonWasTapped()
                  }
                })
          }

        }
        """
        _ = try format(input, rules: [.redundantSelf])
    }

    @Test func redundantSelfParsingBug4() throws {
        let input = """
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let row: Row = promotionSections[indexPath.section][indexPath.row] else { return UITableViewCell() }
            let cell = tableView.dequeueReusable(RowTableViewCell.self, forIndexPath: indexPath)
            cell.update(row: row)
            return cell
        }
        """
        _ = try format(input, rules: [.redundantSelf])
    }

    @Test func redundantSelfParsingBug5() throws {
        let input = """
        Button.primary(
            title: "Title",
            tapHandler: { [weak self] in
                self?.dismissBlock? {
                    // something
                }
            }
        )
        """
        _ = try format(input, rules: [.redundantSelf])
    }

    @Test func redundantSelfParsingBug6() throws {
        let input = """
        if let foo = bar, foo.tracking[jsonDict: "something"] != nil {}
        """
        _ = try format(input, rules: [.redundantSelf])
    }

    @Test func understandsParameterPacks_issue_1992() {
        let input = """
        @resultBuilder
        public enum DirectoryContentBuilder {
            public static func buildPartialBlock<each Accumulated>(
                accumulated: repeat each Accumulated,
                next: some DirectoryContent
            ) -> some DirectoryContent where repeat each Accumulated: DirectoryContent {
                Accumulate(
                    accumulated: repeat each accumulated,
                    next: next
                )
            }

            public static func buildEither<First, Second>(
                first component: First
            ) -> _Either<First, Second> where First: DirectoryContent, Second: DirectoryContent {
                .first(component)
            }

            struct List<Element>: DirectoryContent where Element: DirectoryContent {
                init(_ list: [Element]) {
                    self._list = list
                }

                private let _list: [Element]
            }
        }
        """

        let output = """
        @resultBuilder
        public enum DirectoryContentBuilder {
            public static func buildPartialBlock<each Accumulated>(
                accumulated: repeat each Accumulated,
                next: some DirectoryContent
            ) -> some DirectoryContent where repeat each Accumulated: DirectoryContent {
                Accumulate(
                    accumulated: repeat each accumulated,
                    next: next
                )
            }

            public static func buildEither<First, Second>(
                first component: First
            ) -> _Either<First, Second> where First: DirectoryContent, Second: DirectoryContent {
                .first(component)
            }

            struct List<Element>: DirectoryContent where Element: DirectoryContent {
                init(_ list: [Element]) {
                    _list = list
                }

                private let _list: [Element]
            }
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .redundantSelf,
            exclude: [.simplifyGenericConstraints],
        )
    }

    @Test func redundantSelfIssue2177() {
        let input = """
        final class A {
            let v1: Int
            var v2: Int { didSet {}}

            init(v1: Int, v2: Int) {
                self.v1 = v1
                self.v2 = v2
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
    }

    @Test func redundantSelfIssue2177_2() {
        let input = """
        final class A {
            let v1: Int
            var v2: Int { didSet { }}

            init(v1: Int, v2: Int) {
                self.v1 = v1
                self.v2 = v2
            }
        }
        """
        testFormatting(
            for: input,
            rule: .redundantSelf,
            exclude: [.emptyBraces, .wrapPropertyBodies],
        )
    }

    @Test func redundantSelfIssue2177_3() {
        let input = """
        final class A {
            let v1: Int
            var v2: Int { didSet {} }

            init(v1: Int, v2: Int) {
                self.v1 = v1
                self.v2 = v2
            }
        }
        """
        testFormatting(
            for: input, rule: .redundantSelf, exclude: [.spaceInsideBraces, .wrapPropertyBodies],
        )
    }

    @Test func forAwaitParsingError() {
        let input = """
        for await case (let index, let result)? in group {
            responses[index] = result
        }
        """
        testFormatting(
            for: input, rule: .redundantSelf,
            options: FormatOptions(
                hoistPatternLet: false,
                explicitSelf: .initOnly,
            ),
        )
    }

    @Test func conditionallyCompiledSelfRemoved() {
        let input = """
        extension View {
            @ViewBuilder
            func compatibleSearchable(
                text: Binding<String>,
                isPresented: Binding<Bool>,
                prompt: Text?
            ) -> some View {
                if #available(iOS 17, *) {
                    self.searchable(
                        text: text,
                        isPresented: isPresented,
                        prompt: prompt
                    )
                } else {
                    self.searchable(
                        text: text,
                        prompt: prompt
                    )
                }
            }
        }
        """
        let output = """
        extension View {
            @ViewBuilder
            func compatibleSearchable(
                text: Binding<String>,
                isPresented: Binding<Bool>,
                prompt: Text?
            ) -> some View {
                if #available(iOS 17, *) {
                    searchable(
                        text: text,
                        isPresented: isPresented,
                        prompt: prompt
                    )
                } else {
                    searchable(
                        text: text,
                        prompt: prompt
                    )
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }
}
