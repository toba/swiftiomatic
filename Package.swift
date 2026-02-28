// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swiftiomatic",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "swiftiomatic", targets: ["Swiftiomatic"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "604.0.0-prerelease-2026-01-20",
        ),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.2"),
    ],
    targets: [
        .executableTarget(
            name: "Swiftiomatic",
            dependencies: [
                "DyldWarningWorkaround",
                "SourceKitC",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftIDEUtils", package: "swift-syntax"),
                .product(name: "SwiftLexicalLookup", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "Yams", package: "Yams"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableUpcomingFeature("DisableOutwardActorIsolation"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ],
        ),
        .target(
            name: "DyldWarningWorkaround",
            path: "Sources/DyldWarningWorkaround",
        ),
        .target(
            name: "SourceKitC",
        ),
        .testTarget(
            name: "SwiftiomaticTests",
            dependencies: [
                "Swiftiomatic",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            resources: [
                .copy("Fixtures"),
                .copy("FormatTests/BadConfig"),
                .copy("RuleTests/BuiltInRules/BuiltInRulesResources"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
            ],
        ),
    ],
)
