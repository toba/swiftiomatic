import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireWeakSelfInObservationsTests: RuleTesting {
    private static let closureMessage =
        "'Observations' closure captures 'self' strongly; add '[weak self]' so that the sequence does not keep the owner alive"
    private static let taskMessage =
        "'for await' over 'Observations' runs in a 'Task' that captures 'self' strongly; the loop does not end, so the task keeps the owner alive"
    private static let closureNote = "the closure that captures 'self'"
    private static func ownerNote(_ name: String) -> String {
        "'\(name)' is the owner that the closure keeps alive"
    }

    @Test func explicitSelfInClassFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            @Observable final class 2️⃣Model {
              var count = 0
              func start() {
                let values = 1️⃣Observations 3️⃣{ self.count }
                _ = values
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.closureMessage,
                    notes: [
                        NoteSpec("3️⃣", message: Self.closureNote),
                        NoteSpec("2️⃣", message: Self.ownerNote("Model")),
                    ]
                )
            ]
        )
    }

    @Test func strongSelfCaptureInActorFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            actor 2️⃣Store {
              var count = 0
              func start() {
                let values = 1️⃣Observations 3️⃣{ [self] in count }
                _ = values
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.closureMessage,
                    notes: [
                        NoteSpec("3️⃣", message: Self.closureNote),
                        NoteSpec("2️⃣", message: Self.ownerNote("Store")),
                    ]
                )
            ]
        )
    }

    @Test func selfInNestedClosureFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class 2️⃣Model {
              var items: [Int] = []
              var values: Observations<[Int], Never> {
                1️⃣Observations(3️⃣{ self.items.map { $0 + 1 } })
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.closureMessage,
                    notes: [
                        NoteSpec("3️⃣", message: Self.closureNote),
                        NoteSpec("2️⃣", message: Self.ownerNote("Model")),
                    ]
                )
            ]
        )
    }

    @Test func extensionOfSameFileClassFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class Model { var count = 0 }
            extension 2️⃣Model {
              func start() {
                _ = Observations.1️⃣untilFinished 3️⃣{ .next(self.count) }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.closureMessage,
                    notes: [
                        NoteSpec("3️⃣", message: Self.closureNote),
                        NoteSpec("2️⃣", message: Self.ownerNote("Model")),
                    ]
                )
            ]
        )
    }

    @Test func weakSelfNotFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class Model {
              var count = 0
              func start() {
                _ = Observations { [weak self] in self?.count ?? 0 }
                _ = Observations { [unowned self] in self.count }
              }
            }
            """,
            findings: []
        )
    }

    @Test func noSelfReferenceNotFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class Model {
              let other = Other()
              func start(model: Other) {
                _ = Observations { model.count }
              }
            }
            """,
            findings: []
        )
    }

    @Test func structOwnerNotFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            struct Feed {
              let model: Model
              func start() {
                _ = Observations { self.model.count }
              }
            }
            """,
            findings: []
        )
    }

    @Test func freeFunctionNotFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            func start(model: Model) {
              _ = Observations { model.count }
            }
            """,
            findings: []
        )
    }

    @Test func staticMemberNotFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class Model {
              static var shared = 0
              static func start() {
                _ = Observations { self.shared }
              }
            }
            """,
            findings: []
        )
    }

    @Test func forAwaitInStrongTaskFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class 2️⃣Controller {
              let model = Model()
              var label = ""
              func start() {
                Task 3️⃣{
                  let values = Observations { [model] in model.count }
                  1️⃣for await value in values {
                    self.label = "\\(value)"
                  }
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.taskMessage,
                    notes: [
                        NoteSpec("3️⃣", message: Self.closureNote),
                        NoteSpec("2️⃣", message: Self.ownerNote("Controller")),
                    ]
                )
            ]
        )
    }

    @Test func forAwaitDirectSequenceInStrongTaskFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class 2️⃣Controller {
              var label = ""
              func start(model: Model) {
                Task.immediate 3️⃣{
                  1️⃣for await value in Observations({ model.count }) {
                    self.label = "\\(value)"
                  }
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.taskMessage,
                    notes: [
                        NoteSpec("3️⃣", message: Self.closureNote),
                        NoteSpec("2️⃣", message: Self.ownerNote("Controller")),
                    ]
                )
            ]
        )
    }

    @Test func forAwaitInWeakTaskNotFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class Controller {
              var label = ""
              func start(model: Model) {
                Task { [weak self] in
                  for await value in Observations({ model.count }) {
                    self?.label = "\\(value)"
                  }
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func forAwaitOverOtherSequenceNotFlagged() {
        assertLint(
            RequireWeakSelfInObservations.self,
            """
            final class Controller {
              var label = ""
              func start(stream: AsyncStream<Int>) {
                Task {
                  for await value in stream {
                    self.label = "\\(value)"
                  }
                }
              }
            }
            """,
            findings: []
        )
    }
}
