/// Error severity. See `BugsnagError`.
public struct BugsnagSeverity {
    /// Information.
    public static let info = Self(value: "info")

    /// Warning.
    public static let warning = Self(value: "warning")

    /// Error.
    public static let error = Self(value: "error")

    let value: String
}
