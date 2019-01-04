// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Bugsnag",
    products: [
        .library(
            name: "Bugsnag",
            targets: ["Bugsnag"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "Bugsnag",
            dependencies: ["Vapor", "Authentication"]),
        .testTarget(
            name: "BugsnagTests",
            dependencies: ["Bugsnag", "Vapor"]),
    ]
)
