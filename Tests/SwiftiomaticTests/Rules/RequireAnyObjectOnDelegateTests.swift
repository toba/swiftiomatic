@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireAnyObjectOnDelegateTests: RuleTesting {

    @Test func barelyDelegateProtocolTriggers() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            1️⃣protocol FooDelegate {}
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message:
                        "make 'FooDelegate' class-constrained (e.g. ': AnyObject') so it can be referenced weakly"
                )
            ]
        )
    }

    @Test func nonClassInheritanceTriggers() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            1️⃣protocol FooDelegate: Bar {}
            2️⃣protocol BazDelegate: Foo & Bar {}
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message:
                        "make 'FooDelegate' class-constrained (e.g. ': AnyObject') so it can be referenced weakly"
                ),
                FindingSpec(
                    "2️⃣",
                    message:
                        "make 'BazDelegate' class-constrained (e.g. ': AnyObject') so it can be referenced weakly"
                ),
            ]
        )
    }

    @Test func whereClauseWithNonObjectTriggers() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            1️⃣protocol FooDelegate where Self: StringProtocol {}
            2️⃣protocol BarDelegate where Self: A & B {}
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message:
                        "make 'FooDelegate' class-constrained (e.g. ': AnyObject') so it can be referenced weakly"
                ),
                FindingSpec(
                    "2️⃣",
                    message:
                        "make 'BarDelegate' class-constrained (e.g. ': AnyObject') so it can be referenced weakly"
                ),
            ]
        )
    }

    @Test func anyObjectIsAccepted() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            protocol FooDelegate: AnyObject {}
            protocol BarDelegate: AnyObject & Foo {}
            protocol BazDelegate: Foo, AnyObject & Foo {}
            protocol QuxDelegate: Foo & AnyObject & Bar {}
            """,
            findings: []
        )
    }

    @Test func classRestrictionIsAccepted() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            protocol FooDelegate: class {}
            protocol BarDelegate: class, BazDelegate {}
            """,
            findings: []
        )
    }

    @Test func nsObjectProtocolAndActorAreAccepted() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            protocol FooDelegate: NSObjectProtocol {}
            protocol BarDelegate: Actor {}
            """,
            findings: []
        )
    }

    @Test func inheritsFromAnotherDelegateIsAccepted() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            protocol FooDelegate: BarDelegate {}
            """,
            findings: []
        )
    }

    @Test func objcAttributeIsAccepted() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            @objc protocol FooDelegate {}
            @objc(MyFooDelegate)
            protocol BarDelegate {}
            """,
            findings: []
        )
    }

    @Test func whereClauseWithObjectIsAccepted() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            protocol FooDelegate where Self: BarDelegate {}
            protocol BarDelegate where Self: Foo & BazDelegate & Bar {}
            protocol BazDelegate where Self: AnyObject {}
            protocol QuxDelegate where Self: NSObjectProtocol {}
            """,
            findings: []
        )
    }

    @Test func nonDelegateProtocolIgnored() {
        assertLint(
            RequireAnyObjectOnDelegate.self,
            """
            protocol Foo {}
            class FooDelegate {}
            """,
            findings: []
        )
    }
}
