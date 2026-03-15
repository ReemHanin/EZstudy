import Foundation

struct AIMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    enum Role { case user, assistant }
}

class AIService: ObservableObject {
    static let shared = AIService()

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    }

    var hasAPIKey: Bool { !apiKey.isEmpty }

    func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "anthropic_api_key")
    }

    func complete(
        prompt: String,
        systemPrompt: String = "You are a helpful study assistant for students. Be concise and clear.",
        maxTokens: Int = 1024
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.noAPIKey }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [["role": "user", "content": prompt]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.apiError(msg)
        }

        let parsed = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return parsed.content.first?.text ?? ""
    }

    enum AIError: LocalizedError {
        case noAPIKey
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key configured. Tap the key icon to set your Anthropic API key."
            case .apiError(let msg):
                return "API error: \(msg)"
            }
        }
    }
}

private struct AnthropicResponse: Decodable {
    struct Content: Decodable { let text: String }
    let content: [Content]
}
