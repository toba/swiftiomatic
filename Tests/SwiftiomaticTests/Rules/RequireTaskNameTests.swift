@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RequireTaskNameTests: RuleTesting {
  private static let initMessage =
    "'Task { ... }' is unnamed — pass 'name:' so it shows up in Instruments and the debugger task list"
  private static func staticMessage(_ name: String) -> String {
    "'Task.\(name)' is unnamed — pass 'name:' so it shows up in Instruments and the debugger task list"
  }
  private static func addTaskMessage(_ name: String) -> String {
    "'\(name)' is unnamed — pass 'name:' so it shows up in Instruments and the debugger task list"
  }

  @Test func unnamedTaskInitFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        1️⃣Task {
          await work()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.initMessage)]
    )
  }

  @Test func unnamedTaskWithPriorityFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        1️⃣Task(priority: .background) {
          await work()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.initMessage)]
    )
  }

  @Test func namedTaskInitNotFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        Task(name: "refresh") {
          await work()
        }
      }
      """,
      findings: []
    )
  }

  @Test func namedTaskInitWithPriorityNotFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        Task(name: "refresh", priority: .high) {
          await work()
        }
      }
      """,
      findings: []
    )
  }

  @Test func unnamedTaskDetachedFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        Task.1️⃣detached {
          await work()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.staticMessage("detached"))]
    )
  }

  @Test func unnamedTaskImmediateFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        Task.1️⃣immediate {
          await work()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.staticMessage("immediate"))]
    )
  }

  @Test func unnamedTaskImmediateDetachedFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        Task.1️⃣immediateDetached {
          await work()
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.staticMessage("immediateDetached"))]
    )
  }

  @Test func namedTaskDetachedNotFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        Task.detached(name: "cleanup") {
          await work()
        }
      }
      """,
      findings: []
    )
  }

  @Test func unnamedAddTaskFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() async {
        await withTaskGroup(of: Void.self) { group in
          group.1️⃣addTask {
            await work()
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.addTaskMessage("addTask"))]
    )
  }

  @Test func unnamedAddTaskUnlessCancelledFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() async {
        await withTaskGroup(of: Void.self) { group in
          group.1️⃣addTaskUnlessCancelled {
            await work()
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.addTaskMessage("addTaskUnlessCancelled"))]
    )
  }

  @Test func namedAddTaskNotFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() async {
        await withTaskGroup(of: Void.self) { group in
          group.addTask(name: "child") {
            await work()
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func addTaskWithForeignLabelsNotFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() throws {
        let added = try service.addTask(
          to: a.issue, title: a.title, detail: a.detail,
          parentRef: a.parent, status: a.status ?? .ready
        )
        _ = added
      }
      """,
      findings: []
    )
  }

  @Test func addTaskWithoutClosureNotFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        queue.addTask(work)
      }
      """,
      findings: []
    )
  }

  @Test func addTaskWithOperationLabelFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() async {
        await withTaskGroup(of: Void.self) { group in
          group.1️⃣addTask(operation: work)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.addTaskMessage("addTask"))]
    )
  }

  @Test func addTaskWithPriorityFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() async {
        await withTaskGroup(of: Void.self) { group in
          group.1️⃣addTask(priority: .high) {
            await work()
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.addTaskMessage("addTask"))]
    )
  }

  @Test func unrelatedTaskMemberNotFlagged() {
    assertLint(
      RequireTaskName.self,
      """
      func go() {
        let name = Task.currentName
        let id = Task.basePriority
        _ = name
        _ = id
      }
      """,
      findings: []
    )
  }
}
