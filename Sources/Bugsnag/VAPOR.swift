import NIO
import Vapor

extension HTTPHeaders {
    /// Represents the information we have about the remote peer of this message.
    ///
    /// The peer (remote/client) address is important for availability (block bad clients by their IP) or even security.
    /// We can always get the remote IP of the connection from the `Channel`. However, when clients go through
    /// a proxy or a load balancer, we'd like to get the original client's IP. Most proxy servers and load
    /// balancers communicate the information about the original client in certain headers.
    ///
    /// See https://en.wikipedia.org/wiki/X-Forwarded-For
    public var forwarded: Forwarded? {
        get {
            if let value = self.firstValue(name: .forwarded) {
                return .parse(value)
            } else {
                var forwarded = Forwarded()
                forwarded.by = self.firstValue(name: .init("Via"))
                forwarded.for = self.firstValue(name: .init("X-Forwarded-For"))
                forwarded.host = self.firstValue(name: .init("X-Forwarded-Host"))
                forwarded.proto = self.firstValue(name: .init("X-Forwarded-Proto"))
                // Only return value if we have at least one header.
                if forwarded.by != nil || forwarded.for != nil || forwarded.host != nil || forwarded.proto != nil {
                    return forwarded
                } else {
                    return nil
                }
            }
        }
        set {
            if let forwarded = newValue {
                var value = HTTPHeaderValue("")
                value.parameters["by"] = forwarded.by
                value.parameters["for"] = forwarded.for
                value.parameters["host"] = forwarded.host
                value.parameters["proto"] = forwarded.proto
                self.replaceOrAdd(name: .forwarded, value: value.serialize())
            } else {
                self.remove(name: .forwarded)
            }
        }
    }

    /// Parses the `Forwarded` header.
    public struct Forwarded {
        /// "by" section of the header.
        var by: String?

        /// "for" section of the header
        var `for`: String?

        /// "for" section of the header
        var host: String?

        /// "proto" section of the header.
        var proto: String?

        /// Creates a new `Forwaded` header object from the header value.
        static func parse(_ data: String) -> Forwarded? {
            guard let value = HTTPHeaderValue.parse(data) else {
                return nil
            }

            return .init(
                by: value.parameters["by"],
                for: value.parameters["for"],
                host: value.parameters["host"],
                proto: value.parameters["proto"]
            )
        }
    }

}

extension SocketAddress {
    /// Returns the hostname for this `SocketAddress` if one exists.
    public var hostname: String? {
        switch self {
        case .unixDomainSocket: return nil
        case .v4(let v4): return v4.host
        case .v6(let v6): return v6.host
        }
    }
}
