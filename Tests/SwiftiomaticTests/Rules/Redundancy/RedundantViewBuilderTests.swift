import Testing
@testable import Swiftiomatic

@Suite struct RedundantViewBuilderTests {
    @Test func removeRedundantViewBuilderOnViewBody() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var body: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    @Test func removeRedundantViewBuilderOnViewModifierBody() {
        let input = """
        struct MyModifier: ViewModifier {
            @ViewBuilder
            func body(content: Content) -> some View {
                content
                    .foregroundColor(.red)
            }
        }
        """
        let output = """
        struct MyModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .foregroundColor(.red)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    @Test func removeRedundantViewBuilderOnSingleExpression() {
        let input = """
        struct MyView: View {
            var body: some View {
                helper
            }

            @ViewBuilder
            var helper: some View {
                VStack {
                    Text("baaz")
                    Text("quux")
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                helper
            }

            var helper: some View {
                VStack {
                    Text("baaz")
                    Text("quux")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    @Test func removeRedundantViewBuilderOnSingleExpressionClosure() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Color.red
            }
        }
        """
        let output = """
        struct MyView: View {
            var helper: some View {
                Color.red
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderWithMultipleTopLevelViews() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderWithIfElseExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                if condition {
                    Text("foo")
                } else {
                    Image("bar")
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderWithSwitchExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                switch value {
                case .foo:
                    Text("foo")
                case .bar:
                    Image("bar")
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderWithForEachAndViews() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                ForEach(items) { item in
                    Text(item.name)
                }
                Divider()
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    @Test func removeRedundantViewBuilderBeforeComputedProperty() {
        let input = """
        struct MyView: View {
            @ViewBuilder var body: some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderOnNonBodyProperty() {
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            @ViewBuilder
            var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    @Test func removeRedundantViewBuilderInNestedType() {
        let input = """
        struct OuterView: View {
            var body: some View {
                InnerView()
            }

            struct InnerView: View {
                @ViewBuilder
                var body: some View {
                    Text("Inner")
                }
            }
        }
        """
        let output = """
        struct OuterView: View {
            var body: some View {
                InnerView()
            }

            struct InnerView: View {
                var body: some View {
                    Text("Inner")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderOnPropertyWithModifier() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            private var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    @Test func removeRedundantViewBuilderWithComplexSingleExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Text("Hello")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        """
        let output = """
        struct MyView: View {
            var helper: some View {
                Text("Hello")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderOnHelperFuncWithIfWithoutElse() {
        let input = """
        struct Foo: View {
            var body: some View {
                if let bar {
                    baz(bar: bar)
                }
            }

            @ViewBuilder
            func baz(bar: Bar) -> some View {
                if bar.useA {
                    ViewA()
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderOnFuncNamedBodyInView() {
        // A function named "body" in a View is NOT the View.body protocol requirement
        // (which must be a property), so @ViewBuilder should be preserved if needed
        let input = """
        struct Foo: View {
            var body: some View {
                if let bar {
                    body(bar: bar)
                }
            }

            @ViewBuilder
            func body(bar: Bar) -> some View {
                if bar.useA {
                    ViewA()
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    @Test func keepViewBuilderOnVarNamedBodyInViewModifier() {
        // A property named "body" in a ViewModifier is NOT the ViewModifier.body protocol requirement
        // (which must be a function), so @ViewBuilder should be preserved if needed
        let input = """
        struct Foo: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .overlay(overlay)
            }

            @ViewBuilder
            var body: some View {
                if condition {
                    ViewA()
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }
}
