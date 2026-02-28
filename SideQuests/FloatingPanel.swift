import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {

    // MARK: - Constants

    private static let panelWidth: CGFloat = 720
    private static let panelHeight: CGFloat = 72
    private static let cornerRadius: CGFloat = 20

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
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
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
        isMovableByWindowBackground = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        setupContentView()
    }

    // MARK: - Content

    private func setupContentView() {
        // Blur background
        let blur = NSVisualEffectView()
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.material = .underWindowBackground
        blur.wantsLayer = true

        // SwiftUI search bar hosted inside the blur view
        let searchView = SearchBarView(
            onSubmit: { [weak self] text in
                self?.submit(text: text)
            }
        )

        let host = NSHostingView(rootView: searchView.background(Color.clear))
        host.translatesAutoresizingMaskIntoConstraints = false
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        // Clip host to same rounded shape so it can't overdraw the blur view's corners
        host.layer?.cornerRadius = FloatingPanel.cornerRadius
        host.layer?.masksToBounds = true

        blur.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            host.topAnchor.constraint(equalTo: blur.topAnchor),
            host.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
        ])

        contentView = blur

        // Use a CAShapeLayer mask on the blur view — more reliable than
        // cornerRadius+masksToBounds against NSHostingView overdraw on macOS 13+
        let mask = CAShapeLayer()
        let rect = CGRect(x: 0, y: 0,
                          width: FloatingPanel.panelWidth,
                          height: FloatingPanel.panelHeight)
        mask.path = CGPath(roundedRect: rect,
                           cornerWidth: FloatingPanel.cornerRadius,
                           cornerHeight: FloatingPanel.cornerRadius,
                           transform: nil)
        blur.layer?.mask = mask
    }

    // MARK: - NSPanel overrides

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // MARK: - Show / Hide

    func showPanel() {
        centerOnActiveScreen()
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Tell the SwiftUI view to clear its text and claim focus
        NotificationCenter.default.post(name: .sideQuestsPanelWillShow, object: nil)

        installEventMonitors()
    }

    func hidePanel() {
        removeEventMonitors()
        // Slide up 8px + fade out, then dismiss
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
        // With LSUIElement / .accessory policy, macOS automatically
        // returns focus to the previously active application.
    }

    // MARK: - Positioning

    private func centerOnActiveScreen() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let sr = screen.visibleFrame
        let x = sr.midX - FloatingPanel.panelWidth / 2
        // Place panel ~40% from the top (Spotlight-ish position)
        let y = sr.maxY - (sr.height * 0.42)
        setFrame(
            NSRect(x: x, y: y, width: FloatingPanel.panelWidth, height: FloatingPanel.panelHeight),
            display: true
        )
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
        // Local: intercept Escape before the text field sees it
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hidePanel()
                return nil          // consume event
            }
            return event
        }

        // Global: clicking anywhere outside the panel dismisses it
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

// MARK: - Notification name

extension Notification.Name {
    static let sideQuestsPanelWillShow = Notification.Name("com.rousseau.sidequests.panelWillShow")
}
