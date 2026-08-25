import Testing
import Foundation
@testable import SwiftiomaticKit

@Suite
final class XcodeInstallationTests {
    private let tmpdir: URL

    init() throws {
        tmpdir = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory,
            create: true
        )
    }

    deinit {
        try? FileManager.default.removeItem(at: tmpdir)
    }

    @Test("discover finds the release Xcode and the beta")
    func discoversReleaseAndBeta() throws {
        let apps = tmpdir.appending(path: "Applications")
        try makeXcode(named: "Xcode.app", in: apps)
        try makeXcode(named: "Xcode-beta.app", in: apps)

        let found = XcodeInstallation.discover(in: [apps])

        #expect(found.map(\.name) == ["Xcode.app", "Xcode-beta.app"])
        #expect(found.map(\.isBeta) == [false, true])
        #expect(
            found[1].swiftFormatURL
                .path
                == apps.appending(path: "Xcode-beta.app").path
                + "/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-format"
        )
    }

    @Test("discover puts the release Xcode ahead of every beta")
    func sortsReleaseFirst() throws {
        let apps = tmpdir.appending(path: "Applications")
        try makeXcode(named: "Xcode-beta.app", in: apps)
        try makeXcode(named: "Xcode-27-beta.app", in: apps)
        try makeXcode(named: "Xcode.app", in: apps)

        let found = XcodeInstallation.discover(in: [apps])

        #expect(found.map(\.name) == ["Xcode.app", "Xcode-27-beta.app", "Xcode-beta.app"])
    }

    @Test("discover skips an application without a toolchain")
    func skipsApplicationWithoutToolchain() throws {
        let apps = tmpdir.appending(path: "Applications")
        try makeXcode(named: "Xcode.app", in: apps)
        try FileManager.default.createDirectory(
            at: apps.appending(path: "Xcode-broken.app/Contents"), withIntermediateDirectories: true
        )

        let found = XcodeInstallation.discover(in: [apps])

        #expect(found.map(\.name) == ["Xcode.app"])
    }

    @Test("discover ignores an application that is not Xcode")
    func ignoresOtherApplications() throws {
        let apps = tmpdir.appending(path: "Applications")
        try makeXcode(named: "Xcode.app", in: apps)
        try makeXcode(named: "Numbers.app", in: apps)

        let found = XcodeInstallation.discover(in: [apps])

        #expect(found.map(\.name) == ["Xcode.app"])
    }

    @Test("discover reads several directories and drops a repeated path")
    func mergesDirectories() throws {
        let system = tmpdir.appending(path: "Applications")
        let user = tmpdir.appending(path: "Users/tester/Applications")
        try makeXcode(named: "Xcode.app", in: system)
        try makeXcode(named: "Xcode-beta.app", in: user)

        let found = XcodeInstallation.discover(in: [system, user, system])

        #expect(found.map(\.name) == ["Xcode.app", "Xcode-beta.app"])
    }

    @Test("discover tolerates a missing directory")
    func toleratesMissingDirectory() throws {
        let apps = tmpdir.appending(path: "Applications")
        try makeXcode(named: "Xcode.app", in: apps)

        let found = XcodeInstallation.discover(in: [apps, tmpdir.appending(path: "Nowhere")])

        #expect(found.map(\.name) == ["Xcode.app"])
    }

    /// Create an application bundle that holds the toolchain directory `discover` looks for
    private func makeXcode(named name: String, in directory: URL) throws {
        try FileManager.default.createDirectory(
            at: directory.appending(path: name).appending(
                path: "Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
            ),
            withIntermediateDirectories: true
        )
    }
}
