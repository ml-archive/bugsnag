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
.package(url: "https://github.com/nodes-vapor/bugsnag.git", from: "3.0.0")
```

Update `Sources/App/configure.swift`

```swift
public func configure(
    _ config: inout Config,
    _ environment: inout Environment,
    _ services: inout Services
) throws {
    ...
    // Register provider
    let bugsnagProvider = BugsnagProvider(config: BugsnagConfig(
        apiKey: "<YOUR BUGSNAG API KEY>",
        releaseStage: environment.name,
        shouldReport: environment.name != "local"
        debug: false
    ))
    try services.register(bugsnagProvider)

    ...

    // Register middleware

    var middlewaresConfig = MiddlewareConfig()
    ...
    middlewaresConfig.use(BugsnagMiddleware.self) // Catch errors and report to bugsnag
    ...
    services.register(middlewaresConfig)

    ...
}
```

### Reporting
Bugsnag offers three different types of reports: info, warning and error. To make a report just instantiate an `ErrorReporter` and use the respective functions.

##### Examples
```swift
let reporter = try req.make(ErrorReporter.self) // or `BugsnagReporter.self`

reporter.report(Abort(.upgradeRequired), severity: .info, on: req)
reporter.report(Abort(.notFound), severity: .warning, on: req)
reporter.report(Abort(.internalServerError), severity: .error, on: req) // you can omit the `severity` parameter since `.error` is the default
```

It's also possible to attach metadata to the report.
```swift
reporter.report(
    Abort(.internalServerError),
    metadata: ["key": "value"],
    on: req
)
```

By conforming to the `ReportableError` protocol you can have full control over how (and if) the BugsnagMiddleware reports your errors. It has the following properties:

| Name | Type | Function | Default |
|---|---|---|---|
| `shouldReport` | `Bool` | Opt out of error reporting by returning `false` | `true` |
| `severity` | `Severity` | Indicate error severity (`.info`\|`.warning`\|`.error`) | `.error` |
| `userId` | `CustomStringConvertible?` | An optional user id associated with the error | `nil` |
| `metadata` | `[String: CustomDebugStringConvertible]` | Additional metadata to include in the report | `[:]` |

#### Users
Conforming your `Authenticatable` model to `BugsnagReportableUser` allows you to easily pair the data to a report. The protocol requires your model to have an `id` field that is `CustomStringConvertible`.

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
```

#### Filter out fields from reports
Usually you will receive information such as headers, query params or post body fields in the reports from Bugsnag. To ensure that you do not track sensitive information, you can configure Bugsnag with a list of fields that should be filtered out:

```swift
BugsnagConfig(
    apiKey: "apiKey",
    releaseStage: "test",
    keyFilters: ["password", "email", "authorization", "lastname"]
)
```
In this case Bugsnag Reports won't contain header fields, query params or post body json fields with the keys/names **password**, **email**, **authorization**, **lastname**.

⚠️ Note: in JSON bodies, this only works for the first level of fields and not for nested children.

## 🏆 Credits

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodesagency.com).

## 📄 License

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT).
