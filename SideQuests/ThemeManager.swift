import AppKit

/// Manages the app's appearance preference (light / dark / system).
final class ThemeManager {
    static let shared = ThemeManager()

    private static let defaultsKey = "com.rousseau.sidequests.appearance"

    enum Appearance: String, CaseIterable {
        case system, light, dark

        var label: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
    }

    private(set) var current: Appearance {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: Self.defaultsKey)
            apply()
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.defaultsKey)
        current = Appearance(rawValue: stored ?? "") ?? .system
    }

    func set(_ appearance: Appearance) {
        current = appearance
    }

    /// Cycles Light ↔ Dark (leaves System once a manual choice is made).
    func toggle() {
        switch current {
        case .light:
            current = .dark
        case .dark:
            current = .light
        case .system:
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            current = isDark ? .light : .dark
        }
    }

    func applyOnLaunch() {
        apply()
    }

    private func apply() {
        switch current {
        case .light:  NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:   NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system: NSApp.appearance = nil
        }
    }
}
