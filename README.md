# Bugsnag
[![Swift Version](https://img.shields.io/badge/Swift-3-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-1-F6CBCA.svg)](http://vapor.codes)
[![Circle CI](https://circleci.com/gh/nodes-vapor/bugsnag/tree/vapor-1.svg?style=shield)](https://circleci.com/gh/nodes-vapor/bugsnag)
[![codebeat badge](https://codebeat.co/badges/a63c1fe3-7ab8-400d-9e4a-02054ecd1b95)](https://codebeat.co/projects/github-com-nodes-vapor-bugsnag-vapor-1)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/bugsnag)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/bugsnag)
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
