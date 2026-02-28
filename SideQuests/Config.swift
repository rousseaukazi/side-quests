import Foundation

enum Config {
    /// URL of the sq-server endpoint that fires system events into Roux
    static let sqServerURL = "http://3.145.73.180:9000/sq"

    /// Shared secret — injected at build time via SQ_SERVER_SECRET build setting
    static let sqServerSecret: String = {
        if let plistValue = Bundle.main.infoDictionary?["SQ_SERVER_SECRET"] as? String,
           !plistValue.isEmpty,
           plistValue != "$(SQ_SERVER_SECRET)" {
            return plistValue
        }
        if let envValue = ProcessInfo.processInfo.environment["SQ_SERVER_SECRET"],
           !envValue.isEmpty {
            return envValue
        }
        return ""
    }()
}
