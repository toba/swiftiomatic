import Foundation
@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
package import Testing

@Suite
struct RequireTaskYieldInLoopTests: RuleTesting {
  private static func message(_ keyword: String) -> String {
    "'\(keyword)' loop in async code makes calls with no suspension point. Call 'await Task.yield()' in the loop so other tasks can run"
  }

  @Test func guidanceIsConsider() {
    #expect(RequireTaskYieldInLoop.guidance == .consider)
  }

  @Test func loopsInTaskGroupBodiesFlagged() {
    assertLint(
      RequireTaskYieldInLoop.self,
      """
      func review(_ sources: [Source]) async -> [Result] {
        await withTaskGroup(of: (Int, Result).self) { group in
          1️⃣for (index, source) in sources.enumerated() {
            group.addTask(name: "review \\(source.url)") {
              (index, await self.review(source))
            }
          }
          var results: [Result?] = []
          for await (index, result) in group { results[index] = result }
          return results
        }
      }

      func read(_ shas: Set<String>) async -> [String: Payload] {
        await withTaskGroup(of: (String, Payload)?.self) { group in
          2️⃣for sha in shas {
            group.addTask { await read(sha).map { (sha, $0) } }
          }
          return [:]
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("for")),
        FindingSpec("2️⃣", message: Self.message("for")),
      ]
    )
  }

  @Test func loopsInAsyncFunctionsFlagged() {
    assertLint(
      RequireTaskYieldInLoop.self,
      """
      func attach(_ fetched: [String: ([Pull], [Comment])]) async {
        let fetched = await load()
        1️⃣for (sha, entry) in fetched {
          let (pulls, comments) = entry
          numbers[sha] = pulls.map(\\.number).sorted()
          2️⃣for pull in pulls {
            var record = records[pull.number] ?? Record(pull)
            record.shas.append(sha)
          }
        }
      }

      @concurrent public func initialize(source: String? = nil) async throws -> Result {
        let dirs = detect()
        3️⃣for dir in dirs where dir.hasMarker {
          if lastComponent(dir.path) == ".claude" { best = dir }
        }
        4️⃣for name in config.names {
          try seed(config, name: name)
        }
        5️⃣while index < count {
          index = next(index)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("for")),
        FindingSpec("2️⃣", message: Self.message("for")),
        FindingSpec("3️⃣", message: Self.message("for")),
        FindingSpec("4️⃣", message: Self.message("for")),
        FindingSpec("5️⃣", message: Self.message("while")),
      ]
    )
  }

  @Test func loopsInAwaitingClosuresFlagged() {
    assertLint(
      RequireTaskYieldInLoop.self,
      """
      static let mark = Tool(name: "mark") { service, arguments in
        let marked = try await service.mark(arguments)
        var rows: [Row] = []
        1️⃣for source in marked { try rows.append(service.row(source.id)) }
        return rows
      }

      let handler = { (items: [Item]) async in
        2️⃣repeat { handle(items) } while items.isEmpty
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("for")),
        FindingSpec("2️⃣", message: Self.message("repeat")),
      ]
    )
  }

  @Test func loopsThatAwaitNotFlagged() {
    assertLint(
      RequireTaskYieldInLoop.self,
      """
      func process(_ items: [Item]) async {
        for item in items {
          handle(item)
          await Task.yield()
        }
        for item in items {
          await item.load()
        }
        for await event in events {
          handle(event)
        }
        while hasMore {
          let page = try? await fetchPage()
          store(page)
        }
      }
      """
    )
  }

  @Test func shortAndCallFreeLoopsNotFlagged() {
    assertLint(
      RequireTaskYieldInLoop.self,
      """
      func build(_ values: [Int]) async {
        for index in 0..<3 { append(index) }
        for name in ["a", "b"] { register(name) }
        var total = 0
        for value in values { total += value }
      }
      """
    )
  }

  @Test func syncLoopsNotFlagged() {
    assertLint(
      RequireTaskYieldInLoop.self,
      """
      func syncCode(_ items: [Item]) {
        for item in items { handle(item) }
        let work = { for item in items { handle(item) } }
      }

      func load() async {
        let work = { (items: [Item]) in
          for item in items { handle(item) }
        }
      }
      """
    )
  }
}
