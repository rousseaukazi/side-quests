import SwiftUI
import AppKit

struct SearchBarView: View {

    let onSubmit: (String) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @State private var submitRotation: Double = 0
    @State private var submitScale: CGFloat = 1.0
    @State private var glowIntensity: CGFloat = 0
    @State private var isHoveringSubmit = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "map.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(text.isEmpty ? .secondary : .accentColor)
                .padding(.leading, 18)
                .animation(.easeInOut(duration: 0.15), value: text.isEmpty)

            TextField("Start a side quest…", text: $text)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .textFieldStyle(.plain)
                .foregroundColor(.primary)
                .focused($isFocused)
                .onSubmit(handleSubmit)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor.opacity(glowIntensity), lineWidth: 2)
                )

            if !text.isEmpty {
                Button(action: handleSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                        .rotationEffect(.degrees(submitRotation))
                        .scaleEffect(submitScale)
                        .scaleEffect(isHoveringSubmit ? 1.12 : 1.0)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
                .transition(.opacity.combined(with: .scale))
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveringSubmit = hovering
                    }
                }
            }
        }
        .frame(height: 72)
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
        // Each time the panel surfaces: clear the field and steal focus
        .onReceive(
            NotificationCenter.default.publisher(for: .sideQuestsPanelWillShow)
        ) { _ in
            text = ""
            submitRotation = 0
            submitScale = 1.0
            glowIntensity = 0
            isHoveringSubmit = false
            // Slight delay so makeKeyAndOrderFront has committed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }

    private func handleSubmit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Sound: System "Pop"
        NSSound(named: "Pop")?.play()

        // Glow pulse on text field (0.12s in, fade out)
        withAnimation(.easeIn(duration: 0.06)) {
            glowIntensity = 0.65
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.2)) {
                glowIntensity = 0
            }
        }

        // Arrow: spin 360° + scale up (0.15s)
        withAnimation(.easeInOut(duration: 0.15)) {
            submitRotation += 360
            submitScale = 1.35
        }

        // Clear field immediately, delay actual submit to let animation breathe
        let captured = trimmed
        text = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onSubmit(captured)
        }
    }
}
