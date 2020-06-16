import Vapor

extension Application.Clients {
    private struct TestClientKey: StorageKey {
        typealias Value = TestClient
    }

    var test: TestClient {
        if let existing = self.application.storage[TestClientKey.self] {
            return existing
        } else {
            let new = TestClient()
            self.application.storage[TestClientKey.self] = new
            return new
        }
    }
}
extension Application.Clients.Provider {
    static var test: Self {
        .init { $0.clients.use { $0.clients.test } }
    }
}

final class TestClient: Client {
    var requests: [ClientRequest]

    var eventLoop: EventLoop {
        EmbeddedEventLoop()
    }

    init() {
        self.requests = []
    }

    func delegating(to eventLoop: EventLoop) -> Client {
        self
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        self.requests.append(request)
        return self.eventLoop.makeSucceededFuture(ClientResponse())
    }
}
