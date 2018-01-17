// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Bugsnag",
    products: [
        .library(name: "Bugsnag", targets: ["Bugsnag"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .branch("beta")),
        .package(url: "https://github.com/vapor/core.git", .branch("beta"))
    ],
    targets: [
        .target(name: "Bugsnag", dependencies: ["Vapor", "Core"]),
        .testTarget(name: "BugsnagTests", dependencies: ["Bugsnag"])
    ]
)
