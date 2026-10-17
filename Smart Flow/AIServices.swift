import Foundation
import Security

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    var id: String { rawValue }

    var keyPageURL: URL { URL(string: "https://platform.openai.com/api-keys")! }
}

enum AIFeature: String, CaseIterable, Identifiable {
    case interview = "AI interview"
    case documentImport = "Document import"
    case actionPlan = "Action plan"
    var id: String { rawValue }

    var provider: AIProvider { .openAI }

    var model: String {
        switch self {
        case .interview:      return "gpt-6.1-sol"
        case .documentImport: return "gpt-6.1-sol"
        case .actionPlan:     return "gpt-6.1-sol"
        }
    }
}

enum AIError: LocalizedError {
    case missingKey(AIProvider)
    case server(AIProvider, status: Int, message: String)
    case unreadable(AIProvider)

    var errorDescription: String? {
        switch self {
        case .missingKey(let p):
            return "Add your \(p.rawValue) API key in the Settings tab > AI keys."
        case .server(let p, let status, let message):
            switch status {
            case 401, 403: return "\(p.rawValue) didn't accept the API key. Check it in Settings > AI keys."
            case 429:      return "\(p.rawValue) is rate-limiting or the account is out of credit. Try again shortly."
            default:       return "\(p.rawValue) error \(status): \(message)"
            }
        case .unreadable(let p):
            return "\(p.rawValue) sent back something the app couldn't read. Please try again."
        }
    }
}

enum AIKeyVault {
    private static let service = "SmartFlow.aiKeys"

    static func key(for provider: AIProvider) -> String? {
        if let saved = read(provider), !saved.isEmpty { return saved }
        if let value = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !value.isEmpty { return value }
        return nil
    }

    static func hasKey(_ provider: AIProvider) -> Bool { key(for: provider) != nil }

    static func save(_ key: String, for provider: AIProvider) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        SecItemDelete(query(provider) as CFDictionary)
        defer { AIKeyStatus.shared.changed() }
        guard !trimmed.isEmpty else { return }
        var add = query(provider)
        add[kSecValueData as String] = Data(trimmed.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    static func remove(_ provider: AIProvider) {
        SecItemDelete(query(provider) as CFDictionary)
        AIKeyStatus.shared.changed()
    }

    static func removeUnusedKeys() {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: "Gemini"]
        SecItemDelete(q as CFDictionary)
    }

    private static func query(_ provider: AIProvider) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: provider.rawValue]
    }

    private static func read(_ provider: AIProvider) -> String? {
        var q = query(provider)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

final class AIKeyStatus: ObservableObject {
    static let shared = AIKeyStatus()
    @Published private(set) var version = 0

    func changed() {
        DispatchQueue.main.async { self.version += 1 }
    }
}

struct AIAttachment {
    let data: Data
    let mimeType: String
    var filename: String = "document"

    var contentPart: [String: Any] {
        let dataURL = "data:\(mimeType);base64,\(data.base64EncodedString())"
        if mimeType == "application/pdf" {
            let name = filename.lowercased().hasSuffix(".pdf") ? filename : filename + ".pdf"
            return ["type": "input_file", "filename": name, "file_data": dataURL]
        }
        return ["type": "input_image", "image_url": dataURL]
    }
}

struct OpenAIToolCall {
    let callID: String
    let name: String
    let arguments: [String: Any]
}

struct OpenAIReply {
    let responseID: String
    let text: String
    let toolCalls: [OpenAIToolCall]
}

enum OpenAIClient {
    private static let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    static func respond(instructions: String,
                        input: Any,
                        tools: [[String: Any]],
                        previousResponseID: String?,
                        model: String = AIFeature.interview.model) async throws -> OpenAIReply {
        var body: [String: Any] = [
            "model": model,
            "instructions": instructions,
            "input": input,
            "tools": tools,
        ]
        if let previous = previousResponseID { body["previous_response_id"] = previous }
        return try await send(body)
    }

    static func generate(prompt: String,
                         instructions: String,
                         attachments: [AIAttachment] = [],
                         jsonSchema: (name: String, schema: [String: Any])? = nil,
                         model: String) async throws -> String {
        var content: [[String: Any]] = attachments.map(\.contentPart)
        content.append(["type": "input_text", "text": prompt])

        var body: [String: Any] = [
            "model": model,
            "instructions": instructions,
            "input": [["role": "user", "content": content]],
            "store": false,
        ]
        if let json = jsonSchema {
            body["text"] = ["format": ["type": "json_schema", "name": json.name,
                                       "schema": json.schema, "strict": true] as [String: Any]]
        }
        let reply = try await send(body, timeout: 180)
        guard !reply.text.isEmpty else { throw AIError.unreadable(.openAI) }
        return reply.text
    }

    private static func send(_ body: [String: Any], timeout: TimeInterval = 90) async throws -> OpenAIReply {
        guard let key = AIKeyVault.key(for: .openAI) else { throw AIError.missingKey(.openAI) }

        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

        guard (200..<300).contains(status) else {
            let message = ((json?["error"] as? [String: Any])?["message"] as? String)
                ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.server(.openAI, status: status, message: message)
        }
        guard let reply = json, let id = reply["id"] as? String,
              let output = reply["output"] as? [[String: Any]] else {
            throw AIError.unreadable(.openAI)
        }

        var text = ""
        var calls: [OpenAIToolCall] = []
        for item in output {
            switch item["type"] as? String {
            case "message":
                for part in item["content"] as? [[String: Any]] ?? [] where part["type"] as? String == "output_text" {
                    text += part["text"] as? String ?? ""
                }
            case "function_call":
                let raw = (item["arguments"] as? String) ?? "{}"
                let args = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any] ?? [:]
                if let callID = item["call_id"] as? String, let name = item["name"] as? String {
                    calls.append(OpenAIToolCall(callID: callID, name: name, arguments: args))
                }
            default:
                break
            }
        }
        return OpenAIReply(responseID: id, text: text, toolCalls: calls)
    }
}
