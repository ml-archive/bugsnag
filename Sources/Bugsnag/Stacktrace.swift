import Foundation

struct Stacktrace {
    struct Entry {
        let name: String
        let function: String
    }

    static var current: [Entry] {
        Thread.callStackSymbols.map { line in
            let name: String
            let mangledFunction: String
            #if os(Linux)
            entry = .init()
            #else
            let parts = line.split(
                separator: " ",
                maxSplits: 4,
                omittingEmptySubsequences: true
            )
            name = String(parts[1])
            let functionParts = parts[3].split(separator: "+")
            mangledFunction = functionParts[0].trimmingCharacters(in: .whitespaces)
            #endif
            let function: String
            if mangledFunction.hasPrefix("$s") || mangledFunction.hasPrefix("$S") {
                function = _stdlib_demangleName(mangledFunction)
            } else {
                function = mangledFunction
            }
            return .init(name: name, function: function)
        }
    }
}

@_silgen_name("swift_demangle")
public
func _stdlib_demangleImpl(
    mangledName: UnsafePointer<CChar>?,
    mangledNameLength: UInt,
    outputBuffer: UnsafeMutablePointer<CChar>?,
    outputBufferSize: UnsafeMutablePointer<UInt>?,
    flags: UInt32
) -> UnsafeMutablePointer<CChar>?

private func _stdlib_demangleName(_ mangledName: String) -> String {
    return mangledName.utf8CString.withUnsafeBufferPointer {
        (mangledNameUTF8CStr) in

        let demangledNamePtr = _stdlib_demangleImpl(
            mangledName: mangledNameUTF8CStr.baseAddress,
            mangledNameLength: UInt(mangledNameUTF8CStr.count - 1),
            outputBuffer: nil,
            outputBufferSize: nil,
            flags: 0)

        if let demangledNamePtr = demangledNamePtr {
            let demangledName = String(cString: demangledNamePtr)
            free(demangledNamePtr)
            return demangledName
        }
        return mangledName
    }
}
