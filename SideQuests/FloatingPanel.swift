import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {

    // MARK: - Constants

    private static let panelWidth: CGFloat = 720
    private static let panelHeight: CGFloat = 72
    private static let cornerRadius: CGFloat = 20
    private static let positionKey = "com.rousseau.sidequests.panelPosition"

    // MARK: - State

    /// Kept in sync via SearchBarView.onTextChange so event monitor can read it.
    private var currentText: String = ""

    /// Double-tap T detection
    private var lastTKeyTime: Date?
    private var lastTWhenEmpty: Bool = false

    // MARK: - Event monitors

    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    // MARK: - Init

    init() {
        super.init(
            contentRect: NSRect(
                x: 0, y: 0,
                width: FloatingPanel.panelWidth,
                height: FloatingPanel.panelHeight
            ),
            // No .fullSizeContentView — causes NSHostingView layout offset with .borderless,
            // producing a rectangular background artifact at the top of the panel.
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        delegate = self
        setupContentView()
    }

    // MARK: - Content

    private func setupContentView() {
        var searchView = SearchBarView(
            onSubmit: { [weak self] text in
                self?.submit(text: text)
            }
        )
        searchView.onTextChange = { [weak self] newText in
            self?.currentText = newText
        }

        let rootView = searchView
            .background(PanelMaterial())
            .clipShape(RoundedRectangle(cornerRadius: FloatingPanel.cornerRadius, style: .continuous))

        let host = NSHostingView(rootView: rootView)
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        host.layer?.cornerRadius = FloatingPanel.cornerRadius
        host.layer?.cornerCurve = .continuous
        host.layer?.masksToBounds = true

        contentView = host
    }

    // MARK: - NSPanel overrides

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // MARK: - Show / Hide

    func showPanel() {
        positionPanel()
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .sideQuestsPanelWillShow, object: nil)
        installEventMonitors()
    }

    func hidePanel() {
        removeEventMonitors()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
            var frame = self.frame
            frame.origin.y += 8
            self.animator().setFrame(frame, display: true)
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
            self?.alphaValue = 1.0
        })
    }

    // MARK: - Positioning

    private func positionPanel() {
        if let saved = savedOrigin() {
            let testRect = NSRect(
                origin: saved,
                size: NSSize(width: FloatingPanel.panelWidth, height: FloatingPanel.panelHeight)
            )
            if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(testRect) }) {
                setFrame(NSRect(origin: saved,
                                size: NSSize(width: FloatingPanel.panelWidth,
                                             height: FloatingPanel.panelHeight)),
                         display: true)
                return
            }
        }
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let sr = screen.visibleFrame
        let x = sr.midX - FloatingPanel.panelWidth / 2
        let y = sr.maxY - (sr.height * 0.42)
        setFrame(
            NSRect(x: x, y: y,
                   width: FloatingPanel.panelWidth,
                   height: FloatingPanel.panelHeight),
            display: true
        )
    }

    // MARK: - Position persistence

    private func savedOrigin() -> NSPoint? {
        guard let dict = UserDefaults.standard.dictionary(forKey: Self.positionKey),
              let x = dict["x"] as? Double,
              let y = dict["y"] as? Double else { return nil }
        return NSPoint(x: x, y: y)
    }

    private func savePosition() {
        let o = frame.origin
        UserDefaults.standard.set(["x": Double(o.x), "y": Double(o.y)],
                                   forKey: Self.positionKey)
    }

    // MARK: - Submission

    private func submit(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        hidePanel()
        Task {
            await DiscordService.shared.post(message: trimmed)
        }
    }

    // MARK: - Event monitors

    private func installEventMonitors() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Escape → dismiss
            if event.keyCode == 53 {
                self.hidePanel()
                return nil
            }

            // Double-tap T (keyCode 17) while field was empty → toggle theme
            if event.keyCode == 17 {
                let now = Date()
                if self.lastTWhenEmpty,
                   let last = self.lastTKeyTime,
                   now.timeIntervalSince(last) < 0.35 {
                    // Second T within window — toggle and consume
                    ThemeManager.shared.toggle()
                    self.lastTKeyTime = nil
                    self.lastTWhenEmpty = false
                    // Clear the 't' that the first press already typed
                    NotificationCenter.default.post(name: .sideQuestsClearText, object: nil)
                    return nil
                }
                self.lastTKeyTime = now
                self.lastTWhenEmpty = self.currentText.isEmpty
            } else {
                // Any non-T key resets the double-tap window
                self.lastTKeyTime = nil
                self.lastTWhenEmpty = false
            }

            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.hidePanel()
        }
    }

    private func removeEventMonitors() {
        if let m = localEventMonitor { NSEvent.removeMonitor(m); localEventMonitor = nil }
        if let m = globalEventMonitor { NSEvent.removeMonitor(m); globalEventMonitor = nil }
        lastTKeyTime = nil
        lastTWhenEmpty = false
    }
}

// MARK: - NSWindowDelegate

extension FloatingPanel: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        savePosition()
    }
}

// MARK: - Material background

private struct PanelMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.blendingMode = .behindWindow
        v.state = .active
        v.material = .underWindowBackground
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Notification names

extension Notification.Name {
    static let sideQuestsPanelWillShow = Notification.Name("com.rousseau.sidequests.panelWillShow")
    static let sideQuestsClearText    = Notification.Name("com.rousseau.sidequests.clearText")
}
