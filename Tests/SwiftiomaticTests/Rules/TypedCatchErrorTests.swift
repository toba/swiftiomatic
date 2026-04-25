@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct TypedCatchErrorTests: RuleTesting {

    @Test func untypedLetCatchTriggers() {
        assertLint(
            TypedCatchError.self,
            """
            do {
              try foo()
            } 1️⃣catch let error {}
            """,
            findings: [
                FindingSpec("1️⃣", message: "drop the binding ('catch {}') or pattern-match a concrete error type ('catch let e as MyError')")
            ]
        )
    }

    @Test func untypedVarCatchTriggers() {
        assertLint(
            TypedCatchError.self,
            """
            do {
              try foo()
            } 1️⃣catch var someError {}
            """,
            findings: [
                FindingSpec("1️⃣", message: "drop the binding ('catch {}') or pattern-match a concrete error type ('catch let e as MyError')")
            ]
        )
    }

    @Test func parenthesizedLetCatchTriggers() {
        assertLint(
            TypedCatchError.self,
            """
            do {
              try foo()
            } 1️⃣catch (let error) {}
            """,
            findings: [
                FindingSpec("1️⃣", message: "drop the binding ('catch {}') or pattern-match a concrete error type ('catch let e as MyError')")
            ]
        )
    }

    @Test func bareCatchAccepted() {
        assertLint(
            TypedCatchError.self,
            """
            do {
              try foo()
            } catch {}
            """,
            findings: []
        )
    }

    @Test func typedCatchAccepted() {
        assertLint(
            TypedCatchError.self,
            """
            do {
              try foo()
            } catch let error as MyError {
            } catch var error as OtherError {
            } catch {}
            """,
            findings: []
        )
    }

    @Test func whereClauseAccepted() {
        assertLint(
            TypedCatchError.self,
            """
            do {
                try foo()
            } catch let e where e.code == .fileError {
            } catch {}
            """,
            findings: []
        )
    }

    @Test func patternLiteralAccepted() {
        assertLint(
            TypedCatchError.self,
            """
            do {
              try foo()
            } catch Error.invalidOperation {
            } catch {}
            """,
            findings: []
        )
    }
}
