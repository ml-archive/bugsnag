# Bugsnag
[![Language](https://img.shields.io/badge/Swift-3-brightgreen.svg)](http://swift.org)
[![Build Status](https://travis-ci.org/nodes-vapor/bugsnag.svg?branch=master)](https://travis-ci.org/nodes-vapor/bugsnag)
[![codecov](https://codecov.io/gh/nodes-vapor/bugsnag/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/bugsnag)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/bugsnag/master/LICENSE)


This package is to report errors 

#Installation

Update your `Package.swift` file.
```swift
.Package(url: "https://github.com/nodes-vapor/bugsnag", majorVersion: 0)
```

#### Config
Create config meta.json

```
{
    "apiKey": "secret",
    "notifyReleaseStages": [
        "staging",
        "production"
    ],
    "endpoint": "https://notify.bugsnag.com",
    "filters" : [
        "password"
    ]
}

```

### main.swift
```
import Bugsnag
```

And add middleware
```
try drop.middleware.append(BugsnagMiddleware(drop: drop))
```
