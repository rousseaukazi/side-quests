import Foundation

actor SideQuestService {

    static let shared = SideQuestService()
    private init() {}

    private let endpoint = "http://3.145.73.180:4141/sq"
    private let secret   = "roux-sq-secret"

    func post(text: String) async {
        guard let url = URL(string: endpoint) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let payload: [String: String] = ["text": text, "secret": secret]

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
