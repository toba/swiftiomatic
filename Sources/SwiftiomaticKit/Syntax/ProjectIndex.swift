package import CryptoKit
package import Foundation
package import SwiftOperators
package import SwiftParser
package import SwiftSyntax
package import Synchronization

/// The type facts of every Swift file in one project, for the lint rules that resolve a name
/// declared in another file.
///
/// A pre-pass parses every `.swift` file under the scope root and keeps a small summary for each
/// file: the types it declares or extends, the member names of each, and its typealiases. A rule
/// reads the summary through `Context.typeMembers(around:)` . When a rule needs the declarations of
/// a type in another file, the index parses that file once on demand and keeps its tree for the
/// rest of the run.
///
/// The index resolves names by simple name. When more than one file declares a nominal type with
/// the same name, the declaration in the target directory of the linted file wins. When that does
/// not settle it, the name is ambiguous and resolves to the facts of the linted file alone.
///
/// The index is lint-only. `sm format` does not read it.
package final class ProjectIndex: Sendable {
    /// The facts one file declares, cheap to compute and to store.
    package struct FileSummary: Codable, Sendable, Equatable {
        /// One type declaration or extension in the file.
        package struct TypeDeclaration: Codable, Sendable, Equatable {
            /// The simple name the declaration declares or extends.
            package var name: String
            /// Whether it is a struct, class, enum or actor declaration, not an extension.
            package var isNominal: Bool
            /// The base names of its members.
            package var memberNames: [String]
            /// The base names of its members whose declaration names `Binding` , the candidates for
            /// a helper that builds a binding from closures.
            package var bindingMemberNames: [String]
        }

        /// The SHA-256 of the file bytes, hex-encoded.
        package var contentHash: String
        package var types: [TypeDeclaration]
        /// The simple names of the typealiases in the file.
        package var typeAliases: [String]
        /// The names from `ProjectIndex.trackedNames` that the file uses as an identifier, sorted.
        package var referencedNames: [String] = []
        /// The simple names of the classes in the file that carry `@Model` , sorted.
        package var modelTypeNames: [String] = []
    }

    /// The identifiers whose use the index records for each file. A rule reads them to learn
    /// whether the project uses a framework type, such as `CKSyncEngine` .
    package static let trackedNames: Set<String> = ["CKSyncEngine", "DocumentGroup"]

    /// A file that the index parsed on demand.
    package final class LoadedFile: Sendable {
        package let tree: SourceFileSyntax
        package let converter: SourceLocationConverter
        let members: TypeMemberIndex

        init(tree: SourceFileSyntax, displayPath: String) {
            self.tree = tree
            converter = SourceLocationConverter(fileName: displayPath, tree: tree)
            members = TypeMemberIndex(root: Syntax(tree))
        }
    }

    /// The most files the pre-pass reads. A larger scope is most likely not one project, such as a
    /// home directory, so the index stays empty.
    package static let fileLimit = 20_000

    /// The summary of each file, keyed by standardized absolute path.
    package let summaries: [String: FileSummary]

    /// Source text that replaces the file on disk, keyed by standardized absolute path.
    private let overrides: [String: String]

    /// The paths of the files that declare or extend each type name, sorted.
    private let typeFiles: [String: [String]]

    /// The paths of the files that declare each typealias name, sorted.
    private let aliasFiles: [String: [String]]

    /// The type names whose member of each base name names `Binding` , sorted.
    private let bindingMemberOwners: [String: [String]]

    /// The paths of the files that use each tracked name, sorted.
    private let referenceFiles: [String: [String]]

    /// The paths of the files that declare a `@Model` class of each name, sorted.
    private let modelTypeFiles: [String: [String]]

    private let loaded = Mutex<[String: LoadedFile]>([:])

    /// The root identities of the loaded trees, so a check for a foreign node needs no path.
    private let loadedRoots = Mutex<Set<SyntaxIdentifier>>([])

    /// Creates an index from summaries that the caller computed.
    ///
    /// - Parameters:
    ///   - summaries: The summary of each file, keyed by standardized absolute path.
    ///   - overrides: Source text that replaces the file on disk, such as stdin text.
    package init(summaries: [String: FileSummary], overrides: [String: String] = [:]) {
        self.summaries = summaries
        self.overrides = overrides

        var typeFiles: [String: Set<String>] = [:]
        var aliasFiles: [String: Set<String>] = [:]
        var bindingMemberOwners: [String: Set<String>] = [:]
        var referenceFiles: [String: Set<String>] = [:]
        var modelTypeFiles: [String: Set<String>] = [:]

        for (path, summary) in summaries {
            for name in summary.referencedNames { referenceFiles[name, default: []].insert(path) }
            for name in summary.modelTypeNames { modelTypeFiles[name, default: []].insert(path) }
            for type in summary.types {
                typeFiles[type.name, default: []].insert(path)
                for member in type.bindingMemberNames {
                    bindingMemberOwners[member, default: []].insert(type.name)
                }
            }
            for alias in summary.typeAliases { aliasFiles[alias, default: []].insert(path) }
        }
        self.typeFiles = typeFiles.mapValues { $0.sorted() }
        self.aliasFiles = aliasFiles.mapValues { $0.sorted() }
        self.bindingMemberOwners = bindingMemberOwners.mapValues { $0.sorted() }
        self.referenceFiles = referenceFiles.mapValues { $0.sorted() }
        self.modelTypeFiles = modelTypeFiles.mapValues { $0.sorted() }
    }

    /// Creates an index over in-memory sources, as tests and stdin runs need.
    ///
    /// - Parameter sources: The text of each file, keyed by path. A relative path resolves against
    ///   the working directory.
    package convenience init(sources: [String: String]) {
        var summaries: [String: FileSummary] = [:]
        var overrides: [String: String] = [:]

        for (path, source) in sources {
            let key = Self.key(for: path)
            summaries[key] = Self.summarize(source: source)
            overrides[key] = source
        }
        self.init(summaries: summaries, overrides: overrides)
    }

    // MARK: - Scope

    /// The root of the project that holds `path` , or `nil` when no project holds it
    ///
    /// The root is the nearest directory with a `Package.swift` . Without one, it is the nearest
    /// directory with a `.git` entry, which holds an app project.
    package static func scopeRoot(startingAt path: String) -> URL? {
        var directory = URL(fileURLWithPath: path).standardizedFileURL
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: directory.path, isDirectory: &isDirectory)
        if !exists || !isDirectory.boolValue { directory = directory.deletingLastPathComponent() }

        var gitRoot: URL?

        while true {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent(
                "Package.swift", isDirectory: false).path) { return directory }
            if gitRoot == nil,
               FileManager.default.fileExists(atPath: directory.appendingPathComponent(
                   ".git", isDirectory: false).path) { gitRoot = directory }

            let parent = directory.deletingLastPathComponent().standardizedFileURL
            if parent.path == directory.path { break }
            directory = parent
        }
        return gitRoot
    }

    /// Builds the index of every `.swift` file under `root`
    ///
    /// - Parameters:
    ///   - root: The scope root.
    ///   - excludes: The glob patterns of the files and directories to skip.
    ///   - overrides: Source text that replaces the file on disk, keyed by path.
    ///   - cacheDirectory: The directory that holds the summary cache, or `nil` for no cache.
    package static func build(
        root: URL,
        excludes: [String],
        overrides: [String: String] = [:],
        cacheDirectory: URL? = nil
    ) -> ProjectIndex {
        var paths: [String] = []

        for url in FileIterator(urls: [root], followSymlinks: false, excludes: excludes) {
            // A package manifest declares no project types
            let name = url.lastPathComponent
            if name == "Package.swift" || name.hasPrefix("Package@swift") { continue }
            paths.append(url.standardizedFileURL.path)
            if paths.count > fileLimit { return ProjectIndex(summaries: [:]) }
        }

        let keyedOverrides = Dictionary(
            overrides.map { (key(for: $0.key), $0.value) }, uniquingKeysWith: { $1 })
        for path in keyedOverrides.keys where !paths.contains(path) { paths.append(path) }

        let cacheURL = cacheDirectory.map { summaryCacheURL(in: $0, root: root) }
        let cached = cacheURL.flatMap(readSummaryCache) ?? [:]

        let results = Mutex<[String: FileSummary]>([:])
        paths.withUnsafeBufferPointer { buffer in
            DispatchQueue.concurrentPerform(iterations: buffer.count) { index in
                let path = buffer[index]
                let source: String

                if let text = keyedOverrides[path] {
                    source = text
                } else if let data = FileManager.default.contents(atPath: path) {
                    source = String(decoding: data, as: UTF8.self)
                } else {
                    return
                }
                let hash = LintCache.contentHash(of: source)
                let summary = cached[path].flatMap { $0.contentHash == hash ? $0 : nil }
                    ?? summarize(source: source, contentHash: hash)
                results.withLock { $0[path] = summary }
            }
        }
        let summaries = results.withLock { $0 }

        // The stdin text is not the file on disk, so it does not go into the cache
        if let cacheURL {
            let onDisk = summaries.filter { keyedOverrides[$0.key] == nil }
            if onDisk != cached { writeSummaryCache(onDisk, to: cacheURL) }
        }
        return ProjectIndex(summaries: summaries, overrides: keyedOverrides)
    }

    /// The key of a file: its standardized absolute path.
    package static func key(for path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }

    // MARK: - Summaries

    /// Computes the summary of one file
    package static func summarize(source: String, contentHash: String? = nil) -> FileSummary {
        let collector = SummaryCollector(viewMode: .sourceAccurate)
        let tree = Parser.parse(source: source)
        collector.walk(tree)
        return FileSummary(
            contentHash: contentHash ?? LintCache.contentHash(of: source),
            types: collector.types,
            typeAliases: collector.typeAliases,
            referencedNames: referencedNames(in: tree, source: source),
            modelTypeNames: collector.modelTypeNames.sorted()
        )
    }

    /// The names from `trackedNames` that `tree` uses as an identifier, sorted
    ///
    /// A text search on `source` skips the token walk for a file that holds no tracked name.
    package static func referencedNames(in tree: SourceFileSyntax, source: String) -> [String] {
        let candidates = trackedNames.filter { source.contains($0) }
        guard !candidates.isEmpty else { return [] }
        var found: Set<String> = []

        for token in tree.tokens(viewMode: .sourceAccurate) {
            if case let .identifier(text) = token.tokenKind, candidates.contains(text) {
                found.insert(text)
            }
        }
        return found.sorted()
    }

    private final class SummaryCollector: SyntaxVisitor {
        var types: [FileSummary.TypeDeclaration] = []
        var typeAliases: [String] = []
        var modelTypeNames: [String] = []

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), isNominal: true, members: node.memberBlock)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.attributes.attribute(named: "Model", module: "SwiftData") != nil {
                modelTypeNames.append(node.name.text)
            }
            return record(Syntax(node), isNominal: true, members: node.memberBlock)
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), isNominal: true, members: node.memberBlock)
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), isNominal: true, members: node.memberBlock)
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            record(Syntax(node), isNominal: false, members: node.memberBlock)
        }

        override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            typeAliases.append(node.name.text)
            return .skipChildren
        }

        // Code bodies hold no member declarations, so the walk skips them
        override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

        override func visit(_: AccessorBlockSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

        override func visit(_: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func record(
            _ decl: Syntax,
            isNominal: Bool,
            members: MemberBlockSyntax
        ) -> SyntaxVisitorContinueKind {
            guard let name = TypeMemberIndex.typeName(of: decl) else { return .visitChildren }
            var names: [String] = []
            var bindingNames: [String] = []

            for item in members.members {
                var declared: [String] = []

                if let function = item.decl.as(FunctionDeclSyntax.self) {
                    declared = [function.name.text]
                } else if let variable = item.decl.as(VariableDeclSyntax.self) {
                    declared = variable.bindings.compactMap {
                        $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                    }
                }
                guard !declared.isEmpty else { continue }
                names += declared
                if Self.namesBinding(item.decl) { bindingNames += declared }
            }
            types.append(.init(
                name: name, isNominal: isNominal, memberNames: names,
                bindingMemberNames: bindingNames))
            return .visitChildren
        }

        /// Whether a token of `decl` is the identifier `Binding`
        private static func namesBinding(_ decl: DeclSyntax) -> Bool {
            decl.tokens(viewMode: .sourceAccurate).contains {
                $0.tokenKind == .identifier("Binding")
            }
        }
    }

    // MARK: - Summary cache

    private struct SummaryCache: Codable {
        static let currentVersion = 2

        var version: Int
        var summaries: [String: FileSummary]
    }

    private static func summaryCacheURL(in directory: URL, root: URL) -> URL {
        let digest = LintCache.hexEncode(SHA256.hash(data: Data(root.standardizedFileURL.path.utf8)))
        return directory.appendingPathComponent("project-index", isDirectory: true)
            .appendingPathComponent("\(digest.prefix(16)).json", isDirectory: false)
    }

    private static func readSummaryCache(_ url: URL) -> [String: FileSummary]? {
        guard let data = try? Data(contentsOf: url),
              let cache = try? JSONDecoder().decode(SummaryCache.self, from: data),
              cache.version == SummaryCache.currentVersion else { return nil }
        return cache.summaries
    }

    /// Writes the cache with a write-then-rename, so a concurrent reader never sees half a file.
    private static func writeSummaryCache(_ summaries: [String: FileSummary], to url: URL) {
        let cache = SummaryCache(version: SummaryCache.currentVersion, summaries: summaries)
        guard let data = try? JSONEncoder().encode(cache) else { return }
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(
            ".\(url.lastPathComponent).\(UUID().uuidString)", isDirectory: false)
        do {
            try data.write(to: temporary)
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
        } catch {
            try? FileManager.default.removeItem(at: temporary)
        }
    }

    // MARK: - Lookups

    /// The facts and members that files other than `file` hold for the type `name` , or `nil`
    /// when no other file holds the type or the name is ambiguous
    ///
    /// The members of the result are in `foreignMembers` . Its `members` is empty.
    ///
    /// - Parameters:
    ///   - name: The simple type name.
    ///   - file: The key of the linted file.
    ///   - localIsNominal: Whether the linted file declares the type itself.
    func foreignEntry(
        named name: String,
        from file: String,
        localIsNominal: Bool
    ) -> TypeMemberIndex.TypeEntry? {
        guard let paths = typeFiles[name]?.filter({ $0 != file }), !paths.isEmpty,
              let chosen = resolve(name, paths: paths, from: file, localIsNominal: localIsNominal),
              !chosen.isEmpty else { return nil }

        var entry = TypeMemberIndex.TypeEntry()

        for path in chosen {
            guard let other = load(path)?.members.types.local[name] else { continue }
            entry.kind = entry.kind ?? other.kind
            entry.isObservable = entry.isObservable || other.isObservable
            entry.isView = entry.isView || other.isView
            entry.conformances.formUnion(other.conformances)
            entry.hasPayloadCases = entry.hasPayloadCases || other.hasPayloadCases
            for (member, list) in other.members { entry.foreignMembers[member, default: []] += list }
        }
        return entry
    }

    /// The target type of the typealias `name` that one other file declares, or `nil`
    func foreignTypeAlias(named name: String, from file: String) -> TypeSyntax? {
        guard var paths = aliasFiles[name]?.filter({ $0 != file }), !paths.isEmpty else {
            return nil
        }
        if paths.count > 1 {
            let target = Self.targetDirectory(of: file)
            paths = paths.filter { Self.targetDirectory(of: $0) == target }
        }
        guard paths.count == 1 else { return nil }
        return load(paths[0])?.members.typeAliases.local[name]
    }

    /// The names of the types, in any file, whose member with the base name `member` names
    /// `Binding`
    package func typesWithBindingMember(named member: String) -> [String] {
        bindingMemberOwners[member] ?? []
    }

    /// The paths of the files that use the tracked name `name` as an identifier
    package func filesReferencing(_ name: String) -> [String] {
        referenceFiles[name] ?? []
    }

    /// The paths of the files that declare a `@Model` class named `name`
    package func filesDeclaringModel(named name: String) -> [String] {
        modelTypeFiles[name] ?? []
    }

    /// The paths among `paths` whose declarations of `name` the lookup merges, or `nil` when the
    /// name is ambiguous or names no project type
    private func resolve(
        _ name: String,
        paths: [String],
        from file: String,
        localIsNominal: Bool
    ) -> [String]? {
        let nominalPaths = paths.filter { path in
            summaries[path]?.types.contains { $0.name == name && $0.isNominal } == true
        }
        let nominalCount = nominalPaths.reduce(localIsNominal ? 1 : 0) { count, path in
            count + (summaries[path]?.types.count { $0.name == name && $0.isNominal } ?? 0)
        }
        // Extensions alone extend a type from outside the project, such as an SDK type
        if nominalCount == 0 { return nil }
        if nominalCount == 1 { return paths }

        // A declaration in the target of the linted file wins
        let target = Self.targetDirectory(of: file)
        let sameTarget = paths.filter { Self.targetDirectory(of: $0) == target }
        let sameTargetNominal = sameTarget.reduce(localIsNominal ? 1 : 0) { count, path in
            count + (summaries[path]?.types.count { $0.name == name && $0.isNominal } ?? 0)
        }
        guard sameTargetNominal == 1 else { return nil }
        return sameTarget
    }

    /// The directory of the target that holds `path` : the path up to the directory below the
    /// nearest `Sources` or `Tests` directory, or the parent directory of the file
    package static func targetDirectory(of path: String) -> String {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)

        if let index = components.lastIndex(where: { $0 == "Sources" || $0 == "Tests" }),
           index + 2 < components.count
        {
            return components[...(index + 1)].joined(separator: "/")
        }
        return components.dropLast().joined(separator: "/")
    }

    // MARK: - Loaded files

    /// The parsed tree and member index of the file at `path` , parsed on first use
    package func load(_ path: String) -> LoadedFile? {
        if let file = loaded.withLock({ $0[path] }) { return file }

        let source: String
        if let text = overrides[path] {
            source = text
        } else if let data = FileManager.default.contents(atPath: path) {
            source = String(decoding: data, as: UTF8.self)
        } else {
            return nil
        }
        let tree = OperatorTable.standardOperators.foldAll(Parser.parse(source: source)) { _ in }
            .as(SourceFileSyntax.self) ?? Parser.parse(source: source)
        let file = LoadedFile(tree: tree, displayPath: Self.displayPath(of: path))

        // Two workers can parse the same file at once. The first one stored wins, so every rule
        // sees one tree for the file.
        let stored = loaded.withLock { files in
            if let existing = files[path] { return existing }
            files[path] = file
            return file
        }
        loadedRoots.withLock { _ = $0.insert(stored.tree.id) }
        return stored
    }

    /// The loaded file that holds `node` , or `nil` when the index did not load its tree
    package func loadedFile(holding node: some SyntaxProtocol) -> LoadedFile? {
        let root = node.root.id
        guard loadedRoots.withLock({ $0.contains(root) }) else { return nil }
        return loaded.withLock { $0.values.first { $0.tree.id == root } }
    }

    /// Whether `node` belongs to a tree that the index loaded from another file
    package func isForeign(_ node: some SyntaxProtocol) -> Bool {
        let root = node.root.id
        return loadedRoots.withLock { $0.contains(root) }
    }

    /// The path relative to the working directory when it is under it, else the absolute path
    private static func displayPath(of path: String) -> String {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .standardizedFileURL.path
        guard cwd != "/", path.hasPrefix(cwd + "/") else { return path }
        return String(path.dropFirst(cwd.count + 1))
    }

    // MARK: - Dependencies

    /// A digest of the index entries that `keys` name, as the linted file `file` sees them
    ///
    /// A key is `type:<Name>` , `alias:<Name>` or `binding:<member>` . The digest covers the content
    /// hash of every other file that holds the key, so an edit to one of those files, a new file
    /// that declares the name, or a removed one changes it.
    package func digest(of keys: some Sequence<String>, from file: String) -> String {
        var hasher = SHA256()

        for key in keys.sorted() {
            hasher.update(data: Data(key.utf8))
            hasher.update(data: Data([0]))

            let paths: [String]
            if key.hasPrefix("type:") {
                paths = typeFiles[String(key.dropFirst(5))] ?? []
            } else if key.hasPrefix("alias:") {
                paths = aliasFiles[String(key.dropFirst(6))] ?? []
            } else if key.hasPrefix("binding:") {
                paths = (bindingMemberOwners[String(key.dropFirst(8))] ?? []).flatMap {
                    typeFiles[$0] ?? []
                }
            } else if key.hasPrefix("ref:") {
                paths = referenceFiles[String(key.dropFirst(4))] ?? []
            } else if key.hasPrefix("model:") {
                paths = modelTypeFiles[String(key.dropFirst(6))] ?? []
            } else {
                paths = []
            }
            for path in Set(paths).sorted() where path != file {
                hasher.update(data: Data(path.utf8))
                hasher.update(data: Data([0]))
                hasher.update(data: Data((summaries[path]?.contentHash ?? "").utf8))
                hasher.update(data: Data([0]))
            }
        }
        return LintCache.hexEncode(hasher.finalize())
    }
}

/// The project lookups of one linted file, and the keys they read.
///
/// `Context` creates one for each file. `TypeMemberIndex` asks it for the facts of other files, and
/// the lint cache stores the keys it records.
package final class ProjectLookup: Sendable {
    package let index: ProjectIndex

    /// The key of the linted file.
    package let file: String

    private let recorded = Mutex<Set<String>>([])

    package init(index: ProjectIndex, file: String) {
        self.index = index
        self.file = file
    }

    /// The keys that the lookups of this file read, such as `type:Book` .
    package var keys: Set<String> { recorded.withLock { $0 } }

    /// The merged foreign entry of each name that a lookup read. A rule reads the same names many
    /// times in one file, and each merge copies the member lists.
    private let entries = Mutex<[String: TypeMemberIndex.TypeEntry?]>([:])

    func foreignEntry(named name: String, localIsNominal: Bool) -> TypeMemberIndex.TypeEntry? {
        if let cached = entries.withLock({ $0[name] }) { return cached }
        recorded.withLock { _ = $0.insert("type:\(name)") }
        let entry = index.foreignEntry(named: name, from: file, localIsNominal: localIsNominal)
        entries.withLock { $0[name] = .some(entry) }
        return entry
    }

    func foreignTypeAlias(named name: String) -> TypeSyntax? {
        recorded.withLock { _ = $0.insert("alias:\(name)") }
        return index.foreignTypeAlias(named: name, from: file)
    }

    /// The names of the types whose member with the base name `member` names `Binding`
    func typesWithBindingMember(named member: String) -> [String] {
        recorded.withLock { _ = $0.insert("binding:\(member)") }
        return index.typesWithBindingMember(named: member)
    }

    /// Whether a file other than this one uses the tracked name `name` as an identifier
    func otherFileReferences(_ name: String) -> Bool {
        recorded.withLock { _ = $0.insert("ref:\(name)") }
        return index.filesReferencing(name).contains { $0 != file }
    }

    /// Whether a file other than this one declares a `@Model` class named `name`
    func otherFileDeclaresModel(named name: String) -> Bool {
        recorded.withLock { _ = $0.insert("model:\(name)") }
        return index.filesDeclaringModel(named: name).contains { $0 != file }
    }
}
