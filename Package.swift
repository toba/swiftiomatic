// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swiftiomatic",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "SwiftiomaticKit", targets: ["SwiftiomaticKit"]),
        .library(name: "SwiftiomaticSyntax", targets: ["SwiftiomaticSyntax"]),
        .executable(name: "sm", targets: ["SwiftiomaticCLI"]),
        .plugin(name: "Format Source Code", targets: ["FormatPlugin"]),
        .plugin(name: "Lint Source Code", targets: ["LintPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-format.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", .upToNextMinor(from: "0.4.0")),
    ],
    targets: [
        .target(
            name: "SwiftiomaticSyntax",
            dependencies: [
                "SourceKitC",
                .product(name: "SwiftIDEUtils", package: "swift-syntax"),
                .product(name: "SwiftLexicalLookup", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftBasicFormat", package: "swift-syntax"),
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
            name: "SwiftiomaticKit",
            dependencies: [
                "SwiftiomaticSyntax",
                .product(name: "SwiftFormat", package: "swift-format"),
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
        .executableTarget(
            name: "SwiftiomaticCLI",
            dependencies: [
                "SwiftiomaticKit",
                "SwiftiomaticSyntax",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
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
        .executableTarget(
            name: "GeneratePipeline",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
            ],
        ),
        .target(
            name: "SourceKitC",
        ),
        .plugin(
            name: "FormatPlugin",
            capability: .command(
                intent: .sourceCodeFormatting(),
                permissions: [.writeToPackageDirectory(reason: "Formats Swift source files")]
            ),
            dependencies: ["SwiftiomaticCLI"],
            path: "Plugins/FormatPlugin"
        ),
        .plugin(
            name: "LintPlugin",
            capability: .command(
                intent: .custom(verb: "lint-source-code", description: "Lint Swift source files"),
                permissions: []
            ),
            dependencies: ["SwiftiomaticCLI"],
            path: "Plugins/LintPlugin"
        ),
        .testTarget(
            name: "SwiftiomaticTests",
            dependencies: [
                "SwiftiomaticKit",
                "SwiftiomaticSyntax",
                .product(name: "Subprocess", package: "swift-subprocess"),
            ],
            resources: [
                .copy("Suggest/SuggestFixtures"),
                .copy("Configuration/ConfigFixtures"),
                .copy("Format/BadConfig"),
                .copy("Rules/Resources"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("ApproachableConcurrency"),
            ],
        ),
    ],
)
