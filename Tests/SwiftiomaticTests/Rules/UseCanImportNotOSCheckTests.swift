import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseCanImportNotOSCheckTests: RuleTesting {
    private static let message =
        "this '#if os(...)' guards only an import; use '#if canImport(...)' to check for the framework, with 'canImport(UIKit)' first or 'canImport(AppKit) && !targetEnvironment(macCatalyst)' so Mac Catalyst picks UIKit"

    @Test func importOnlyOSCheckFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            1️⃣#if os(iOS)
            import UIKit
            #endif

            func haptic() {
              UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func combinedOSConditionsFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            1️⃣#if os(iOS) || os(tvOS)
            import UIKit
            #endif
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func platformSplitNotFlagged() {
        // From toba-ui `PlatformTextAttachment`.
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            public import SwiftUI

            #if os(macOS)
            import AppKit
            #else
            import UIKit
            #endif

            public extension NSTextAttachment {}
            """,
            findings: []
        )
    }

    private static func frameworkMessage(_ framework: String, _ suffix: String = "") -> String {
        "this '#if os(...)' names exactly the platforms that ship \(framework); check '#if canImport(\(framework))\(suffix)' so the code follows the framework, not the platform list"
    }

    @Test func osCheckWithCodeFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            1️⃣#if os(macOS)
            import AppKit

            final class Scroller: NSScroller {}
            #endif
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.frameworkMessage("AppKit", " && !targetEnvironment(macCatalyst)")
                )
            ]
        )
    }

    @Test func wholeFileOSCheckFlagged() {
        // From jig `ClaudeSession.swift`.
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            1️⃣#if os(macOS)

            import AppKit
            import JigKit
            import SwiftUI

            @MainActor struct ClaudeSession {
              let folder: URL?
            }

            #endif
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.frameworkMessage("AppKit", " && !targetEnvironment(macCatalyst)")
                )
            ]
        )
    }

    @Test func everyUIKitPlatformWithCodeFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            1️⃣#if os(iOS) || os(tvOS) || os(visionOS)
            import UIKit

            func haptic() {}
            #else
            func haptic() {}
            #endif
            """,
            findings: [FindingSpec("1️⃣", message: Self.frameworkMessage("UIKit"))]
        )
    }

    @Test func subsetOfFrameworkPlatformsWithCodeNotFlagged() {
        // UIKit ships on more platforms than iOS, so the check is about the platform.
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            #if os(iOS)
            import UIKit

            func haptic() {}
            #endif
            """,
            findings: []
        )
    }

    @Test func platformBehaviorWithoutFrameworkImportNotFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            #if os(macOS)
            import Foundation

            func run() { Process().launch() }
            #endif
            """,
            findings: []
        )
    }

    @Test func platformSplitWithCodeNotFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            #if os(macOS)
            import AppKit
            typealias PlatformImage = NSImage
            #else
            import UIKit
            typealias PlatformImage = UIImage
            #endif
            """,
            findings: []
        )
    }

    @Test func canImportNotFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            #if canImport(UIKit)
            import UIKit
            #endif
            """,
            findings: []
        )
    }

    @Test func mixedConditionNotFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            #if os(iOS) && DEBUG
            import UIKit
            #endif
            """,
            findings: []
        )
    }

    @Test func platformSplitUsedOnlyInsideConditionsFlagged() {
        // From Thesis `ProjectLanguagePicker.swift`.
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            import SwiftUI

            1️⃣#if os(macOS)
            import AppKit
            #else
            import UIKit
            import TobaCore
            public import Foundation
            #endif

            struct ProjectLanguagePicker: View {
              var languages: [String] {
                #if os(macOS)
                let identifiers = NSSpellChecker.shared.availableLanguages
                #else
                let identifiers = UITextChecker.availableLanguages
                #endif
                return identifiers
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }
}
