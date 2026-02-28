import Foundation

actor DiscordService {

    static let shared = DiscordService()

    private init() {}

    func post(message: String) async {
        let urlString = Config.webhookURL

        guard urlString != Config.placeholderURL else {
            print("[SideQuests] ⚠️  No webhook URL configured.")
            print("[SideQuests]    Set DISCORD_WEBHOOK_URL in the build settings or Info.plist.")
            return
        }

        guard let url = URL(string: urlString) else {
            print("[SideQuests] ⚠️  Malformed webhook URL: \(urlString)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Discord webhook payload
        let payload: [String: Any] = [
            "content": message,
            "username": "Side Quests"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200, 204:
                    print("[SideQuests] ✅ Posted: \(message)")
                case 400...499:
                    print("[SideQuests] ❌ Client error \(http.statusCode) — check webhook URL.")
                case 500...599:
                    print("[SideQuests] ❌ Discord server error \(http.statusCode).")
                default:
                    print("[SideQuests] ⚠️  Unexpected status \(http.statusCode).")
                }
            }
        } catch {
            print("[SideQuests] ❌ Network error: \(error.localizedDescription)")
        }
    }
}
