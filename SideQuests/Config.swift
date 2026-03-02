import Foundation

enum Config {

    // MARK: - Hardcoded defaults (Rousseau's setup — works out of the box)

    private static let defaultEndpoint = "http://3.145.73.180:4141/sq"
    private static let defaultSecret   = "roux-sq-secret"

    // MARK: - UserDefaults keys

    private static let endpointKey = "com.rousseau.sidequests.endpoint"
    private static let secretKey   = "com.rousseau.sidequests.secret"

    // MARK: - Accessors (UserDefaults → hardcoded fallback)

    static var endpoint: String {
        get {
            let saved = UserDefaults.standard.string(forKey: endpointKey) ?? ""
            return saved.isEmpty ? defaultEndpoint : saved
        }
        set {
            UserDefaults.standard.set(newValue.isEmpty ? defaultEndpoint : newValue,
                                      forKey: endpointKey)
        }
    }

    static var secret: String {
        get {
            let saved = UserDefaults.standard.string(forKey: secretKey) ?? ""
            return saved.isEmpty ? defaultSecret : saved
        }
        set {
            UserDefaults.standard.set(newValue.isEmpty ? defaultSecret : newValue,
                                      forKey: secretKey)
        }
    }

    /// True if the user has saved a custom config (useful for showing "configured" state in menu).
    static var isCustomized: Bool {
        let ep = UserDefaults.standard.string(forKey: endpointKey) ?? ""
        return !ep.isEmpty && ep != defaultEndpoint
    }

    /// Wipe saved config and revert to defaults.
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: endpointKey)
        UserDefaults.standard.removeObject(forKey: secretKey)
    }
}
