import Testing
@testable import Swiftiomatic

@Suite struct RedundantLetTests {
    @Test func removeRedundantLet() {
        let input = """
        let _ = bar {}
        """
        let output = """
        _ = bar {}
        """
        testFormatting(for: input, output, rule: .redundantLet)
    }

    @Test func noRemoveLetWithType() {
        let input = """
        let _: String = bar {}
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func removeRedundantLetInCase() {
        let input = """
        if case .foo(let _) = bar {}
        """
        let output = """
        if case .foo(_) = bar {}
        """
        testFormatting(for: input, output, rule: .redundantLet, exclude: [.redundantPattern])
    }

    @Test func removeRedundantVarsInCase() {
        let input = """
        if case .foo(var _, var /* unused */ _) = bar {}
        """
        let output = """
        if case .foo(_, /* unused */ _) = bar {}
        """
        testFormatting(for: input, output, rule: .redundantLet)
    }

    @Test func noRemoveLetInIf() {
        let input = """
        if let _ = foo {}
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetInMultiIf() {
        let input = """
        if foo == bar, /* comment! */ let _ = baz {}
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetInGuard() {
        let input = """
        guard let _ = foo else {}
        """
        testFormatting(
            for: input, rule: .redundantLet,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func noRemoveLetInWhile() {
        let input = """
        while let _ = foo {}
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetInViewBuilder() {
        let input = """
        HStack {
            let _ = print("Hi")
            Text("Some text")
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetInViewBuilderModifier() {
        let input = """
        VStack {
            Text("Some text")
        }
        .overlay(
            HStack {
                let _ = print("")
            }
        )
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetInIfStatementInViewBuilder() {
        let input = """
        VStack(spacing: 0) {
            if visible == "YES" {
                let _ = print("")
            }
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetInCondIfStatementInViewBuilder() {
        let input = """
        VStack {
            #if VIEW_PERF_LOGGING
                let _ = Self._printChanges()
            #else
                let _ = Self._printChanges()
            #endif
            let _ = Self._printChanges()
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetInSwitchStatementInViewBuilder() {
        let input = """
        struct TestView: View {
            var body: some View {
                #if DEBUG
                    let _ = Self._printChanges()
                #endif
                var foo = ""
                switch (self.min, self.max) {
                case let (nil, max as Int):
                    let _ = {
                        foo = "\\(max)"
                    }()

                default:
                    EmptyView()
                }

                Text(foo)
            }
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveAsyncLet() {
        let input = """
        async let _ = foo()
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetImmediatelyAfterMainActorAttribute() {
        let input = """
        let foo = bar { @MainActor
            let _ = try await baz()
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func noRemoveLetImmediatelyAfterSendableAttribute() {
        let input = """
        let foo = bar { @Sendable
            let _ = try await baz()
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    @Test func preserveLetInPreviewMacro() {
        let input = """
        #Preview {
            let _ = 1234
            Text("Test")
        }

        #Preview(name: "Test") {
            let _ = 1234
            Text("Test")
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }
}
