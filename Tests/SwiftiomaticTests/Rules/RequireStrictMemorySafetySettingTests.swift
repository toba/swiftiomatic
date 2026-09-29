import Foundation
import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireStrictMemorySafetySettingTests: RuleTesting {
  private static let manifest = URL(fileURLWithPath: "/pkg/Package.swift")

  private static func message(_ target: String) -> String {
    "add '.strictMemorySafety()' to the 'swiftSettings' of '\(target)'. Every target must opt in to strict memory safety"
  }

  @Test func targetsWithoutSettingFlagged() {
    assertLint(
      RequireStrictMemorySafetySetting.self,
      """
      let package = Package(
        name: "Demo",
        targets: [
          .1️⃣target(name: "Core"),
          .2️⃣executableTarget(name: "Tool", dependencies: ["Core"]),
          .3️⃣testTarget(name: "CoreTests", swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
          .4️⃣macro(name: "Macros", dependencies: []),
        ]
      )
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("Core")),
        FindingSpec("2️⃣", message: Self.message("Tool")),
        FindingSpec("3️⃣", message: Self.message("CoreTests")),
        FindingSpec("4️⃣", message: Self.message("Macros")),
      ],
      assumingFileURL: Self.manifest
    )
  }

  @Test func inlineSettingNotFlagged() {
    assertLint(
      RequireStrictMemorySafetySetting.self,
      """
      let package = Package(
        name: "Demo",
        targets: [
          .target(name: "Core", swiftSettings: [.strictMemorySafety()]),
          .testTarget(
            name: "CoreTests",
            swiftSettings: [.enableUpcomingFeature("ExistentialAny"), .strictMemorySafety()]
          ),
        ]
      )
      """,
      findings: [],
      assumingFileURL: Self.manifest
    )
  }

  @Test func sharedSettingsVariableResolved() {
    assertLint(
      RequireStrictMemorySafetySetting.self,
      """
      let swiftSettings: [SwiftSetting] = [
        .swiftLanguageMode(.v6),
        .strictMemorySafety(),
      ]
      let testSettings = swiftSettings + [.define("TESTING")]
      let looseSettings: [SwiftSetting] = [.swiftLanguageMode(.v6)]

      let package = Package(
        name: "Demo",
        targets: [
          .target(name: "Core", swiftSettings: swiftSettings),
          .testTarget(name: "CoreTests", swiftSettings: testSettings),
          .1️⃣target(name: "Loose", swiftSettings: looseSettings),
        ]
      )
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("Loose"))],
      assumingFileURL: Self.manifest
    )
  }

  @Test func settingsAppliedInTargetsLoopNotFlagged() {
    assertLint(
      RequireStrictMemorySafetySetting.self,
      """
      let package = Package(
        name: "Demo",
        targets: [.target(name: "Core")]
      )

      for target in package.targets {
        target.swiftSettings = (target.swiftSettings ?? []) + [.strictMemorySafety()]
      }
      """,
      findings: [],
      assumingFileURL: Self.manifest
    )
  }

  @Test func nonSwiftTargetsNotFlagged() {
    assertLint(
      RequireStrictMemorySafetySetting.self,
      """
      let package = Package(
        name: "Demo",
        targets: [
          .binaryTarget(name: "Lib", path: "Lib.xcframework"),
          .systemLibrary(name: "CZlib"),
          .plugin(
            name: "Gen",
            capability: .buildTool(),
            dependencies: [.target(name: "Tool"), .product(name: "Parser", package: "syntax")]
          ),
        ]
      )
      """,
      findings: [],
      assumingFileURL: Self.manifest
    )
  }

  @Test func otherFilesNotFlagged() {
    assertLint(
      RequireStrictMemorySafetySetting.self,
      """
      let targets = [Target.target(name: "Core")]
      let other = [.target(name: "Tool")]
      """,
      findings: []
    )
  }
}
