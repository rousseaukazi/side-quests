import Foundation

enum Config {

    static let placeholderURL = "YOUR_WEBHOOK_URL_HERE"

    /// Discord webhook URL.
    ///
    /// Resolution order:
    ///  1. Info.plist key `DISCORD_WEBHOOK_URL`  — injected at build time via
    ///     the `DISCORD_WEBHOOK_URL` Xcode build setting (set via env var in CI).
    ///  2. Process environment variable `DISCORD_WEBHOOK_URL` — handy for local
    ///     `swift run` / debug sessions.
    ///  3. The placeholder string (app logs a warning instead of crashing).
    static let webhookURL: String = {
        // 1. Build-time injection via Info.plist
        if let plistValue = Bundle.main.infoDictionary?["DISCORD_WEBHOOK_URL"] as? String,
           !plistValue.isEmpty,
           plistValue != "$(DISCORD_WEBHOOK_URL)" {
            return plistValue
        }

        // 2. Runtime environment variable (local dev / testing)
        if let envValue = ProcessInfo.processInfo.environment["DISCORD_WEBHOOK_URL"],
           !envValue.isEmpty {
            return envValue
        }

        // 3. Placeholder — will log a warning when first used
        return placeholderURL
    }()
}
