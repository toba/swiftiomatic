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
        .executableTarget(
            name: "Swiftiomatic",
            dependencies: [
                "DyldWarningWorkaround",
                "SwiftLintCoreMacros",
                "CollectionConcurrencyKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "SwiftIDEUtils", package: "swift-syntax"),
                .product(name: "SwiftLexicalLookup", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftyTextTable", package: "SwiftyTextTable"),
                .product(name: "Yams", package: "Yams"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableUpcomingFeature("DisableOutwardActorIsolation"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),
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
            path: "Sources/Lint/Macros",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "SwiftiomaticTests",
            dependencies: ["Swiftiomatic"],
            resources: [.copy("Fixtures")],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
