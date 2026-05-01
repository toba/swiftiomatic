@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseFinalClassesTests: RuleTesting {

  // MARK: - Basic transformations

  @Test func basicClassMadeFinal() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        1️⃣class Foo {}
        """,
      expected: """
        final class Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func publicClassMadeFinal() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        public 1️⃣class Bar {}
        """,
      expected: """
        public final class Bar {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func privateClassMadeFinal() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        private 1️⃣class Baz {}
        """,
      expected: """
        private final class Baz {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func internalClassMadeFinal() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        internal 1️⃣class Qux {}
        """,
      expected: """
        internal final class Qux {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func classWithMultipleModifiers() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        @objc public 1️⃣class MyClass {}
        """,
      expected: """
        @objc public final class MyClass {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func nestedClasses() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        1️⃣class OuterClass {
            2️⃣class InnerClass {}
        }
        """,
      expected: """
        final class OuterClass {
            final class InnerClass {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
        FindingSpec("2️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func classWithInheritance() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        1️⃣class Child: Parent {}
        """,
      expected: """
        final class Child: Parent {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func classWithProtocolConformance() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        1️⃣class MyClass: SomeProtocol {}
        """,
      expected: """
        final class MyClass: SomeProtocol {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func multipleClasses() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        1️⃣class FirstClass {}
        2️⃣class SecondClass {}
        open class ThirdClass {}
        final class FourthClass {}
        """,
      expected: """
        final class FirstClass {}
        final class SecondClass {}
        open class ThirdClass {}
        final class FourthClass {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
        FindingSpec("2️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func classWithComments() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        // This is a class
        1️⃣class MyClass {
            // Some content
        }
        """,
      expected: """
        // This is a class
        final class MyClass {
            // Some content
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func classInheritingFromExternalClassMadeFinal() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        1️⃣class MyViewController: UIViewController {}
        """,
      expected: """
        final class MyViewController: UIViewController {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  // MARK: - Open member conversion

  @Test func convertOpenMembersToPublic() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        public 1️⃣class MyClass {
            open var property1: String = ""
            open let property2: Int = 0
            open func method1() {}
            private var privateProperty: String = ""
            public func publicMethod() {}
        }
        """,
      expected: """
        public final class MyClass {
            public var property1: String = ""
            public let property2: Int = 0
            public func method1() {}
            private var privateProperty: String = ""
            public func publicMethod() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func nestedClassWithOpenMembers() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        public 1️⃣class OuterClass {
            open var outerProperty: String = ""

            public 2️⃣class InnerClass {
                open var innerProperty: String = ""
            }
        }
        """,
      expected: """
        public final class OuterClass {
            public var outerProperty: String = ""

            public final class InnerClass {
                public var innerProperty: String = ""
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
        FindingSpec("2️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func mixedScenarioWithBaseAndOpen() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class BaseController {}
        public 1️⃣class MyController {
            open var title: String = ""
            open func setup() {}
        }
        class UtilityBase {}
        """,
      expected: """
        class BaseController {}
        public final class MyController {
            public var title: String = ""
            public func setup() {}
        }
        class UtilityBase {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  // MARK: - Subclass detection

  @Test func classWithSubclassNotMadeFinal() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class ParentClass {}
        1️⃣class SubClass: ParentClass {}
        """,
      expected: """
        class ParentClass {}
        final class SubClass: ParentClass {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func multipleInheritanceLevels() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class GrandParent {}
        class Parent: GrandParent {}
        1️⃣class Child: Parent {}
        """,
      expected: """
        class GrandParent {}
        class Parent: GrandParent {}
        final class Child: Parent {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func genericClassWithSubclass() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class Container<T> {}
        1️⃣class StringContainer: Container<String> {}
        """,
      expected: """
        class Container<T> {}
        final class StringContainer: Container<String> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func genericClassWithGenericSubclass() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class BaseContainer<T> {}
        1️⃣class SpecialContainer<U>: BaseContainer<U> {}
        """,
      expected: """
        class BaseContainer<T> {}
        final class SpecialContainer<U>: BaseContainer<U> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func complexGenericInheritanceChain() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class BaseContainer<T> {}
        class MiddleContainer<T>: BaseContainer<T> {}
        1️⃣class FinalContainer: MiddleContainer<String> {}
        """,
      expected: """
        class BaseContainer<T> {}
        class MiddleContainer<T>: BaseContainer<T> {}
        final class FinalContainer: MiddleContainer<String> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func nestedClassInheritance() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        final class OuterClass {
            var property: String = ""

            private class InnerBase {}
            private 1️⃣class RouteWithInheritance: InnerBase {}
        }
        """,
      expected: """
        final class OuterClass {
            var property: String = ""

            private class InnerBase {}
            private final class RouteWithInheritance: InnerBase {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func mixedScenario() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class ParentClass {}
        final class AlreadyFinalClass {}
        open class OpenClass {}
        1️⃣class SubClass: ParentClass {}
        2️⃣class IndependentClass {}
        """,
      expected: """
        class ParentClass {}
        final class AlreadyFinalClass {}
        open class OpenClass {}
        final class SubClass: ParentClass {}
        final class IndependentClass {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
        FindingSpec("2️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  // MARK: - No-change cases

  @Test func openClassLeftUnchanged() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        open class OpenClass {}
        """,
      expected: """
        open class OpenClass {}
        """,
      findings: []
    )
  }

  @Test func alreadyFinalClassLeftUnchanged() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        final class FinalClass {}
        """,
      expected: """
        final class FinalClass {}
        """,
      findings: []
    )
  }

  @Test func publicFinalClassLeftUnchanged() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        public final class PublicFinalClass {}
        """,
      expected: """
        public final class PublicFinalClass {}
        """,
      findings: []
    )
  }

  @Test func publicOpenClassLeftUnchanged() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        public open class PublicOpenClass {}
        """,
      expected: """
        public open class PublicOpenClass {}
        """,
      findings: []
    )
  }

  @Test func classFunctionNotAffected() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        struct Foo {
            class func bar() {}
        }
        """,
      expected: """
        struct Foo {
            class func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func classVariableNotAffected() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        struct Foo {
            class var bar: String { "bar" }
        }
        """,
      expected: """
        struct Foo {
            class var bar: String { "bar" }
        }
        """,
      findings: []
    )
  }

  @Test func baseClassNotMadeFinal() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class BaseClass {}
        class ClassBase {}
        class SomeBase {}
        class BaseSomething {}
        class ViewControllerBase {}
        1️⃣class RegularClass {}
        """,
      expected: """
        class BaseClass {}
        class ClassBase {}
        class SomeBase {}
        class BaseSomething {}
        class ViewControllerBase {}
        final class RegularClass {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }

  @Test func baseCommentPreservesClass() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        /// Base class
        public class Foo {}

        /// Customization point to be subclassed
        public class Bar {}

        // subclass this in your custom implementation
        public class Baz {}
        """,
      expected: """
        /// Base class
        public class Foo {}

        /// Customization point to be subclassed
        public class Bar {}

        // subclass this in your custom implementation
        public class Baz {}
        """,
      findings: []
    )
  }

  @Test func multipleGenericParameters() {
    assertFormatting(
      UseFinalClasses.self,
      input: """
        class GenericClass<T, U> {}
        1️⃣class ConcreteClass: GenericClass<String, Int> {}
        """,
      expected: """
        class GenericClass<T, U> {}
        final class ConcreteClass: GenericClass<String, Int> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'final class' unless designed for subclassing"),
      ]
    )
  }
}
