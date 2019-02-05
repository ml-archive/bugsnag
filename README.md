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
.package(url: "https://github.com/nodes-vapor/bugsnag.git", .upToNextMinor(from: "3.0.0"))
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
    let reporter = BugsnagReporter(
        apiKey: "<YOUR BUGSNAG API KEY>",
        releaseStage: environment.name,
        shouldReport: environment.name != "local"
        debug: false
    )
    services.register(reporter)

    ...

    // Register middleware
    middlewares.use(reporter) // Catch errors and report to bugsnag

    ...
}
```

### Reporting
Bugsnag offers three different types of reports: info, warning and error. To make a report just instantiate a `BugsnagReporter` and use the respective functions.

##### Examples
```swift
let reporter = try req.make(BugsnagReporter.self)

reporter.info(Abort(.upgradeRequired), on: req)
reporter.warning(Abort(.notFound), on: req)
reporter.error(Abort(.internalServerError), on: req)
```

It's also possible to attach metadata to the report.
```swift
reporter.error(
    Abort(.internalServerError),
    metadata: ["key": "value"],
    on: req
)
```

Reporting an error returns a discardable future. Just map the result if you would like to do more work after the report has been sent.

```swift
return reporter.error(yourError, on: req).flatMap {
    ...
}
```

#### Users
Conforming your `Authenticatable` model to `BugsnagReportableUser` allows you to lazily pair the data to a report. The protocol requires your model to have an `id` field.

```swift
extension YourUser: BugsnagReportableUser {}

try reporter.error(userType: YourUser.self, Abort(.notFound), on: req)
```

#### Breadcrumbs
Breadcrumbs enable you to attach custom events to your reports. Leave a breadcrumb using the convenience function on `Request`.

```swift
req.breadcrumb(
    name: "Something happened!",
    type: .manual,
    metadata: ["foo": "bar"]
)
```

The breadcrumb types are provided by Bugsnag:
```swift
enum BreadcrumbType {
    case navigation
    case request
    case process
    case log
    case user
    case state
    case error
    case manual
}
