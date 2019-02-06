public struct Severity {
    let value: String

    public static let info = Severity(value: "info")
    public static let warning = Severity(value: "warning")
    public static let error = Severity(value: "error")
}
