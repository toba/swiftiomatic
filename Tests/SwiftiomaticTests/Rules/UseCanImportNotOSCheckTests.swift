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

    @Test func osCheckWithCodeNotFlagged() {
        assertLint(
            UseCanImportNotOSCheck.self,
            """
            #if os(macOS)
            import AppKit

            final class Scroller: NSScroller {}
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
