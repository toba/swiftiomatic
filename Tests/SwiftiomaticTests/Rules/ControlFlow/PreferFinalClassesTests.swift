import Testing
@testable import Swiftiomatic

@Suite struct PreferFinalClassesTests {
    @Test func basicClassMadesFinal() {
        let input = """
        class Foo {}
        """
        let output = """
        final class Foo {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func publicClassMadesFinal() {
        let input = """
        public class Bar {}
        """
        let output = """
        public final class Bar {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func privateClassMadesFinal() {
        let input = """
        private class Baz {}
        """
        let output = """
        private final class Baz {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func internalClassMadesFinal() {
        let input = """
        internal class Qux {}
        """
        let output = """
        internal final class Qux {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.redundantInternal])
    }

    @Test func openClassLeftUnchanged() {
        let input = """
        open class OpenClass {}
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    @Test func alreadyFinalClassLeftUnchanged() {
        let input = """
        final class FinalClass {}
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    @Test func publicFinalClassLeftUnchanged() {
        let input = """
        public final class PublicFinalClass {}
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    @Test func publicOpenClassLeftUnchanged() {
        let input = """
        public open class PublicOpenClass {}
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    @Test func classFunctionNotAffected() {
        let input = """
        struct Foo {
            class func bar() {}
        }
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    @Test func classVariableNotAffected() {
        let input = """
        struct Foo {
            class var bar: String { "bar" }
        }
        """
        testFormatting(
            for: input, rule: .preferFinalClasses, exclude: [
                .wrapFunctionBodies,
                .wrapPropertyBodies,
            ],
        )
    }

    @Test func nestedClass() {
        let input = """
        class OuterClass {
            class InnerClass {}
        }
        """
        let output = """
        final class OuterClass {
            final class InnerClass {}
        }
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.enumNamespaces])
    }

    @Test func classWithInheritance() {
        let input = """
        class Child: Parent {}
        """
        let output = """
        final class Child: Parent {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func classWithProtocolConformance() {
        let input = """
        class MyClass: SomeProtocol {}
        """
        let output = """
        final class MyClass: SomeProtocol {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func classWithMultipleModifiers() {
        let input = """
        @objc public class MyClass {}
        """
        let output = """
        @objc public final class MyClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func multipleClasses() {
        let input = """
        class FirstClass {}
        class SecondClass {}
        open class ThirdClass {}
        final class FourthClass {}
        """
        let output = """
        final class FirstClass {}
        final class SecondClass {}
        open class ThirdClass {}
        final class FourthClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func classWithComments() {
        let input = """
        // This is a class
        class MyClass {
            // Some content
        }
        """
        let output = """
        // This is a class
        final class MyClass {
            // Some content
        }
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.docComments])
    }

    @Test func classWithSubclassNotMadeFinal() {
        let input = """
        class BaseClass {}
        class SubClass: BaseClass {}
        """
        let output = """
        class BaseClass {}
        final class SubClass: BaseClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func multipleInheritanceLevels() {
        let input = """
        class GrandParent {}
        class Parent: GrandParent {}
        class Child: Parent {}
        """
        let output = """
        class GrandParent {}
        class Parent: GrandParent {}
        final class Child: Parent {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func classWithProtocolConformanceStillMadeFinal() {
        let input = """
        protocol SomeProtocol {}
        class MyClass: SomeProtocol {}
        """
        let output = """
        protocol SomeProtocol {}
        final class MyClass: SomeProtocol {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func classInheritingFromExternalClassMadeFinal() {
        let input = """
        class MyViewController: UIViewController {}
        """
        let output = """
        final class MyViewController: UIViewController {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func mixedScenario() {
        let input = """
        class BaseClass {}
        final class AlreadyFinalClass {}
        open class OpenClass {}
        class SubClass: BaseClass {}
        class IndependentClass {}
        """
        let output = """
        class BaseClass {}
        final class AlreadyFinalClass {}
        open class OpenClass {}
        final class SubClass: BaseClass {}
        final class IndependentClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func genericClassWithSubclass() {
        let input = """
        class Container<T> {}
        class StringContainer: Container<String> {}
        """
        let output = """
        class Container<T> {}
        final class StringContainer: Container<String> {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func genericClassWithGenericSubclass() {
        let input = """
        class BaseContainer<T> {}
        class SpecialContainer<U>: BaseContainer<U> {}
        """
        let output = """
        class BaseContainer<T> {}
        final class SpecialContainer<U>: BaseContainer<U> {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func multipleGenericParameters() {
        let input = """
        class GenericClass<T, U> {}
        class ConcreteClass: GenericClass<String, Int> {}
        """
        let output = """
        class GenericClass<T, U> {}
        final class ConcreteClass: GenericClass<String, Int> {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func complexGenericInheritanceChain() {
        let input = """
        class BaseContainer<T> {}
        class MiddleContainer<T>: BaseContainer<T> {}
        class FinalContainer: MiddleContainer<String> {}
        """
        let output = """
        class BaseContainer<T> {}
        class MiddleContainer<T>: BaseContainer<T> {}
        final class FinalContainer: MiddleContainer<String> {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func baseClassNotMadeFinal() {
        let input = """
        class BaseClass {}
        class ClassBase {}
        class SomeBase {}
        class BaseSomething {}
        class ViewControllerBase {}
        class RegularClass {}
        """
        let output = """
        class BaseClass {}
        class ClassBase {}
        class SomeBase {}
        class BaseSomething {}
        class ViewControllerBase {}
        final class RegularClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func convertOpenMembersToPublic() {
        let input = """
        public class MyClass {
            open var property1: String = ""
            open let property2: Int = 0
            open func method1() {}
            private var privateProperty: String = ""
            public func publicMethod() {}
        }
        """
        let output = """
        public final class MyClass {
            public var property1: String = ""
            public let property2: Int = 0
            public func method1() {}
            private var privateProperty: String = ""
            public func publicMethod() {}
        }
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    @Test func nestedClassWithOpenMembersNotConverted() {
        let input = """
        public class OuterClass {
            open var outerProperty: String = ""

            public class InnerClass {
                open var innerProperty: String = ""
            }
        }
        """
        let output = """
        public final class OuterClass {
            public var outerProperty: String = ""

            public final class InnerClass {
                public var innerProperty: String = ""
            }
        }
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.enumNamespaces])
    }

    @Test func mixedScenarioWithBaseAndOpen() {
        let input = """
        class BaseController {}
        public class MyController {
            open var title: String = ""
            open func setup() {}
        }
        class UtilityBase {}
        """
        let output = """
        class BaseController {}
        public final class MyController {
            public var title: String = ""
            public func setup() {}
        }
        class UtilityBase {}
        """
        testFormatting(
            for: input, output, rule: .preferFinalClasses, exclude: [.blankLinesBetweenScopes],
        )
    }

    @Test func nonFinalClassWithBaseCommentPreserved() {
        let input = """
        /// Base class
        public class Foo {}

        /// Customization point to be subclassed
        public class Foo {}

        //subclass this in your custom implementation
        public class Bar {}
        """

        testFormatting(
            for: input, rule: .preferFinalClasses, exclude: [.docComments, .spaceInsideComments],
        )
    }

    @Test func nestedClassInheritance() {
        let input = """
        final class OuterClass {
            var property: String = ""

            private class BaseRoute {}
            private class RouteWithInheritance: BaseRoute {}
        }
        """

        let output = """
        final class OuterClass {
            var property: String = ""

            private class BaseRoute {}
            private final class RouteWithInheritance: BaseRoute {}
        }
        """

        testFormatting(for: input, output, rule: .preferFinalClasses)
    }
}
