//
//  AIServices.swift
//  Safety First
//
// The cloud AI layer. Everything uses the OpenAI API (the Responses API, POST /v1/responses):
//
//   Feature              How it uses OpenAI
//   -------------------  ----------------------------------------------------------------------
//   AI interview         A back-and-forth chat that saves answers with function calling
//   Document import      Reads a PDF or photo and returns the figures as JSON (structured output)
//   Action plan          Writes a plan from the answers and the app's own calculations
//
// Each feature can use its own model: change AIFeature.model below.
//
//   AIProvider / AIFeature = the provider, and which model each feature uses
//   AIKeyVault             = stores the API key in the iPhone Keychain (never in the code)
//   AIKeyStatus            = tells the screens when the key is saved or removed
//   OpenAIClient           = the network calls
//
// IMPORTANT before shipping to the App Store: any key inside an app can be pulled out of it.
// For a class project, typing your own key into Settings > AI keys is fine. For real users, put a small
// server in between (the app calls your server, your server holds the key and calls OpenAI).
// Only the endpoint URL below would change.

import Foundation
import Security

// MARK: - Provider and models

// Only one provider now. Kept as an enum so the Settings screen and messages don't hard-code the name.
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

    // Model IDs. Check OpenAI's model list for current names and prices.
    // gpt-6.1-sol = balanced cost/quality with function calling, structured output and PDF/image input.
    // Swap in "gpt-6-luna" for lower cost, or "gpt-6-astra" for the strongest model.
    var model: String {
        switch self {
        case .interview:      return "gpt-6.1-sol"
        case .documentImport: return "gpt-6.1-sol"
        case .actionPlan:     return "gpt-6.1-sol"
        }
    }
}

// MARK: - Errors

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

// MARK: - API key (Keychain)

// Same Keychain approach as PasswordVault: encrypted, only while unlocked, never synced or backed up.
// For development you can instead set OPENAI_API_KEY in
// Product > Scheme > Edit Scheme > Run > Environment Variables (only works when run from Xcode).
enum AIKeyVault {
    private static let service = "TheWealthApp.aiKeys"

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

    // Removes keys saved by older versions of the app for providers it no longer uses (e.g. Gemini).
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

// The Keychain can't tell SwiftUI when it changes, so screens that show "add a key" watch this instead.
// Saving or removing a key bumps it, and every AI screen redraws.
final class AIKeyStatus: ObservableObject {
    static let shared = AIKeyStatus()
    @Published private(set) var version = 0

    func changed() {
        DispatchQueue.main.async { self.version += 1 }
    }
}

// MARK: - Files sent to OpenAI

// A PDF or an image the user picked.
struct AIAttachment {
    let data: Data
    let mimeType: String
    var filename: String = "document"

    // Responses API content part: PDFs are "input_file", photos are "input_image". Both are sent as base64 data URLs.
    var contentPart: [String: Any] {
        let dataURL = "data:\(mimeType);base64,\(data.base64EncodedString())"
        if mimeType == "application/pdf" {
            let name = filename.lowercased().hasSuffix(".pdf") ? filename : filename + ".pdf"
            return ["type": "input_file", "filename": name, "file_data": dataURL]
        }
        return ["type": "input_image", "image_url": dataURL]
    }
}

// MARK: - OpenAI (Responses API)

// One function the model asked the app to run.
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

    // Conversation turn with tools (used by the interview).
    // input: a plain user message (String) or an array of input items (e.g. function_call_output).
    // previousResponseID: continues the same conversation, so earlier turns don't have to be re-sent.
    static func respond(instructions: String,
                        input: Any,
                        tools: [[String: Any]],
                        previousResponseID: String?,
                        model: String = AIFeature.interview.model) async throws -> OpenAIReply {
        var body: [String: Any] = [
            "model": model,
            "instructions": instructions,   // sent every turn, so it always has the latest answers
            "input": input,
            "tools": tools,
        ]
        if let previous = previousResponseID { body["previous_response_id"] = previous }
        return try await send(body)
    }

    // One-off request (used by document import and the action plan).
    // Pass a JSON schema to get back JSON that matches it exactly (strict structured output).
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
            "store": false,   // one-off requests don't need to be kept on OpenAI's side
        ]
        if let json = jsonSchema {
            body["text"] = ["format": ["type": "json_schema", "name": json.name,
                                       "schema": json.schema, "strict": true] as [String: Any]]
        }
        let reply = try await send(body, timeout: 180)
        guard !reply.text.isEmpty else { throw AIError.unreadable(.openAI) }
        return reply.text
    }

    // Sends the request and pulls the text and function calls out of the reply.
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
                // "arguments" arrives as a JSON string, so it's decoded here.
                let raw = (item["arguments"] as? String) ?? "{}"
                let args = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any] ?? [:]
                if let callID = item["call_id"] as? String, let name = item["name"] as? String {
                    calls.append(OpenAIToolCall(callID: callID, name: name, arguments: args))
                }
            default:
                break   // reasoning items etc. are kept server-side via previous_response_id
            }
        }
        return OpenAIReply(responseID: id, text: text, toolCalls: calls)
    }
}
