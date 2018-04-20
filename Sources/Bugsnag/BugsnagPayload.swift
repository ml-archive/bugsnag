//
//  BugsnagPayload.swift
//  Bugsnag
//
//  Created by Jimmy McDermott on 1/16/18.
//

import Foundation
import Vapor

public final class BugsnagPayload: Content {
    let apiKey: String
    let notifier: Notifier
    let events: [Event]
    
    init(apiKey: String, notifier: Notifier, events: [Event]) {
        self.apiKey = apiKey
        self.notifier = notifier
        self.events = events
    }
    
    public final class Notifier: Content {
        let name: String
        let version: String
        let url: String
        
        init(name: String, version: String, url: String) {
            self.name = name
            self.version = version
            self.url = url
        }
    }
    
    public final class Event: Content {
        let payloadVersion: Int
        let exceptions: [Exception]
        let app: App
        let severity: String
        let user: User
        let metadata: Metadata
        
        init(payloadVersion: Int, exceptions: [Exception], app: App, severity: String, user: User, metadata: Metadata) {
            self.payloadVersion = payloadVersion
            self.exceptions = exceptions
            self.app = app
            self.severity = severity
            self.user = user
            self.metadata = metadata
        }
        
        public final class Exception: Content {
            let errorClass: String
            let message: String
            let stacktrace: [Stacktrace]
            
            init(errorClass: String, message: String, stacktrace: [Stacktrace]) {
                self.errorClass = errorClass
                self.message = message
                self.stacktrace = stacktrace
            }
        }
        
        public final class Stacktrace: Content {
            let file: String
            let lineNumber: Int
            let columnNumber: Int
            let method: String
            
            init(file: String, lineNumber: Int, columnNumber: Int, method: String) {
                self.file = file
                self.lineNumber = lineNumber
                self.columnNumber = columnNumber
                self.method = method
            }
        }
        
        public final class App: Content {
            let releaseStage: String
            let type: String
            
            init(releaseStage: String, type: String) {
                self.releaseStage = releaseStage
                self.type = type
            }
        }
        
        public final class User: Content {
            let id: String?
            let name: String?
            let email: String?
            
            init(id: String?, name: String?, email: String?) {
                self.id = id
                self.name = name
                self.email = email
            }
        }
        
        public final class Metadata: Content {
            let url: String
            
            init(url: String) {
                self.url = url
            }
        }
    }
}
