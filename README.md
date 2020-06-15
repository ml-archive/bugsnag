# Bugsnag 🐛
[![Swift Version](https://img.shields.io/badge/Swift-5.2-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-4-e040fb.svg)](https://vapor.codes)
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
.package(url: "https://github.com/nodes-vapor/bugsnag.git", from: "4.0.0")
```

Update `configure.swift`

```swift
public func configure(_ app: Application) throws {
    // Configure Bugsnag.
    app.bugsnag.configuration = .init(
        apiKey: "<YOUR BUGSNAG API KEY>",
        releaseStage: environment.name,
        shouldReport: environment.name != "local"
    )

    // Add Bugsnag middleware.
    app.middleware.use(BugsnagMiddleware())
}
```

### Reporting

`BugsnagMiddleware` will automatically report errors thrown by your route handlers. You can report errors manually from `Application` or `Request`.

```swift
// Reporting from Application.
app.bugsnag.report(Abort(.internalServerError))

// Reporting from Request.
app.get("test") { req in
    req.bugsnag.report(Abort(.upgradeRequired))
    return HTTPStatus.ok
}
```

By conforming to the `BugsnagError` protocol you can have full control over how your errors are reported. It has the following properties:

| Name | Type | Function | Default |
|---|---|---|---|
| `shouldReport` | `Bool` | Opt out of error reporting by returning `false` | `true` |
| `severity` | `Severity` | Indicate error severity (`.info`\|`.warning`\|`.error`) | `.error` |
| `metadata` | `[String: CustomDebugStringConvertible]` | Additional metadata to include in the report | `[:]` |

### Users
Conforming your `Authenticatable` model to `BugsnagUser` allows you to easily pair the data to a report.

```swift
extension TestUser: BugsnagUser {
    var bugsnagID: CustomStringConvertible? { 
        self.id
    }
}
```

Configure all user models you would like Bugsnag to report.

```swift
// Add to configure.swift.
app.bugsnag.users.add(TestUser.self)
```

Bugsnag will automatically check Vapor's authentication API for the configured user types and report the user's identifier if they are logged in.

### Breadcrumbs
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
    case error
    case log
    case manual
    case navigation
    case process
    case request
    case state
    case user
}
```

### Blocked Keys

Usually you will receive information such as headers, query params or post body fields in the reports from Bugsnag. To ensure that you do not track sensitive information, you can configure Bugsnag with a list of fields that should be filtered out:

```swift
app.bugsnag.configuration = .init(
    apiKey: "foo",
    releaseStage: "debug",
    blockedKeys: ["email", "password"]
)
```
In this case Bugsnag Reports won't contain header fields, query params or post body json fields with the keys/names **email** and **password**.

⚠️ Note: If blocked keys are defined and Bugsnag does not know how to parse the request body, the entire body will be hidden.

## 🏆 Credits

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodesagency.com).

## 📄 License

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT).
