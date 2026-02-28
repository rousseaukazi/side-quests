import SwiftUI
import AppKit

private struct Particle: Identifiable {
    let id = UUID()
    let angle: Double    // degrees
    let distance: CGFloat
}

struct SearchBarView: View {

    let onSubmit: (String) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @State private var isHoveringSubmit = false
    @State private var isSubmitting = false
    @State private var particles: [Particle] = []
    @State private var particlesActive = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "map.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor((text.isEmpty && !isSubmitting) ? .secondary : .accentColor)
                .padding(.leading, 18)
                .animation(.easeInOut(duration: 0.15), value: text.isEmpty)

            TextField("Start a side quest…", text: $text)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .textFieldStyle(.plain)
                .foregroundColor(.primary)
                .focused($isFocused)
                .onSubmit(handleSubmit)

            // Keep visible while submitting so particles have somewhere to live
            if !text.isEmpty || isSubmitting {
                ZStack {
                    // Particle burst — 8 dots scatter outward then fade
                    ForEach(particles) { p in
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                            .offset(
                                x: particlesActive ? CGFloat(cos(p.angle * .pi / 180)) * p.distance : 0,
                                y: particlesActive ? CGFloat(sin(p.angle * .pi / 180)) * p.distance : 0
                            )
                            .opacity(particlesActive ? 0 : 0.9)
                            .animation(.easeOut(duration: 0.4), value: particlesActive)
                    }

                    // Arrow — fades out as particles burst
                    Button(action: handleSubmit) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.accentColor)
                            .scaleEffect(isSubmitting ? 1.25 : (isHoveringSubmit ? 1.12 : 1.0))
                            .opacity(isSubmitting ? 0 : 1)
                            .animation(.easeOut(duration: 0.12), value: isSubmitting)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHoveringSubmit = hovering
                        }
                    }
                }
                .padding(.trailing, 12)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(height: 72)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty && !isSubmitting)
        .onReceive(
            NotificationCenter.default.publisher(for: .sideQuestsPanelWillShow)
        ) { _ in
            text = ""
            particles = []
            particlesActive = false
            isSubmitting = false
            isHoveringSubmit = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }

    private func handleSubmit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmitting else { return }

        isSubmitting = true

        // Sound fires immediately
        NSSound(named: "Pop")?.play()

        // Spawn 8 particles evenly distributed + slight random radius variation
        particles = (0..<8).map { i in
            Particle(
                angle: Double(i) * 45.0 + Double.random(in: -8...8),
                distance: CGFloat.random(in: 18...30)
            )
        }

        // Tiny delay so particles mount, then trigger animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            withAnimation { particlesActive = true }
        }

        // Clear text immediately (arrow stays visible via isSubmitting)
        let captured = trimmed
        text = ""

        // Let animation finish (0.4s), THEN dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            onSubmit(captured)
            // Reset state after panel has dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSubmitting = false
                particles = []
                particlesActive = false
            }
        }
    }
}
