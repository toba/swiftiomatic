@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseTypedThrowsNotResultTests: RuleTesting {
  @Test func doCatchResultFlagged() {
    assertLint(
      UseTypedThrowsNotResult.self,
      """
      func 1️⃣parse() -> Result<Int, MyError> {
        do {
          return .success(try compute())
        } catch {
          return .failure(error as! MyError)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "function returns 'Result<T, E>' via do/catch — express as 'throws(E) -> T' (typed throws)"),
      ]
    )
  }

  @Test func resultWithoutDoCatchNotFlagged() {
    assertLint(
      UseTypedThrowsNotResult.self,
      """
      func parse() -> Result<Int, MyError> {
        Result { try compute() }.mapError { $0 as! MyError }
      }
      """,
      findings: []
    )
  }

  @Test func nonResultReturnNotFlagged() {
    assertLint(
      UseTypedThrowsNotResult.self,
      """
      func parse() throws -> Int {
        do {
          return try compute()
        } catch {
          throw error
        }
      }
      """,
      findings: []
    )
  }

  @Test func multipleStatementsBeforeDoNotFlagged() {
    assertLint(
      UseTypedThrowsNotResult.self,
      """
      func parse() -> Result<Int, MyError> {
        log("start")
        do {
          return .success(try compute())
        } catch {
          return .failure(error as! MyError)
        }
      }
      """,
      findings: []
    )
  }

  @Test func multipleCatchClausesNotFlagged() {
    assertLint(
      UseTypedThrowsNotResult.self,
      """
      func parse() -> Result<Int, MyError> {
        do {
          return .success(try compute())
        } catch is OneError {
          return .failure(.one)
        } catch {
          return .failure(.other)
        }
      }
      """,
      findings: []
    )
  }
}
