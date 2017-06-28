import Vapor

extension Abort {
    public func report() -> Abort {
        return addReportMetadata(true)
    }
    
    public func doNotReport() -> Abort {
        return addReportMetadata(false)
    }
    
    func addReportMetadata(_ shouldReport: Bool) -> Abort {
        var metadata = self.metadata ?? Node.object([:])
        metadata["report"] = true
        
        let result = Abort.init(
            status,
            metadata: metadata,
            reason: reason,
            identifier: identifier,
            possibleCauses: possibleCauses,
            suggestedFixes: suggestedFixes,
            documentationLinks: documentationLinks,
            stackOverflowQuestions: stackOverflowQuestions,
            gitHubIssues: gitHubIssues
        )
        
        return result
    }
}
