import Vapor

public final class BugsnagClient: Service, Middleware {
    public let apiKey: String
    public let hostName: String
    public let payloadVersion: UInt8
    public let releaseStage: String
    let debug: Bool
    
    public init(_ config: BugsnagConfig) {
        self.apiKey = config.apiKey
        self.hostName = config.hostName
        self.payloadVersion = config.payloadVersion
        self.releaseStage = config.releaseStage
        self.debug = config.debug
    }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        var response: Future<Response>
        
        do {
            response =  try next.respond(to: request)
        } catch let error {
            self.report(on: request, with: error)
            throw error
        }
        
        // TODO: Find a better way that doesn't care about responding
        return response.thenIfError { error in
            self.report(on: request, with: error)
            return response
        }
    }
    
    private func report(
        on request: Request,
        with error: Error
    ) {
        do {
            let body = try RequestBuilder(
                request: request.http,
                error: error,
                releaseStage: self.releaseStage
            ).build()
            
            _ = HTTPClient.connect(hostname: "notify.bugsnag.com", on: request)
                .flatMap(to: HTTPResponse.self) { client in
                    let headers = HTTPHeaders.init([
                        ("Content-Type", "application/json"),
                        ("Bugsnag-Api-Key", self.apiKey),
                        ("Bugsnag-Payload-Version", self.payloadVersion.string)
                    ])
                    
                    let req = HTTPRequest(method: .POST, url: "/", headers: headers, body: body)
                    return client.send(req)
                }
                .map(to: Void.self) { response in
                    if self.debug {
                        print("Bugsnag response:")
                        print(response.status.code, response.status.reasonPhrase)
                    }
                }
        } catch {
            // fail silently
        }
    }
    
    public static func report(error: Error, meta: [String]?) throws {
        
    }
}
