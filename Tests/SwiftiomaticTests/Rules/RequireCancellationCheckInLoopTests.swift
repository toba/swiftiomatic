import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireCancellationCheckInLoopTests: RuleTesting {
    private static func message(_ keyword: String) -> String {
        "'\(keyword)' loop runs in async code but never checks for cancellation. Check 'Task.isCancelled' or call 'Task.checkCancellation()' in the loop"
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
                for try await event in events {
                  handle(event)
                }
              }
            }

            func syncCode(_ items: [Item]) {
              for item in items { handle(item) }
              let work = { for item in items { handle(item) } }
            }
            """
        )
    }

    @Test func loopsInAsyncFunctionsFlagged() {
        assertLint(
            RequireCancellationCheckInLoop.self,
            """
            func review(_ sources: [Source]) async -> [Result] {
              await withTaskGroup(of: Result.self) { group in
                1️⃣for source in sources {
                  group.addTask { await self.review(source) }
                }
                var results: [Result] = []
                2️⃣for await result in group { results.append(result) }
                return results
              }
            }

            func merge(_ fetched: [String: [Pull]]) async {
              3️⃣for (sha, pulls) in fetched {
                4️⃣for pull in pulls { record(pull, sha) }
              }
            }

            func serve(_ server: Server) async {
              5️⃣while case let .line(line) = lines.next() {
                let reply = await server.handle(line: line)
                write(reply)
              }
            }

            func waitUntilIdle() async {
              6️⃣while working, Date() < deadline {
                try? await Task.sleep(for: .milliseconds(20))
              }
            }

            var value: Int {
              get async {
                7️⃣for item in items { total += item }
                return total
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("for")),
                FindingSpec("2️⃣", message: Self.message("for")),
                FindingSpec("3️⃣", message: Self.message("for")),
                FindingSpec("4️⃣", message: Self.message("for")),
                FindingSpec("5️⃣", message: Self.message("while")),
                FindingSpec("6️⃣", message: Self.message("while")),
                FindingSpec("7️⃣", message: Self.message("for")),
            ]
        )
    }

    /// The musup `Scrobbler` and `MusicBrainzClient` shapes: a throwing await does not prove that
    /// the loop stops on cancellation, whether a `catch` in the loop handles the error or not.
    @Test func throwingAwaitDoesNotExemptLoop() {
        assertLint(
            RequireCancellationCheckInLoop.self,
            """
            func flush() async {
              1️⃣while let session, !pending.isEmpty {
                do {
                  try await client.scrobble(pending.removeFirst(), session: session)
                } catch {
                  log(error)
                }
              }
            }

            func releases(_ ids: [ID]) async throws -> [Release] {
              var all: [Release] = []
              2️⃣for id in ids {
                all += try await releaseGroups(for: id)
              }
              return all
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("while")),
                FindingSpec("2️⃣", message: Self.message("for")),
            ]
        )
    }

    /// A `catch` in the loop that handles the `CancellationError` of `Task.sleep` lets the loop go
    /// on, so the sleep does not stop it.
    @Test func sleepInsideDoCatchDoesNotExemptLoop() {
        assertLint(
            RequireCancellationCheckInLoop.self,
            """
            func poll() async {
              1️⃣while true {
                do {
                  try await Task.sleep(for: .seconds(5))
                } catch {
                  log(error)
                }
                await refresh()
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("while"))]
        )
    }

    @Test func loopsInAsyncClosuresFlagged() {
        assertLint(
            RequireCancellationCheckInLoop.self,
            """
            static let mark = Tool(name: "mark") { service, arguments in
              let marked = try await service.mark(arguments)
              var rows: [Row] = []
              1️⃣for source in marked { try rows.append(service.row(source.id)) }
              return rows
            }

            let handler = { (items: [Item]) async in
              2️⃣for item in items { handle(item) }
            }

            struct Root: View {
              var body: some View {
                Text("x").task {
                  let changes = await coordinator.changes()
                  3️⃣for await status in changes where status != .available {
                    log(status)
                  }
                }
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("for")),
                FindingSpec("2️⃣", message: Self.message("for")),
                FindingSpec("3️⃣", message: Self.message("for")),
            ]
        )
    }

    @Test func shortLiteralLoopsNotFlagged() {
        assertLint(
            RequireCancellationCheckInLoop.self,
            """
            func build() async {
              for index in 0..<3 { append(index) }
              for name in ["a", "b"] { register(name) }
              1️⃣for index in 1...10 {
                await process(index)
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("for"))]
        )
    }

    @Test func throwingAwaitInNestedTaskDoesNotExemptLoop() {
        assertLint(
            RequireCancellationCheckInLoop.self,
            """
            func start(_ items: [Item]) async {
              await withThrowingTaskGroup(of: Void.self) { group in
                1️⃣for item in items {
                  group.addTask { try await item.load() }
                }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("for"))]
        )
    }
}
