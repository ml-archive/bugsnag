import Vapor

extension Droplet {
    public var bugsnag: Reporter? {
        get { return storage["bugsnag"] as? Reporter }
        set { storage["bugsnag"] = newValue }
    }
}
