# Bugsnag 🐛
[![Swift Version](https://img.shields.io/badge/Swift-3-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-2-F6CBCA.svg)](http://vapor.codes)
[![Circle CI](https://circleci.com/gh/nodes-vapor/bugsnag/tree/master.svg?style=shield)](https://circleci.com/gh/nodes-vapor/bugsnag)
[![codebeat badge](https://codebeat.co/badges/e93cc2d5-7365-4916-bc92-3f6bb39b18f4)](https://codebeat.co/projects/github-com-nodes-vapor-bugsnag-master)
[![codecov](https://codecov.io/gh/nodes-vapor/bugsnag/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/bugsnag)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/bugsnag)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/bugsnag)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/bugsnag/master/LICENSE)


Reporting errors to [Bugsnag](https://www.bugsnag.com/).

## 📦 Installation

### Installing CStack

Bugsnag uses [Stacked](https://github.com/nodes-vapor/stacked) (which depends on [CStack](https://github.com/nodes-vapor/cstack)) in order to provide unified stack traces across macOS and Linux. For this to work, there's some installation to be done on the machine running the project. See the Stacked repo for more information, but here's a short copy/pasta:

#### macOS and Homebrew

First add the tap:

```
brew tap nodes-vapor/homebrew-tap
```

And next, install the library by running:

```
brew install cstack
```

#### Linux and APT

We're working hard on making CStack available on Linux (through APT) and we'll make sure to update this readme as soon as it gets ready.

### Integrating Bugsnag in your project

Update your `Package.swift` file.

```swift
.Package(url: "https://github.com/nodes-vapor/bugsnag.git", majorVersion: 2)
```


## Getting started 🚀

Create a `bugsnag.json` configuration file with your Bugsnag credentials and configuration.

```json
{
    "apiKey": "my-bugsnag-key",
  	"endpoint": "https://notify.bugsnag.com",
    "notifyReleaseStages": [
        "staging",
        "production"
    ],
    "filters": [
        "password",
        "newPassword",
        "repeat_password"
    ],
    "stackTraceSize": 100
}
```

See the configuration section for an explanation of the different options.

### Automatic reporting

This package comes with a middleware that will automatically report any thrown errors to bugsnag. For best error data, please make sure that the errors being thrown conform to Vapor's `AbortError` type. 

To setup the middleware, then first make sure to import the package (in e.g. `Config+Setup.swift`):

```Swift
import Bugsnag
```

Next, add the middleware:

```swift
addConfigurable(middleware: Bugsnag.Middleware.init, name: "bugsnag")
```

Don't forget to add the middleware to your `droplet.json` config as well.

### Manual reporting

Sometimes it's convenient to report errors silently without letting the client know. For this, the Bugsnag package comes with functionality to manually report errors.

First, you'll have to make sure to import the package as desribed above (in Automatic reporting), then you need to add the Bugsnag provider:

```swift
try addProvider(Bugsnag.Provider.self)
```

You're now able to get a reference to a `Reporter` through the `Droplet`. You can then use this `Reporter` to manually report errors:

```swift
myDroplet.bugsnag?.report(error: Abort.badRequest, request: myRequest)
```

Consider injecting the reporter into the controllers that might need it instead of passing around the `Droplet`. There's also an option to pass in a completion block if you want to get notified when the submission has completed.

### Metadata

Remember that when using Vapor's `AbortError` type, you can pass in some metadata on your error which will also be reported to Bugsnag. This is convenient if you want to include information that can help you debug a specific error.

```swift
Abort.init(.internalServerError, metadata: ["userId": 1337], reason: "User failed to login.")
```



## Configurations 🔧

| Key                    | Example value                    | Required | Description                              |
| ---------------------- | -------------------------------- | -------- | ---------------------------------------- |
| `apiKey`               | `23487897ADIUHASIUDH3247`        | Yes      | Bugsnag API key for reporting errors.    |
| `endpoint`             | ` https://notify.bugsnag.com`    | Yes      | The endpoint to hit when reporting errors. |
| ` notifyReleaseStages` | `["staging", "production"]`      | No       | The environments in which errors should be reported. Environments not in the list will not report errors. |
| ` filters`             | `["password", "repeatPassword"]` | No       | Keys to filter out from a requests url-, query-, form and JSON parameters. |
| ` stackTraceSize`      | `100`                            | No       | The default size of the stacktrace to report together with the error. This value can be overruled when reporting errors manually. |


## 🏆 Credits

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodesagency.com).
The package owner for this project is [Steffen](https://github.com/steffendsommer).


## 📄 License

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
