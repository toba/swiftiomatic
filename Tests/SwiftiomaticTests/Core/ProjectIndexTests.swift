import SwiftSyntax
import Foundation
import Testing
@testable import SwiftiomaticKit

@Suite struct ProjectIndexTests {
    private static let model = """
        @Observable final class Model {
          var value = 0
        }
        """

    @Test func summaryListsTypesMembersAndAliases() {
        let summary = ProjectIndex.summarize(source: """
            struct Row: View {
              let item: Item
              var body: some View { Text("x") }
              func binding() -> Binding<Bool> { Binding(get: { true }, set: { _ in }) }
            }
            extension Row { func helper() {} }
            typealias Action = () -> Void
            """)

        #expect(summary.types.map(\.name) == ["Row", "Row"])
        #expect(summary.types.map(\.isNominal) == [true, false])
        #expect(summary.types[0].memberNames == ["item", "body", "binding"])
        #expect(summary.types[0].bindingMemberNames == ["binding"])
        #expect(summary.typeAliases == ["Action"])
    }

    @Test func foreignEntryMergesOtherFiles() throws {
        let index = ProjectIndex(sources: [
            "/p/Sources/App/Model.swift": Self.model,
            "/p/Sources/App/Model+Extras.swift": "extension Model: Equatable { func reset() {} }",
            "/p/Sources/App/View.swift": "struct V {}",
        ])
        let entry = try #require(index.foreignEntry(
            named: "Model", from: "/p/Sources/App/View.swift", localIsNominal: false))

        #expect(entry.kind == .class)
        #expect(entry.isObservable)
        #expect(entry.conformances.contains("Equatable"))
        #expect(entry.members.isEmpty)
        #expect(entry.foreignMembers["value"]?.count == 1)
        #expect(entry.foreignMembers["reset"]?.count == 1)
    }

    /// Two declarations of one name in other targets are two different types, so the name
    /// resolves to nothing.
    @Test func ambiguousNameOutsideTargetResolvesToNothing() {
        let index = ProjectIndex(sources: [
            "/p/Sources/A/Model.swift": Self.model,
            "/p/Sources/B/Model.swift": "struct Model {}",
            "/p/Sources/C/View.swift": "struct V {}",
        ])
        #expect(index.foreignEntry(
            named: "Model", from: "/p/Sources/C/View.swift", localIsNominal: false) == nil)
    }

    @Test func declarationInSameTargetWins() throws {
        let index = ProjectIndex(sources: [
            "/p/Sources/A/Model.swift": Self.model,
            "/p/Sources/B/Model.swift": "struct Model {}",
            "/p/Sources/A/Views/View.swift": "struct V {}",
        ])
        let entry = try #require(index.foreignEntry(
            named: "Model", from: "/p/Sources/A/Views/View.swift", localIsNominal: false))
        #expect(entry.kind == .class)
    }

    /// A local declaration and one in another target make the name ambiguous for the other file,
    /// so the lookup adds nothing to the local entry.
    @Test func localDeclarationMakesOtherTargetDeclarationAmbiguous() {
        let index = ProjectIndex(sources: [
            "/p/Sources/A/Model.swift": Self.model,
            "/p/Sources/B/View.swift": "struct Model {}",
        ])
        #expect(index.foreignEntry(
            named: "Model", from: "/p/Sources/B/View.swift", localIsNominal: true) == nil)
    }

    /// Extensions alone extend a type from outside the project, so they give no facts.
    @Test func extensionsOfOutsideTypeResolveToNothing() {
        let index = ProjectIndex(sources: [
            "/p/Sources/A/String+X.swift": "extension String { var x: Int { 0 } }",
            "/p/Sources/A/View.swift": "struct V {}",
        ])
        #expect(index.foreignEntry(
            named: "String", from: "/p/Sources/A/View.swift", localIsNominal: false) == nil)
    }

    @Test func foreignTypeAliasResolves() throws {
        let index = ProjectIndex(sources: [
            "/p/Sources/A/Actions.swift": "typealias Action = () -> Void",
            "/p/Sources/A/View.swift": "struct V {}",
        ])
        let target = try #require(index.foreignTypeAlias(
            named: "Action", from: "/p/Sources/A/View.swift"))
        #expect(target.trimmedDescription == "() -> Void")
    }

    @Test func targetDirectoryStopsBelowSources() {
        #expect(ProjectIndex.targetDirectory(of: "/p/Sources/App/Views/Row.swift") == "/p/Sources/App")
        #expect(ProjectIndex.targetDirectory(of: "/p/Tests/AppTests/RowTests.swift") == "/p/Tests/AppTests")
        #expect(ProjectIndex.targetDirectory(of: "/p/App/Row.swift") == "/p/App")
    }

    // MARK: - Dependencies

    private static func index(model: String) -> ProjectIndex {
        ProjectIndex(sources: [
            "/p/Sources/A/Model.swift": model,
            "/p/Sources/A/Other.swift": "struct Other {}",
            "/p/Sources/A/View.swift": "struct V {}",
        ])
    }

    /// A LintCache record stores the digest, so a changed digest makes the lookup miss.
    @Test func digestChangesWhenDependencyChanges() {
        let before = Self.index(model: Self.model)
        let after = Self.index(model: "struct Model {}")
        let keys = ["type:Model"]

        #expect(before.digest(of: keys, from: "/p/Sources/A/View.swift")
            != after.digest(of: keys, from: "/p/Sources/A/View.swift"))
    }

    @Test func digestIgnoresUnrelatedFiles() {
        let before = Self.index(model: Self.model)
        let after = ProjectIndex(sources: [
            "/p/Sources/A/Model.swift": Self.model,
            "/p/Sources/A/Other.swift": "struct Other { var changed = 1 }",
            "/p/Sources/A/View.swift": "struct V { var edited = 2 }",
        ])
        let keys = ["type:Model"]

        #expect(before.digest(of: keys, from: "/p/Sources/A/View.swift")
            == after.digest(of: keys, from: "/p/Sources/A/View.swift"))
    }

    /// A key that named no type changes its digest when a file starts to declare the name.
    @Test func digestChangesWhenNameAppears() {
        let before = ProjectIndex(sources: ["/p/Sources/A/View.swift": "struct V {}"])
        let after = ProjectIndex(sources: [
            "/p/Sources/A/View.swift": "struct V {}",
            "/p/Sources/A/Model.swift": Self.model,
        ])
        #expect(before.digest(of: ["type:Model"], from: "/p/Sources/A/View.swift")
            != after.digest(of: ["type:Model"], from: "/p/Sources/A/View.swift"))
    }

    // MARK: - Scope

    @Test func scopeRootIsNearestPackage() throws {
        let root = try FileManager.default.url(
            for: .itemReplacementDirectory, in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory, create: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = root.appendingPathComponent("Sources/App", isDirectory: true)
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try Data("// swift-tools-version: 6.4\n".utf8)
            .write(to: root.appendingPathComponent("Package.swift"))
        let file = sources.appendingPathComponent("Row.swift")
        try Data("struct Row {}\n".utf8).write(to: file)
        try Data(Self.model.utf8).write(to: sources.appendingPathComponent("Model.swift"))

        let scope = try #require(ProjectIndex.scopeRoot(startingAt: file.path))
        #expect(scope.standardizedFileURL.path == root.standardizedFileURL.path)

        let index = ProjectIndex.build(root: scope, excludes: defaultRecursionExcludes)
        #expect(index.summaries.count == 2)
        #expect(index.foreignEntry(
            named: "Model", from: ProjectIndex.key(for: file.path), localIsNominal: false)?
            .isObservable == true)
    }

    /// The summary cache gives the same index, and a changed file gets a new summary.
    @Test func summaryCacheRoundTrips() throws {
        let root = try FileManager.default.url(
            for: .itemReplacementDirectory, in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory, create: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = root.appendingPathComponent(".build/sm-lint-cache", isDirectory: true)
        let file = root.appendingPathComponent("Model.swift")
        try Data(Self.model.utf8).write(to: file)

        let first = ProjectIndex.build(root: root, excludes: defaultRecursionExcludes, cacheDirectory: cache)
        let second = ProjectIndex.build(root: root, excludes: defaultRecursionExcludes, cacheDirectory: cache)
        #expect(first.summaries == second.summaries)

        try Data("struct Model {}\n".utf8).write(to: file)
        let third = ProjectIndex.build(root: root, excludes: defaultRecursionExcludes, cacheDirectory: cache)
        #expect(third.summaries[ProjectIndex.key(for: file.path)]?.types.first?.memberNames == [])
    }
}
