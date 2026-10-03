import Foundation
import Security

/// What the routes page shows above the cards: where from, how long, roughly how much.
struct PlanContext: Equatable {
    var origin: String
    var days: Int
    var budget: String

    static let sample = PlanContext(origin: "Warsaw", days: 4, budget: "Around €800")
}

struct GeneratedPlan {
    let context: PlanContext
    let routes: [TravelRoute]
}

enum PlannerError: LocalizedError {
    case missingKey
    case http(Int, String)
    case refused
    case truncated
    case unreadable

    var errorDescription: String? {
        switch self {
        case .missingKey: "Add a Claude API key to plan real trips."
        case .http(401, _): "Claude didn’t accept the API key. Check it in your profile."
        case .http(429, _): "Claude is busy right now. Try again in a moment."
        case .http(let code, let message): "Claude returned an error (\(code)). \(message)"
        case .refused: "Claude couldn’t plan this one. Try describing the trip differently."
        case .truncated: "The plan came back incomplete. Try a shorter trip or fewer details."
        case .unreadable: "The plan came back in an unexpected shape. Try again."
        }
    }
}

/// Plans trips with Claude. Keeps the conversation so "make it better" requests
/// build on the routes already shown.
@MainActor
@Observable
final class TripPlanner {
    private(set) var isWorking = false
    private(set) var progress = ""
    private(set) var isImprovingWish = false
    /// Raw API messages, appended to and never edited, so follow-up turns can refine the plan.
    private var history: [[String: Any]] = []

    func plan(wish: String, origin: String) async throws -> GeneratedPlan {
        history = [["role": "user", "content": "Home city: \(origin)\n\nTrip wish:\n\(wish)"]]
        return try await requestPlan()
    }

    func refine(_ feedback: String) async throws -> GeneratedPlan {
        history.append(["role": "user", "content": "Make the plan better: \(feedback)\n\nReturn the full updated plan with three routes."])
        do {
            return try await requestPlan()
        } catch {
            history.removeLast()
            throw error
        }
    }

    /// Rewrites a rough wish into a clearer one, keeping the traveller's own intent.
    func improve(wish: String, origin: String) async throws -> String {
        isImprovingWish = true
        defer { isImprovingWish = false }
        let body: [String: Any] = [
            "model": ClaudeAPI.model,
            "max_tokens": 2000,
            "output_config": ["effort": "low"],
            "system": """
            You help travellers describe a trip for a planning app. Rewrite the traveller's wish as 2–3 warm, \
            first-person sentences that state: what kind of place and pace they want, how many days, where they start \
            (default: \(origin)), and a per-person budget in euros if they gave one. Keep every detail they mentioned \
            and do not invent specific destinations they didn't ask for. If something important is missing, make a \
            sensible assumption and phrase it naturally. Reply with the rewritten wish only.
            """,
            "messages": [["role": "user", "content": wish]]
        ]
        let message = try await ClaudeAPI.send(body) { _ in }
        let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw PlannerError.unreadable }
        return text
    }

    private func requestPlan() async throws -> GeneratedPlan {
        isWorking = true
        progress = "Reading your wish"
        defer { isWorking = false }
        let body: [String: Any] = [
            "model": ClaudeAPI.model,
            "max_tokens": 32000,
            "output_config": ["effort": "medium", "format": ["type": "json_schema", "schema": PlanSchema.schema]],
            "system": PlanSchema.systemPrompt,
            "messages": history
        ]
        let message = try await ClaudeAPI.send(body) { [weak self] text in
            self?.progress = PlanSchema.progress(for: text)
        }
        guard let data = message.text.data(using: .utf8),
              let dto = try? JSONDecoder().decode(PlanDTO.self, from: data),
              dto.routes.count > 0 else { throw PlannerError.unreadable }
        history.append(["role": "assistant", "content": message.content])
        return dto.plan()
    }
}

// MARK: - API

enum ClaudeAPI {
    static let model = "claude-opus-5-5"

    struct Message {
        /// Content blocks exactly as returned, so they can be sent back unchanged.
        let content: [[String: Any]]
        var text: String {
            content.filter { $0["type"] as? String == "text" }.compactMap { $0["text"] as? String }.joined()
        }
    }

    static var apiKey: String? {
        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty { return key }
        return KeyStore.load()
    }

    /// Streams a Messages API request and rebuilds the final content blocks from the events.
    static func send(_ body: [String: Any], onText: @escaping (String) -> Void) async throws -> Message {
        guard let apiKey else { throw PlannerError.missingKey }
        var body = body
        body["stream"] = true
        body["fallbacks"] = "default"

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 300
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            var raw = ""
            for try await line in bytes.lines { raw += line }
            throw PlannerError.http(status, errorMessage(from: raw))
        }

        var blocks: [Int: [String: Any]] = [:]
        var partialJSON: [Int: String] = [:]
        var text = ""
        var stopReason: String?

        for try await line in bytes.lines {
            guard line.hasPrefix("data:"),
                  let data = line.dropFirst(5).trimmingCharacters(in: .whitespaces).data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = event["type"] as? String else { continue }
            let index = event["index"] as? Int ?? 0
            switch type {
            case "content_block_start":
                blocks[index] = event["content_block"] as? [String: Any]
            case "content_block_delta":
                guard let delta = event["delta"] as? [String: Any], var block = blocks[index] else { continue }
                switch delta["type"] as? String {
                case "text_delta":
                    let piece = delta["text"] as? String ?? ""
                    block["text"] = (block["text"] as? String ?? "") + piece
                    text += piece
                    onText(text)
                case "thinking_delta":
                    block["thinking"] = (block["thinking"] as? String ?? "") + (delta["thinking"] as? String ?? "")
                case "signature_delta":
                    block["signature"] = delta["signature"] as? String
                case "input_json_delta":
                    partialJSON[index, default: ""] += delta["partial_json"] as? String ?? ""
                default:
                    break
                }
                blocks[index] = block
            case "content_block_stop":
                if let json = partialJSON[index], let data = json.data(using: .utf8) {
                    blocks[index]?["input"] = try? JSONSerialization.jsonObject(with: data)
                }
            case "message_delta":
                if let delta = event["delta"] as? [String: Any] { stopReason = delta["stop_reason"] as? String ?? stopReason }
            case "error":
                let message = (event["error"] as? [String: Any])?["message"] as? String ?? "Stream interrupted."
                throw PlannerError.http(529, message)
            default:
                break
            }
        }

        switch stopReason {
        case "refusal": throw PlannerError.refused
        case "max_tokens": throw PlannerError.truncated
        default: break
        }
        return Message(content: blocks.keys.sorted().compactMap { blocks[$0] })
    }

    private static func errorMessage(from raw: String) -> String {
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else { return "" }
        return message
    }
}

/// Stores the API key in the Keychain so it never lands in the project or UserDefaults.
enum KeyStore {
    private static let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "elsewhere.anthropic",
        kSecAttrAccount as String: "api-key"
    ]

    static func load() -> String? {
        var request = query
        request[kSecReturnData as String] = true
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ key: String) {
        SecItemDelete(query as CFDictionary)
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var item = query
        item[kSecValueData as String] = Data(trimmed.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }
}

// MARK: - Plan schema

private enum PlanSchema {
    static let artwork = ["Algarve", "Costa", "Tavira", "Lisbon", "Madeira", "Rome", "Copenhagen", "Tokyo", "none"]

    static let systemPrompt = """
    You are the trip planner inside Elsewhere, a travel app. Turn the traveller's wish into three genuinely \
    different ways to take the trip, each with a complete day-by-day itinerary they could follow.

    Guidelines:
    - Start from the traveller's home city unless the wish names another origin. Use the trip length and budget \
    they give; if they don't give them, choose sensible ones and reflect them in the plan's context fields.
    - The three routes should differ in a meaningful trade-off (for example easiest journey, most nature, best \
    value, most culture) and say so in a short badge. They may share a destination region or go to different ones.
    - Use real places that exist. Keep travel times and prices realistic for the season; all money is an \
    estimated per-person amount in whole euros, and all durations are whole minutes.
    - Every day has 2–4 stops in visiting order. transferMinutes/transferTitle/transferCost describe getting from \
    that stop to the next one; the last stop of each day has transferMinutes 0, transferCost 0 and an empty \
    transferTitle. The first and last days include arriving and leaving. startMinute is minutes after midnight.
    - Give every stop exactly two alternatives the traveller could swap in. roadDelta is how many minutes the \
    alternative adds to (positive) or saves from (negative) the onward transfer.
    - costs cover the whole trip: destinationTravel (getting there and back), stay, localTransport, visits.
    - travelMinutes is total time spent travelling over the whole trip, including getting there and back.
    - artwork: choose a bundled photo only when it actually shows that destination (Algarve = Algarve beaches, \
    Costa = Costa Vicentina, Tavira = eastern Algarve, Lisbon, Madeira, Rome, Copenhagen, Tokyo); otherwise "none".
    - Write in a calm, warm tone. Titles are short; reasons are one brief phrase.

    When the traveller asks to make the plan better, return a complete updated plan that applies their request \
    while keeping what they didn't ask to change.
    """

    private static func object(_ properties: [String: Any]) -> [String: Any] {
        ["type": "object", "properties": properties, "required": Array(properties.keys), "additionalProperties": false]
    }
    private static let string: [String: Any] = ["type": "string"]
    private static let integer: [String: Any] = ["type": "integer"]

    static let schema: [String: Any] = {
        let option = object(["title": string, "reason": string, "visitMinutes": integer, "price": integer, "roadDelta": integer])
        let stop = object([
            "title": string, "reason": string, "visitMinutes": integer, "price": integer,
            "transferMinutes": integer, "transferTitle": string, "transferCost": integer,
            "alternatives": ["type": "array", "items": option]
        ])
        let day = object(["title": string, "note": string, "startMinute": integer, "stops": ["type": "array", "items": stop]])
        let costs = object(["destinationTravel": integer, "stay": integer, "localTransport": integer, "visits": integer])
        let route = object([
            "badge": string, "name": string, "place": string, "headline": string, "reason": string,
            "artwork": ["type": "string", "enum": artwork], "travelMinutes": integer, "costs": costs,
            "days": ["type": "array", "items": day]
        ])
        return object([
            "origin": string, "days": integer,
            "budget": ["type": "string", "description": "Short label such as \"Around €800\""],
            "routes": ["type": "array", "items": route]
        ])
    }()

    /// Turns the partial JSON streamed so far into a short status line.
    static func progress(for partial: String) -> String {
        let routes = partial.components(separatedBy: "\"badge\"").count - 1
        let place = partial.components(separatedBy: "\"place\":").last.flatMap { tail -> String? in
            guard routes > 0 else { return nil }
            let parts = tail.split(separator: "\"", omittingEmptySubsequences: false)
            return parts.count > 2 ? String(parts[1]) : nil
        }
        switch routes {
        case 0: return "Choosing where to go"
        default:
            if let place, !place.isEmpty { return "Route \(min(routes, 3)) of 3 · \(place)" }
            return "Route \(min(routes, 3)) of 3"
        }
    }
}

private struct PlanDTO: Decodable {
    struct Option: Decodable { let title, reason: String; let visitMinutes, price, roadDelta: Int }
    struct Stop: Decodable {
        let title, reason: String
        let visitMinutes, price, transferMinutes: Int
        let transferTitle: String
        let transferCost: Int
        let alternatives: [Option]
    }
    struct Day: Decodable { let title, note: String; let startMinute: Int; let stops: [Stop] }
    struct Costs: Decodable { let destinationTravel, stay, localTransport, visits: Int }
    struct Route: Decodable {
        let badge, name, place, headline, reason, artwork: String
        let travelMinutes: Int
        let costs: Costs
        let days: [Day]
    }
    let origin: String
    let days: Int
    let budget: String
    let routes: [Route]

    func plan() -> GeneratedPlan {
        // Route ids stay unique across plans so saved routes and swaps never collide.
        let base = Int(Date().timeIntervalSince1970 * 10) * 10
        let routes = routes.prefix(3).enumerated().map { index, route in
            let days = route.days.map { day in
                DayPlan(title: day.title, note: day.note, startMinute: day.startMinute, stops: day.stops.enumerated().map { id, stop in
                    TravelStop(id: id, title: stop.title, reason: stop.reason, visitMinutes: stop.visitMinutes,
                               price: stop.price, transferMinutes: stop.transferMinutes, transferTitle: stop.transferTitle,
                               transferCost: stop.transferCost, alternatives: stop.alternatives.map {
                                   TravelOption(title: $0.title, reason: $0.reason, visitMinutes: $0.visitMinutes, price: $0.price, roadDelta: $0.roadDelta)
                               })
                })
            }
            let costs = CostBreakdown(destinationTravel: route.costs.destinationTravel, stay: route.costs.stay,
                                      localTransport: route.costs.localTransport, visits: route.costs.visits)
            let anchor = days.count > 1 ? days[1] : days.first
            return TravelRoute(
                id: base + index, badge: route.badge, name: route.name, place: route.place,
                headline: route.headline, reason: route.reason,
                artwork: route.artwork == "none" ? "" : route.artwork,
                estimatedTotal: costs.destinationTravel + costs.stay + costs.localTransport + costs.visits,
                travelMinutes: route.travelMinutes,
                visitMinutes: days.flatMap(\.stops).reduce(0) { $0 + $1.visitMinutes },
                costs: costs, dayTitle: anchor?.title ?? "", dayNote: anchor?.note ?? "",
                stops: anchor?.stops ?? [], days: days
            )
        }
        return GeneratedPlan(context: PlanContext(origin: origin, days: max(days, 1), budget: budget), routes: routes)
    }
}
