// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Busybox",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "Busybox", targets: ["Busybox"]),
        .plugin(name: "ContributorGenerator", targets: ["ContributorGenerator"]),
        .plugin(name: "GenerateCodeStats", targets: ["GenerateCodeStats"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "0.50700.1")
    ],
    targets: [
        .target(name: "Busybox", dependencies: []),
        .testTarget(name: "BusyboxTests", dependencies: ["Busybox"]),
        .plugin(
            name: "ContributorGenerator",
            capability: .command(
                intent: .custom(verb: "regenerate-contributors-list",
                                description: "Generates the CONTRIBUTORS.txt file based on Git logs"),
                permissions: [
                    .writeToPackageDirectory(reason: "This command write the new CONTRIBUTORS.txt to the source root.")
                ]
            )
        ),
        .plugin(
            name: "GenerateCodeStats",
            capability: .command(
                intent: .custom(
                    verb: "code-stats", // Verb used from the command line
                    description: "Generates code statistics"),
                permissions: [
                    .writeToPackageDirectory(reason: "Generate code statistics file at root level")
                ])
        ),
    ]
)
