
import Vapor

public final class RequestBuilder {
    
    private let request: HTTPRequest
    private let error: Error
    
    public init(request: HTTPRequest, error: Error)
    {
        self.request = request
        self.error = error
    }
    
    public func build() throws -> LosslessHTTPBodyRepresentable {
        let body = self.payload()
        return try JSONEncoder().encode(body)
    }
    
    private func payload() -> BugsnagPayload {
        return BugsnagPayload(
            apiKey: "d70977c90ea82f8fa72c0d655bda637e",
            notifier: self.notifier(),
            events: [self.events()]
        )
    }
    
    private func notifier() -> BugsnagNotifier {
        return BugsnagNotifier(
            name: "nodes-vapor/bugsnag",
            version: "3",
            url: "https://github.com/nodes-vapor/bugsnag.git"
        )
    }
    
    private func events() -> BugsnagEvent {
        return BugsnagEvent(
            payloadVersion: "4",
            exceptions: [self.bugsnagException()],
//            breadcrumbs: <#T##[BugsnagBreadcrumb]#>,
            request: self.bugsnagRequest()
//            threads: <#T##[BugsnagThread]#>,
//            context: <#T##String#>,
//            groupingHash: <#T##String#>,
//            unhandled: <#T##Bool#>,
//            severity: <#T##String#>,
//            severityReason: <#T##BugsnagSeverityReason#>,
//            user: <#T##BugsnagUser#>,
//            app: <#T##BugsnagApp#>,
//            device: <#T##BugsnagDevice#>,
//            session: <#T##BugsnagSession#>,
//            metaData: <#T##BugsnagMetaData#>
        )
    }
    
    private func bugsnagRequest() -> BugsnagRequest {
        return BugsnagRequest(
            clientIp: String(describing: self.request.remotePeer.hostname),
            headers: self.parseHeaders(headers: self.request.headers),
            httpMethod: "\(self.request.method)",
            url: self.request.urlString,
            referer: self.request.remotePeer.description
        )
    }
    
    private func bugsnagException() -> BugsnagException {
        let reason: String
        let status: HTTPResponseStatus
        
        if let abort = self.error as? AbortError {
            reason = abort.reason
            status = abort.status
        } else {
            status = .internalServerError
            reason = "Something went wrong."
        }
        
        return BugsnagException(
            errorClass: self.error.localizedDescription,
            message: reason,
            // let stacktrace: [BugsnagStacktrace]
            type: status.reasonPhrase
        )
    }
 
    fileprivate func parseHeaders(headers: HTTPHeaders) -> [String:String] {
        var extractedHeaders: [String:String] = [:]
        
        headers.forEach { header in
            extractedHeaders[header.name] = header.value
        }
        
        return extractedHeaders
    }
}
