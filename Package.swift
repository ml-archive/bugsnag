// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "bugsnag",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Bugsnag", targets: ["Bugsnag"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.10.0"),
        .package(url: "https://github.com/skelpo/JSON", from: "1.1.4"),
    ],
    targets: [
        .target(name: "Bugsnag", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "JSON", package: "JSON"),
        ]),
        .testTarget(name: "BugsnagTests", dependencies: [
            .target(name: "Bugsnag"),
            .product(name: "XCTVapor", package: "vapor"),
        ]),
    ]
)
