@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseAsyncResultInitTests: RuleTesting {
  private static let message =
    "this 'do'/'catch' only builds a 'Result' — collapse it to 'await Result { try await … }' (SE-0530)"

  @Test func awaitedResultWrapperFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() async {
        let result: Result<[Article], any Error>
        1️⃣do {
          result = .success(try await importArticles())
        } catch {
          result = .failure(error)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func memberTargetFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() async {
        1️⃣do {
          self.state = .success(await fetch())
        } catch {
          self.state = .failure(error)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func setupBeforeAssignmentStillFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() async {
        1️⃣do {
          try validate()
          result = .success(try await importArticles())
        } catch {
          result = .failure(error)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func synchronousWrapperNotFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() {
        do {
          result = .success(try importArticles())
        } catch {
          result = .failure(error)
        }
      }
      """,
      findings: []
    )
  }

  @Test func differentTargetsNotFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() async {
        do {
          loaded = .success(await fetch())
        } catch {
          failed = .failure(error)
        }
      }
      """,
      findings: []
    )
  }

  @Test func typedCatchNotFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() async {
        do {
          result = .success(await fetch())
        } catch let error as URLError {
          result = .failure(error)
        }
      }
      """,
      findings: []
    )
  }

  @Test func extraCatchStatementNotFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() async {
        do {
          result = .success(await fetch())
        } catch {
          log(error)
          result = .failure(error)
        }
      }
      """,
      findings: []
    )
  }

  @Test func nonResultAssignmentNotFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() async {
        do {
          value = await fetch()
        } catch {
          value = nil
        }
      }
      """,
      findings: []
    )
  }

  @Test func resultInitNotFlagged() {
    assertLint(
      UseAsyncResultInit.self,
      """
      func load() async {
        let result = await Result { try await importArticles() }
      }
      """,
      findings: []
    )
  }
}
