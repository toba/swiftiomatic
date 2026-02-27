// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swiftiomatic",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "swiftiomatic", targets: ["Swiftiomatic"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "604.0.0-prerelease-2026-01-20"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.2"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.37.2"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0"),
        .package(url: "https://github.com/ileitch/swift-filename-matcher", .upToNextMinor(from: "2.0.1")),
    ],
    targets: [
        // MARK: - Swiftiomatic CLI
        .executableTarget(
            name: "Swiftiomatic",
            dependencies: [
                "Suggest",
                "Format",
                "SourceKitService",
                "Lint",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),

        // MARK: - Suggest (AST-based analysis)
        .target(
            name: "Suggest",
            dependencies: [
                "SourceKitService",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/Suggest"
        ),
        .target(
            name: "SourceKitService",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
            ],
        ),
        .target(
            name: "Format",
            dependencies: [],
            path: "Sources/Format"
        ),

        // MARK: - SwiftLint (vendored from SwiftLint 0.63.2)
        .target(
            name: "DyldWarningWorkaround",
            path: "Sources/Lint/DyldWarningWorkaround"
        ),
        .macro(
            name: "SwiftLintCoreMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/Lint/Macros"
        ),
        .target(
            name: "SwiftLintCore",
            dependencies: [
                .target(name: "DyldWarningWorkaround"),
                .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "SwiftIDEUtils", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftyTextTable", package: "SwiftyTextTable"),
                .product(name: "Yams", package: "Yams"),
                "SwiftLintCoreMacros",
            ],
            path: "Sources/Lint/Core"
        ),
        .target(
            name: "SwiftLintBuiltInRules",
            dependencies: [
                .product(name: "SwiftLexicalLookup", package: "swift-syntax"),
                "SwiftLintCore",
            ],
            path: "Sources/Lint/BuiltInRules"
        ),
        .target(
            name: "SwiftLintExtraRules",
            dependencies: ["SwiftLintCore"],
            path: "Sources/Lint/ExtraRules"
        ),
        .target(
            name: "Lint",
            dependencies: [
                .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
                "SwiftLintBuiltInRules",
                "SwiftLintCore",
                "SwiftLintExtraRules",
                "CollectionConcurrencyKit",
            ],
            path: "Sources/Lint/Framework",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        // MARK: - Tests
        .testTarget(
            name: "SwiftiomaticTests",
            dependencies: ["Suggest", "SourceKitService"],
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
