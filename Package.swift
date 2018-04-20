// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Bugsnag",
    products: [
        .library(name: "Bugsnag", targets: ["Bugsnag"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc.2")
    ],
    targets: [
        .target(name: "Bugsnag", dependencies: ["Vapor"]),
        .testTarget(name: "BugsnagTests", dependencies: ["Bugsnag"])
    ]
)
