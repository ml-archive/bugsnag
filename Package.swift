import PackageDescription

let package = Package(
    name: "Bugsnag",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2)
    ]
)
