import Vapor

extension Application {
    
    // MARK: - API
    struct BugsnagStorageKey: StorageKey {
        typealias Value = Bugsnag
    }
    
    public var bugsnag: Bugsnag {
        get {
            guard let val = self.storage[BugsnagStorageKey.self] else { fatalError() }
            return val
        }
        set {
            self.storage[BugsnagStorageKey.self] = newValue
        }
    }
}

extension Request {
    var bugsnag: Bugsnag { self.application.bugsnag }
}
