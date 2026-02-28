import Foundation

/// Posts sidequest text to the sq-server, which fires a system event into Roux.
actor DiscordService {

    static let shared = DiscordService()
    private init() {}

    func post(message: String) async {
        guard let url = URL(string: Config.sqServerURL) else {
            print("[SideQuests] ❌ Bad server URL: \(Config.sqServerURL)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let payload: [String: String] = [
            "text": message,
            "secret": Config.sqServerSecret
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200:
                    print("[SideQuests] ✅ Sent: /sq \(message)")
                case 401:
                    print("[SideQuests] ❌ Unauthorized — check SQ_SERVER_SECRET.")
                default:
                    print("[SideQuests] ⚠️  Status \(http.statusCode)")
                }
            }
        } catch {
            print("[SideQuests] ❌ Network error: \(error.localizedDescription)")
        }
    }
}
