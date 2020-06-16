import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeZone
import struct Foundation.Date
import class NIO.ThreadSpecificVariable

final class ISO8601Timestamp {
    private static var cache: ThreadSpecificVariable<ISO8601Timestamp> = .init()

    static var shared: ISO8601Timestamp {
        let formatter: ISO8601Timestamp
        if let existing = self.cache.currentValue {
            formatter = existing
        } else {
            let new = ISO8601Timestamp()
            self.cache.currentValue = new
            formatter = new
        }
        return formatter
    }

    let formatter: DateFormatter

    init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        self.formatter = formatter
    }

    func current() -> String {
        self.formatter.string(from: Date())
    }
}
