import PackageDescription

let package = Package(
    name: "Bugsnag",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/nodes-vapor/stacked.git", majorVersion: 0, minor: 0)
    ]
)
