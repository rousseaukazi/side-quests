import SwiftUI

struct SearchBarView: View {

    let onSubmit: (String) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.leading, 18)

            TextField("Send a side quest…", text: $text)
                .font(.system(size: 19))
                .textFieldStyle(.plain)
                .foregroundColor(.primary)
                .focused($isFocused)
                .onSubmit(handleSubmit)

            // Show a faint placeholder hint when empty
            if !text.isEmpty {
                Button(action: handleSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(height: 64)
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
        // Each time the panel surfaces: clear the field and steal focus
        .onReceive(
            NotificationCenter.default.publisher(for: .sideQuestsPanelWillShow)
        ) { _ in
            text = ""
            // Slight delay so makeKeyAndOrderFront has committed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }

    private func handleSubmit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        text = ""
    }
}
