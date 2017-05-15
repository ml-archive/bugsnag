import PackageDescription

let package = Package(
    name: "Bugsnag",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/nodes-vapor/stacked.git", majorVersion: 0, minor: 1)
    ]
)
