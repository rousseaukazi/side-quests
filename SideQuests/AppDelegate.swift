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

        // Configure endpoint (for sharing with others)
        let configTitle = Config.isCustomized ? "Configure… (custom)" : "Configure…"
        menu.addItem(
            withTitle: configTitle,
            action: #selector(showConfigureDialog),
            keyEquivalent: ""
        )

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

    @objc private func showConfigureDialog() {
        let alert = NSAlert()
        alert.messageText = "Configure Side Quests"
        alert.informativeText = "Set the sq-server endpoint and secret.\nLeave blank to use the built-in defaults."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Reset to Default")
        alert.addButton(withTitle: "Cancel")

        // Stack two labeled text fields as the accessory view
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 76))

        let endpointLabel = NSTextField(labelWithString: "Endpoint URL")
        endpointLabel.frame = NSRect(x: 0, y: 52, width: 120, height: 17)
        endpointLabel.font = .systemFont(ofSize: 12)

        let endpointField = NSTextField(frame: NSRect(x: 0, y: 30, width: 380, height: 22))
        endpointField.placeholderString = "http://your-server/sq"
        endpointField.stringValue = UserDefaults.standard.string(forKey: "com.rousseau.sidequests.endpoint") ?? ""

        let secretLabel = NSTextField(labelWithString: "Secret")
        secretLabel.frame = NSRect(x: 0, y: 8, width: 120, height: 17)
        secretLabel.font = .systemFont(ofSize: 12)

        let secretField = NSSecureTextField(frame: NSRect(x: 0, y: -14, width: 380, height: 22))
        secretField.placeholderString = "your-secret"
        secretField.stringValue = UserDefaults.standard.string(forKey: "com.rousseau.sidequests.secret") ?? ""

        container.addSubview(endpointLabel)
        container.addSubview(endpointField)
        container.addSubview(secretLabel)
        container.addSubview(secretField)

        alert.accessoryView = container
        NSApp.activate(ignoringOtherApps: true)

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:  // Save
            Config.endpoint = endpointField.stringValue
            Config.secret   = secretField.stringValue
        case .alertSecondButtonReturn: // Reset to Default
            Config.resetToDefaults()
        default:
            break
        }
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
