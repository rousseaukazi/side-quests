import SwiftUI
import AppKit

struct SearchBarView: View {

    let onSubmit: (String) -> Void
    var onTextChange: ((String) -> Void)? = nil

    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @State private var isHoveringSubmit = false
    @State private var isSubmitting = false
    @State private var showCheckmark = false

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
                .onChange(of: text) { newValue in
                    onTextChange?(newValue)
                }

            // Keep visible during submit animation
            if !text.isEmpty || isSubmitting {
                Button(action: handleSubmit) {
                    ZStack {
                        // Arrow — fades out as checkmark appears
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.accentColor)
                            .scaleEffect(showCheckmark ? 0.3 : (isHoveringSubmit ? 1.12 : 1.0))
                            .opacity(showCheckmark ? 0 : 1)

                        // Checkmark — springs in
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.accentColor)
                            .scaleEffect(showCheckmark ? 1.0 : 0.3)
                            .opacity(showCheckmark ? 1 : 0)
                    }
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: showCheckmark)
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
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
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty && !isSubmitting)
        .onReceive(
            NotificationCenter.default.publisher(for: .sideQuestsPanelWillShow)
        ) { _ in
            resetState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .sideQuestsClearText)
        ) { _ in
            text = ""
            onTextChange?("")
        }
    }

    private func resetState() {
        text = ""
        isSubmitting = false
        showCheckmark = false
        isHoveringSubmit = false
        onTextChange?("")
    }

    private func handleSubmit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmitting else { return }

        isSubmitting = true

        // Sound + checkmark morph (arrow → ✓ with spring)
        NSSound(named: "Pop")?.play()
        withAnimation { showCheckmark = true }

        // Clear field immediately; button stays visible via isSubmitting
        let captured = trimmed
        text = ""

        // Hold checkmark briefly, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onSubmit(captured)
            // Reset after panel has had time to dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isSubmitting = false
                showCheckmark = false
            }
        }
    }
}
