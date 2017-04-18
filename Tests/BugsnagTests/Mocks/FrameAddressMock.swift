import Vapor
import Bugsnag
import HTTP
import Stacked

internal class FrameAddressMock: FrameAddressType {
    static var lastStackSize: Int? = nil

    static func getStackTrace(maxStackSize: Int) -> [String] {
        self.lastStackSize = maxStackSize
        return []
    }
}
