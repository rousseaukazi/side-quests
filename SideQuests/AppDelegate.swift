import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePanel = Self(
        "togglePanel",
        default: .init(.s, modifiers: [.command, .shift])
    )
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private(set) var panel: FloatingPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ThemeManager.shared.applyOnLaunch()
        setupStatusItem()
        setupPanel()
        setupHotkey()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }

        // Use custom asset catalog icon; fall back to SF Symbol if asset not found
        if let customImage = NSImage(named: "MenuBarIcon") {
            customImage.isTemplate = true  // lets macOS adapt for dark/light menu bar
            button.image = customImage
        } else {
            button.image = NSImage(systemSymbolName: "map.fill",
                                   accessibilityDescription: "Side Quests")
        }
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.action = #selector(statusItemClicked(_:))
        button.target = self
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(
            withTitle: "Show Side Quests",
            action: #selector(showPanel),
            keyEquivalent: ""
        )

        menu.addItem(.separator())

        // Appearance submenu
        let appearanceItem = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        let appearanceMenu = NSMenu()
        for option in ThemeManager.Appearance.allCases {
            let item = NSMenuItem(
                title: option.label,
                action: #selector(setAppearance(_:)),
                keyEquivalent: ""
            )
            item.tag = ThemeManager.Appearance.allCases.firstIndex(of: option) ?? 0
            item.state = (ThemeManager.shared.current == option) ? .on : .off
            item.target = self
            appearanceMenu.addItem(item)
        }
        appearanceItem.submenu = appearanceMenu
        menu.addItem(appearanceItem)

        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit Side Quests",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func setAppearance(_ sender: NSMenuItem) {
        let options = ThemeManager.Appearance.allCases
        guard sender.tag < options.count else { return }
        ThemeManager.shared.set(options[sender.tag])
    }

    // MARK: - Panel

    private func setupPanel() {
        panel = FloatingPanel()
    }

    @objc func showPanel() {
        panel?.showPanel()
    }

    func togglePanel() {
        if panel?.isVisible == true {
            panel?.hidePanel()
        } else {
            panel?.showPanel()
        }
    }

    // MARK: - Global Hotkey

    private func setupHotkey() {
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            self?.togglePanel()
        }
    }
}
