@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireCancellationCheckInLoopTests: RuleTesting {
  private static func message(_ keyword: String) -> String {
    "'\(keyword)' loop awaits inside a task but never checks for cancellation. Check 'Task.isCancelled' or call 'Task.checkCancellation()' in the loop"
  }

  @Test func guidanceIsConsider() {
    #expect(RequireCancellationCheckInLoop.guidance == .consider)
  }

  @Test func awaitingLoopInTaskFlagged() {
    assertLint(
      RequireCancellationCheckInLoop.self,
      """
      func load(_ items: [Item]) {
        Task(name: "load picked attachments") {
          var made: [Payload] = []
          1️⃣for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            made.append(data)
          }
        }
        Task.detached {
          2️⃣while hasMore {
            await fetchPage()
          }
        }
      }

      struct Feed: View {
        var body: some View {
          List {}.task {
            3️⃣repeat {
              await refresh()
            } while true
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("for")),
        FindingSpec("2️⃣", message: Self.message("while")),
        FindingSpec("3️⃣", message: Self.message("repeat")),
      ]
    )
  }

  @Test func checkedAsyncSequenceAndSyncLoopsNotFlagged() {
    assertLint(
      RequireCancellationCheckInLoop.self,
      """
      func load(_ items: [Item]) {
        Task {
          for item in items {
            if Task.isCancelled { return }
            await item.load()
          }
          for item in items {
            try Task.checkCancellation()
            await item.load()
          }
          while true {
            try await Task.sleep(for: .seconds(1))
          }
          for await event in events {
            handle(event)
          }
          for item in items {
            handle(item)
          }
        }
      }

      func outsideTask(_ items: [Item]) async {
        for item in items { await item.load() }
      }
      """
    )
  }
}
