# Bugsnag
[![Language](https://img.shields.io/badge/Swift-3-brightgreen.svg)](http://swift.org)
[![Build Status](https://travis-ci.org/nodes-vapor/bugsnag.svg?branch=master)](https://travis-ci.org/nodes-vapor/bugsnag)
[![codecov](https://codecov.io/gh/nodes-vapor/bugsnag/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/bugsnag)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/bugsnag/master/LICENSE)


Reporting errors to [Bugsnag](https://www.bugsnag.com/).

## Integration

Update your `Package.swift` file.

```swift
.Package(url: "https://github.com/nodes-vapor/bugsnag.git", majorVersion: 0)
```

## Getting started 🚀

Create a `bugsnag.json` configuration file with your Bugsnag credentials and configuration.

```json
{
    "apiKey": "#BUGSNAG_KEY#",
    "notifyReleaseStages": [
        "staging",
        "production"
    ],
    "endpoint": "https://notify.bugsnag.com",
    "filters": [
        "password",
        "newPassword",
        "repeat_password"
    ]
}
```

### Automatic reporting

This package comes with a middleware that will automatically report any thrown errors to bugsnag. For best error data, please make sure that the errso being thrown conform to Vapor's `AbortError` type. 

To setup the middleware, then first make sure to import the package, in e.g. `main.swift`.

```Swift
import Bugsnag
```

Next, add the middleware:
```swift
try drop.middleware.append(Bugsnag.Middleware(drop: drop))
```

### Manual reporting

Sometimes it's convenient to report errors silently without letting the client know. For this, the Bugsnag package comes with functionality to manually report errors.

First, you'll have to make sure to import the package as desribed above (in Automatic reporting), then you need to add the Bugsnag provider:

```swift
try drop.addProvider(Bugsnag.Provider.self)
```

Then whenever you want to report to Bugsnag, you can access the Bugsnag reporter through your `Droplet`:

```swift
myDroplet.bugsnag?.report(error: Abort.badRequest, request: myRequest)
```

There's also an option to pass in a completion block if you wan't to get notified when the submission has completed.

## 🏆 Credits
This package is developed and maintained by the Vapor team at [Nodes](https://www.nodes.dk).

## 📄 License
This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
