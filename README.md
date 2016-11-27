This package is to report errors 

#Installation

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
