import Foundation

/// Posts sidequest text to the sq-server, which handles Discord channel creation.
actor DiscordService {

    static let shared = DiscordService()
    private init() {}

    func post(message: String) async {
        let endpoint = Config.endpoint
        let secret   = Config.secret

        guard let url = URL(string: endpoint) else {
            print("[SideQuests] ❌ Invalid endpoint URL: \(endpoint)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let payload: [String: String] = ["text": message, "secret": secret]

        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200, 201:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let channel = json["channel"] as? String {
                        print("[SideQuests] ✅ Created: #\(channel)")
                    }
                default:
                    print("[SideQuests] ❌ Server error \(http.statusCode)")
                }
            }
        } catch {
            print("[SideQuests] ❌ Network error: \(error.localizedDescription)")
        }
    }
}
