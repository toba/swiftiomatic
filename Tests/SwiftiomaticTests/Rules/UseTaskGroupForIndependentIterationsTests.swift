@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseTaskGroupForIndependentIterationsTests: RuleTesting {
  private static let message =
    "each pass of this 'for' loop awaits work that does not depend on an earlier pass. Run the passes at once in a task group"

  @Test func guidanceIsConsider() {
    #expect(UseTaskGroupForIndependentIterations.guidance == .consider)
  }

  @Test func whileAndRepeatLoopsNotFlagged() {
    // The body of a `while` or `repeat` loop changes what its condition reads, so each pass
    // depends on the one before it.
    assertLint(
      UseTaskGroupForIndependentIterations.self,
      """
      extension GitActions {
        fileprivate func waitUntilIdle(within seconds: Double = 20) async {
          let deadline = Date().addingTimeInterval(seconds)
          while working, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(20))
          }
        }

        func drain(from start: Cursor?) async {
          var cursor = start
          while cursor != nil {
            let page = await fetch(cursor)
            cursor = page.next
          }
          repeat {
            await refresh()
          } while stale
        }
      }
      """
    )
  }

  @Test func forLoopCollectingResultsFlagged() {
    assertLint(
      UseTaskGroupForIndependentIterations.self,
      """
      func totalSize(of urls: [URL]) async throws -> Int {
        var sizes: [Int] = []
        1️⃣for url in urls {
          sizes.append(try await size(of: url))
        }
        var total = 0
        2️⃣for url in urls {
          total += try await size(of: url)
        }
        return sizes.count + total
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
      ]
    )
  }

  @Test func forAwaitLoopNotFlagged() {
    assertLint(
      UseTaskGroupForIndependentIterations.self,
      """
      func drain(_ stream: AsyncStream<Int>) async {
        for await value in stream {
          await handle(value)
        }
      }
      """
    )
  }

  @Test func iterationThatFeedsTheNextNotFlagged() {
    assertLint(
      UseTaskGroupForIndependentIterations.self,
      """
      func follow(_ start: Page) async throws {
        var page = start
        while page.hasNext {
          page = try await fetch(after: page)
        }
      }
      """
    )
  }

  @Test func loopThatExitsEarlyNotFlagged() {
    assertLint(
      UseTaskGroupForIndependentIterations.self,
      """
      func firstMatch(in urls: [URL]) async -> URL? {
        for url in urls {
          if await matches(url) { return url }
        }
        return nil
      }
      """
    )
  }

  @Test func loopThatAddsGroupTasksNotFlagged() {
    assertLint(
      UseTaskGroupForIndependentIterations.self,
      """
      func load(_ urls: [URL]) async {
        await withTaskGroup { group in
          for url in urls {
            group.addTask { await fetch(url) }
          }
        }
      }
      """
    )
  }

  @Test func syncFunctionNotFlagged() {
    assertLint(
      UseTaskGroupForIndependentIterations.self,
      """
      func load(_ urls: [URL]) {
        for url in urls {
          print(url)
        }
      }
      """
    )
  }
}
