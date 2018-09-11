# Bugsnag 🐛
[![Swift Version](https://img.shields.io/badge/Swift-4-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-3-F6CBCA.svg)](http://vapor.codes)
[![Circle CI](https://circleci.com/gh/nodes-vapor/bugsnag/tree/master.svg?style=shield)](https://circleci.com/gh/nodes-vapor/bugsnag)
[![codebeat badge](https://codebeat.co/badges/e93cc2d5-7365-4916-bc92-3f6bb39b18f4)](https://codebeat.co/projects/github-com-nodes-vapor-bugsnag-master)
[![codecov](https://codecov.io/gh/nodes-vapor/bugsnag/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/bugsnag)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/bugsnag)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/bugsnag)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/bugsnag/master/LICENSE)

Reporting errors to [Bugsnag](https://www.bugsnag.com/).

## 📦 Installation

### Integrating Bugsnag in your project

Update your `Package.swift` file.

```swift
// .Package(url:"https://github.com/nodes-vapor/bugsnag.git", majorVersion: 3)
.package(url: "https://github.com/nodes-vapor/bugsnag.git", .branch("vapor-3"))
```

Update `Sources/App/configure.swift`

```swift
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    ...

    // Register provider
    let bugsnagConfig: BugsnagConfig = BugsnagConfig(
        apiKey: [YOUR BUGSNAG API KEY],
        releaseStage: environment.name,
        debug: false
    )
    services.register(BugsnagClient(bugsnagConfig))

    ...

    // Register middleware
    middlewares.use(BugsnagClient.self) // Catch errors and report to bugsnag

    ...
}
```

**Pitfall:** _Vapor's Error middleware overrides any `Error` it catches, meaning that if Bugsnag middleware is registered after the Error middleware, no errors exist for Bugsnag to report_

