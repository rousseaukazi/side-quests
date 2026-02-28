import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // Default: ⌘⇧Space
    static let togglePanel = Self(
        "togglePanel",
        default: .init(.s, modifiers: [.command, .shift])
    )
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private(set) var panel: FloatingPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure no Dock icon (belt-and-suspenders alongside LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPanel()
        setupHotkey()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }

        button.image = NSImage(
            systemSymbolName: "bolt.fill",
            accessibilityDescription: "Side Quests"
        )
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
        menu.addItem(
            withTitle: "Quit Side Quests",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        // Attach temporarily so the button can present it
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
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
