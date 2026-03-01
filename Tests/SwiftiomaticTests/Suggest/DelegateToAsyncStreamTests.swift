import Foundation
import Testing

@testable import Swiftiomatic

@Suite("DelegateToAsyncStreamRule")
struct DelegateToAsyncStreamTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SuggestFixtures/DelegateToAsyncStream.swift")
            .path
    }()

    @Test func detectsDelegateProtocol() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = DelegateToAsyncStreamRule()
        let violations = rule.validate(file: file)

        #expect(violations.contains { $0.reason.contains("DownloadDelegate") })
    }

    @Test func detectsObserverProtocol() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = DelegateToAsyncStreamRule()
        let violations = rule.validate(file: file)

        #expect(violations.contains { $0.reason.contains("StateObserver") })
    }

    @Test func doesNotFlagDataSourceProtocol() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = DelegateToAsyncStreamRule()
        let violations = rule.validate(file: file)

        // DataSource has return types — not delegate-shaped
        #expect(!violations.contains { $0.reason.contains("DataSource") })
    }

    @Test func doesNotFlagSingleMethodProtocol() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = DelegateToAsyncStreamRule()
        let violations = rule.validate(file: file)

        // SingleCallback has only one method
        #expect(!violations.contains { $0.reason.contains("SingleCallback") })
    }
}
