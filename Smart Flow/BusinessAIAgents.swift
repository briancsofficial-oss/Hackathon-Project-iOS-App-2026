import Foundation

struct BusinessChatLine: Identifiable, Equatable {
    let id = UUID()
    let fromUser: Bool
    let text: String
}

@MainActor
final class BusinessInterviewAgent: ObservableObject {
    @Published private(set) var lines: [BusinessChatLine] = []
    @Published private(set) var isThinking = false
    @Published private(set) var isFinished = false
    @Published var errorText: String?
    @Published private(set) var lastSaved: [BusinessField] = []

    private let store: BusinessStore
    private var previousResponseID: String?
    private var lastUserText: String?

    init(store: BusinessStore = .shared) {
        self.store = store
    }

    var hasStarted: Bool { !lines.isEmpty || isThinking }

    func start() {
        guard !hasStarted else { return }
        run(userText: "Hi, I'm ready to start the business checkup.", showInChat: false)
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        run(userText: trimmed, showInChat: true)
    }

    func retry() {
        guard let text = lastUserText, !isThinking else { return }
        run(userText: text, showInChat: false)
    }

    func restart() {
        lines = []
        previousResponseID = nil
        isFinished = false
        errorText = nil
        lastSaved = []
    }

    private func run(userText: String, showInChat: Bool) {
        if showInChat { lines.append(BusinessChatLine(fromUser: true, text: userText)) }
        lastUserText = userText
        errorText = nil
        isThinking = true

        Task {
            do {
                try await converse(firstInput: userText)
            } catch {
                errorText = error.localizedDescription
                if case AIError.server(_, let status, _) = error, status == 400 || status == 404 {
                    previousResponseID = nil
                }
            }
            isThinking = false
        }
    }

    private func converse(firstInput: String) async throws {
        var input: Any = firstInput
        var saved: [BusinessField] = []

        for _ in 0..<6 {
            let reply = try await OpenAIClient.respond(instructions: instructions,
                                                       input: input,
                                                       tools: Self.tools,
                                                       previousResponseID: previousResponseID)
            previousResponseID = reply.responseID

            if !reply.text.isEmpty {
                lines.append(BusinessChatLine(fromUser: false, text: reply.text))
            }
            guard !reply.toolCalls.isEmpty else { break }

            var outputs: [[String: Any]] = []
            for call in reply.toolCalls {
                let result = handle(call, saved: &saved)
                outputs.append(["type": "function_call_output", "call_id": call.callID, "output": result])
            }
            input = outputs
        }
        lastSaved = saved
    }

    private func handle(_ call: OpenAIToolCall, saved: inout [BusinessField]) -> String {
        switch call.name {
        case "record_answers":
            var accepted: [String] = []
            var rejected: [String] = []
            var profile = store.profile
            for (key, value) in call.arguments {
                guard let field = BusinessField(rawValue: key), !(value is NSNull) else { continue }
                if profile.set(field, from: value) {
                    accepted.append(key)
                    saved.append(field)
                } else {
                    rejected.append(key)
                }
            }
            store.profile = profile
            return Self.json([
                "saved": accepted,
                "rejected_invalid_values": rejected,
                "still_missing": BusinessPhase.allCases.flatMap { profile.missing(in: $0) }.map(\.rawValue),
            ])

        case "finish_interview":
            isFinished = true
            return Self.json(["ok": true])

        default:
            return Self.json(["error": "Unknown function \(call.name)"])
        }
    }

    private var instructions: String {
        let profile = store.profile
        let progress = BusinessPhase.allCases.map { phase -> String in
            let missing = profile.missing(in: phase)
            let status = missing.isEmpty ? "DONE" : "missing: " + missing.map { "\($0.rawValue) (\"\($0.question)\")" }.joined(separator: "; ")
            return "Phase \(phase.rawValue + 1) \(phase.title): \(status)"
        }.joined(separator: "\n")

        let nextPhase = BusinessPhase.allCases.first { !profile.isComplete($0) }

        return """
        You are the Business Checkup interviewer inside Smart Flow, an educational finance app.
        Your job is to collect a small business owner's financial information through friendly conversation, \
        in 6 phases: Revenue & Income, Payroll & People, Operating Costs, Business Debt, Cash & Working Capital, Goals & Horizon.

        How to interview:
        - Work through the phases in order, starting with the first phase that isn't DONE. Say which phase you're on when you start a new one.
        - Ask one or two related questions per message. Keep messages under 80 words. Plain language, no jargon without a quick explanation.
        - As soon as the owner gives any answer, call record_answers with every value you learned (null for everything else). \
        Do this before writing your reply.
        - Convert to the unit the field needs: fields starting with monthly_ are per month, annual_revenue is per 12 months, \
        *_percent fields are 0-100. Example: "about $15k a week in sales" is annual_revenue 780000. Briefly confirm conversions you made.
        - "None", "no" or "we don't have that" is a valid answer: record 0 for amounts, or "No" (false) for yes/no questions.
        - If an answer is vague ("a lot", "depends"), ask for a best estimate. Estimates are fine.
        - Never invent or assume numbers the owner didn't give. Never ask for account numbers, tax IDs, SSNs or passwords.
        - Don't give financial advice during the interview. The app shows results and a plan afterwards.
        - If the owner asks to change an earlier answer, record the new value.
        - When every phase is DONE, give a 2-3 sentence recap, tell them to tap "See results", and call finish_interview.

        Progress right now:
        \(progress)
        \(nextPhase.map { "Next phase to work on: \($0.title)." } ?? "All phases are complete.")

        Answers saved so far:
        \(profile.summaryForAI)
        """
    }

    private static let tools: [[String: Any]] = {
        var properties: [String: Any] = [:]
        for field in BusinessField.allCases {
            var schema: [String: Any] = ["description": field.question + " " + field.hint]
            switch field.kind {
            case .money, .count:
                schema["type"] = ["number", "null"]
            case .percent:
                schema["type"] = ["number", "null"]
                schema["description"] = field.question + " (0-100) " + field.hint
            case .text:
                schema["type"] = ["string", "null"]
            case .choice(let options):
                schema["type"] = ["string", "null"]
                schema["enum"] = (options as [Any]) + [NSNull()]
            case .yesNo:
                schema["type"] = ["boolean", "null"]
            }
            properties[field.rawValue] = schema
        }

        let record: [String: Any] = [
            "type": "function",
            "name": "record_answers",
            "description": "Save the business owner's answers. Use null for every field not learned in this message.",
            "strict": true,
            "parameters": [
                "type": "object",
                "properties": properties,
                "required": BusinessField.allCases.map(\.rawValue),
                "additionalProperties": false,
            ] as [String: Any],
        ]

        let finish: [String: Any] = [
            "type": "function",
            "name": "finish_interview",
            "description": "Call once, after every phase is complete and you've recapped.",
            "strict": true,
            "parameters": [
                "type": "object",
                "properties": ["recap": ["type": "string"]],
                "required": ["recap"],
                "additionalProperties": false,
            ] as [String: Any],
        ]
        return [record, finish]
    }()

    private static func json(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}

struct DocumentFindings {
    let documentType: String
    let notes: String
    let values: [(field: BusinessField, value: Double)]
}

enum BusinessDocumentReader {
    private static var readableFields: [BusinessField] {
        BusinessField.allCases.filter { $0.kind.isNumber && $0.phase != .goals }
    }

    static func read(_ attachments: [AIAttachment]) async throws -> DocumentFindings {
        var properties: [String: Any] = [
            "document_type": ["type": "string", "description": "e.g. Profit and loss statement, Bank statement, Payroll register, Balance sheet. If there are several documents, name each type briefly."],
            "notes": ["type": "string", "description": "One or two sentences: the period covered and any caveats."],
        ]
        for field in readableFields {
            properties[field.rawValue] = ["type": ["number", "null"], "description": field.question + " " + field.hint]
        }
        let schema: [String: Any] = [
            "type": "object",
            "properties": properties,
            "required": ["document_type", "notes"] + readableFields.map(\.rawValue),
            "additionalProperties": false,
        ]

        let system = """
        You extract small-business financial figures from documents for a budgeting app.
        You may get several documents at once. Combine them into one set of answers; when they overlap, use the most recent and most complete one.
        Only fill a field when the documents clearly support it. Use null for anything you would have to guess.
        Units: fields starting with monthly_ are per month (average a multi-month period; divide yearly totals by 12). \
        annual_revenue is a 12-month total (annualize a shorter period and say so in notes). Percent fields are 0-100. \
        Balances are as of the document's end date. Use plain numbers with no currency symbols.
        Never include account numbers, names of employees or any personal identifiers.
        """

        let text = try await OpenAIClient.generate(
            prompt: attachments.count == 1 ? "Extract the figures from this document." : "Extract the figures from these \(attachments.count) documents.",
            instructions: system,
            attachments: attachments,
            jsonSchema: (name: "business_figures", schema: schema),
            model: AIFeature.documentImport.model)

        guard let json = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] else {
            throw AIError.unreadable(.openAI)
        }

        var values: [(field: BusinessField, value: Double)] = []
        for field in readableFields {
            var probe = BusinessProfile()
            if probe.set(field, from: json[field.rawValue]) {
                values.append((field: field, value: probe[field]))
            }
        }
        return DocumentFindings(documentType: json["document_type"] as? String ?? "Document",
                                notes: json["notes"] as? String ?? "",
                                values: values)
    }
}

enum PlanChart: String, CaseIterable {
    case none
    case cashRunway = "cash_runway"
    case debtCoverage = "debt_coverage"
    case payrollShare = "payroll_share"
    case currentRatio = "current_ratio"
    case cashFlow = "cash_flow"
    case expenseBreakdown = "expense_breakdown"
    case debtBalances = "debt_balances"
}

struct ActionPlan: Codable {
    struct Step: Codable {
        let title: String
        let detail: String
        let chart: String

        var chartKind: PlanChart { PlanChart(rawValue: chart) ?? .none }
    }

    let summary: String
    let steps: [Step]

    static func decode(_ text: String) -> ActionPlan? {
        try? JSONDecoder().decode(ActionPlan.self, from: Data(text.utf8))
    }
}

enum BusinessPlanWriter {
    static let disclaimer = "This is educational, not professional advice. For tax, legal or lending decisions, talk to a CPA or advisor."

    static func write(for profile: BusinessProfile) async throws -> String {
        let metrics = BusinessMetrics(p: profile)
        let system = """
        You are a small-business finance coach inside an educational app. Write a practical action plan.
        Use ONLY the answers and calculated metrics provided; never recalculate or invent figures. Quote the dollar amounts given.
        Format: summary is a one-sentence overall read. Then 3 to 5 steps ordered by urgency. Each step has a short title \
        and 1-2 sentences of detail on what to do and why, tied to a specific number. Priorities in general: past-due taxes, \
        cash runway under 3 months, DSCR under 1.25, expensive debt such as merchant cash advances and card balances, \
        then the owner's stated goal and timeline.
        Charts: the app draws charts from its own numbers. For each step pick the one chart that makes that step clearer, \
        or "none". Use charts only where they help: at most 3 in the whole plan, never the same chart twice, \
        and never a chart whose metric is n/a.
        - cash_runway: months of fixed costs the cash covers, against a 3-month target
        - debt_coverage: DSCR against the 1.25x lender target
        - payroll_share: payroll as a share of revenue
        - current_ratio: short-term assets against short-term debts
        - cash_flow: monthly money in, money out and net cash flow
        - expense_breakdown: where monthly spending goes
        - debt_balances: balances owed by type
        Under 250 words in total. Don't add a disclaimer; the app shows one.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "summary": ["type": "string", "description": "One-sentence overall read."],
                "steps": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "title": ["type": "string", "description": "Short step title."],
                            "detail": ["type": "string", "description": "1-2 sentences tied to a specific number."],
                            "chart": ["type": "string", "enum": PlanChart.allCases.map(\.rawValue),
                                      "description": "The chart that supports this step, or none."],
                        ] as [String: Any],
                        "required": ["title", "detail", "chart"],
                        "additionalProperties": false,
                    ] as [String: Any],
                ] as [String: Any],
            ] as [String: Any],
            "required": ["summary", "steps"],
            "additionalProperties": false,
        ]
        let prompt = """
        Business answers:
        \(profile.summaryForAI)

        Calculated by the app:
        \(metrics.summaryForAI)
        """
        let text = try await OpenAIClient.generate(prompt: prompt, instructions: system,
                                                   jsonSchema: (name: "action_plan", schema: schema),
                                                   model: AIFeature.actionPlan.model)
        guard ActionPlan.decode(text) != nil else { throw AIError.unreadable(.openAI) }
        return text
    }
}
