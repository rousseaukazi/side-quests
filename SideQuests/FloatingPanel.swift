import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {

    // MARK: - Constants

    private static let panelWidth: CGFloat = 720
    private static let panelHeight: CGFloat = 72
    private static let cornerRadius: CGFloat = 20
    private static let positionKey = "com.rousseau.sidequests.panelPosition"

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
            // NOTE: NO .fullSizeContentView — that flag causes NSHostingView to
            // miscalculate its layout region with .borderless panels, producing
            // a rectangular background artifact in the title-bar-height area.
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
        // Allow dragging from anywhere on the panel background
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        delegate = self
        setupContentView()
    }

    // MARK: - Content

    private func setupContentView() {
        let searchView = SearchBarView(
            onSubmit: { [weak self] text in
                self?.submit(text: text)
            }
        )

        // Wrap the SwiftUI view with a material background + hard clip shape.
        // Using SwiftUI's .background + .clipShape instead of a separate
        // NSVisualEffectView avoids the compositing layer mismatch that was
        // causing square corners to overdraw the rounded blur view.
        let rootView = searchView
            .background(PanelMaterial())
            .clipShape(RoundedRectangle(cornerRadius: FloatingPanel.cornerRadius, style: .continuous))

        let host = NSHostingView(rootView: rootView)
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        // Belt-and-suspenders: also clip at the CA level
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
        // Restore saved position if it's still on a live screen
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
        // Default: center on main screen, ~40% from top (Spotlight position)
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
            if event.keyCode == 53 { // Escape
                self?.hidePanel()
                return nil
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
    }
}

// MARK: - NSWindowDelegate (position persistence)

extension FloatingPanel: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        savePosition()
    }
}

// MARK: - Material background (NSViewRepresentable)
// Using a representable instead of a separate NSVisualEffectView wrapper
// keeps the blur layer inside the SwiftUI compositing tree where clipShape
// can mask it correctly.

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

// MARK: - Notification name

extension Notification.Name {
    static let sideQuestsPanelWillShow = Notification.Name("com.rousseau.sidequests.panelWillShow")
}
