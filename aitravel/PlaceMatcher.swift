import Foundation

/// How well one place fits the traveller's wish, and why.
struct PlaceMatch: Identifiable {
    struct Reason: Identifiable {
        let id: String
        let label: String
        let symbol: String
        /// 0–1: how well the place delivers on something the traveller cares about.
        let fit: Double
        /// True when the place has something the traveller wants to avoid, or misses on budget, length, or distance.
        let isWarning: Bool
        var showsPercent = true

        var text: String { showsPercent ? "\(label) \(Int((fit * 100).rounded()))%" : label }
    }

    let place: Place
    /// 0–1 overall fit shown as a percentage.
    let fit: Double
    let reasons: [Reason]

    var id: String { place.id }
    var percent: Int { Int((fit * 100).rounded()) }
}

/// What Jev read from the wish: how much each trait matters, plus budget and distance.
struct TravellerProfile {
    /// Probability per level: avoid, indifferent, would enjoy, central.
    var preferences: [PlaceParam: [Double]] = [:]
    /// Per-person budget in euros, when the wish names an amount.
    var budgetAmount: Int?
    /// Target cost level 0–1, when the wish implies a budget without naming one.
    var budgetTarget: Double?
    /// Trip length in days, if the wish implies one.
    var tripDays: Double?
    /// Flight-length preference, if the wish implies one.
    var wantsShortFlight: Bool?

    func wants(_ param: PlaceParam) -> Double {
        guard let p = preferences[param], p.count == 4 else { return 0 }
        return p[2] * 0.6 + p[3]
    }

    func avoids(_ param: PlaceParam) -> Double {
        preferences[param]?.first ?? 0
    }
}

enum MatchError: LocalizedError {
    case missingKey
    case http(Int, String)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .missingKey: "Add JEV_API_KEY or OPENROUTER_API_KEY to the .env file to match places to your wish."
        case .http(401, _), .http(403, _): "Jev didn’t accept the API key. Check \(AppConfig.jev?.keyName ?? "JEV_API_KEY") in .env."
        case .http(429, _): "Jev is rate limiting requests. Keep typing and it will try again."
        case .http(let code, let message): "Jev returned an error (\(code)). \(message)"
        case .unreadable: "Jev’s answer came back in an unexpected shape."
        }
    }
}

/// Ranks the bundled places against a wish with one Jev request: a yes/no "would this fit?" per place,
/// plus questions that read the traveller's preferences so each match can explain itself.
@MainActor
@Observable
final class PlaceMatcher {
    private(set) var matches: [PlaceMatch] = []
    private(set) var isMatching = false
    private(set) var error: String?
    /// The wish the current matches were computed for.
    private(set) var matchedWish = ""

    /// The traveller can submit once the wish is at least this long.
    static let minimumCharacters = 10

    func match(wish: String, origin: String) async {
        let wish = wish.trimmingCharacters(in: .whitespacesAndNewlines)
        guard wish != matchedWish || matches.isEmpty else { return }
        isMatching = true
        error = nil
        defer { isMatching = false }
        do {
            let answers = try await JevAPI.evaluate(state: [
                "traveller_wish": wish,
                "home_city": origin,
                "today": Date.now.formatted(.dateTime.month(.wide).year())
            ], questions: Self.questions(for: PlaceLibrary.all))
            guard !Task.isCancelled else { return }
            matches = Self.rank(PlaceLibrary.all, answers: answers, wish: wish)
            matchedWish = wish
            error = nil
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            self.error = error.localizedDescription
        }
    }

    #if DEBUG
    /// Shows matches from hand-written, Jev-shaped preference answers, for visual review without an API key.
    /// There are no per-place answers here, so the fit comes from the trait match alone.
    func preview(answers: [String: JevAnswer], wish: String) {
        matches = Self.rank(PlaceLibrary.all, answers: answers, wish: wish)
        matchedWish = wish.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Roughly what Jev might read from the sample wish: warm, beach, quiet nature, relaxing, around €800.
    static let sampleAnswers: [String: JevAnswer] = [
        "wants_beaches": JevAnswer(levels: [0, 0.05, 0.15, 0.8]),
        "wants_warmth": JevAnswer(levels: [0, 0.05, 0.2, 0.75]),
        "wants_nature": JevAnswer(levels: [0, 0.1, 0.5, 0.4]),
        "wants_relaxation": JevAnswer(levels: [0, 0.05, 0.25, 0.7]),
        "wants_nightlife": JevAnswer(levels: [0.55, 0.4, 0.05, 0]),
        "wants_culture": JevAnswer(levels: [0.05, 0.8, 0.15, 0]),
        "wants_food": JevAnswer(levels: [0, 0.75, 0.25, 0]),
        "wants_adventure": JevAnswer(levels: [0.2, 0.7, 0.1, 0]),
        "trip_length": JevAnswer(choice: "short", probabilities: ["short": 0.85, "weekend": 0.05, "week": 0.05, "long": 0, "unspecified": 0.05]),
        "budget": JevAnswer(choice: "moderate", probabilities: ["moderate": 0.7, "comfortable": 0.2, "tight": 0.05, "luxury": 0, "unspecified": 0.05]),
        "distance": JevAnswer(choice: "unspecified", probabilities: ["unspecified": 0.7, "short": 0.25, "long": 0.05])
    ]
    #endif

    // MARK: Questions

    private static let preferenceLevels = [
        "The traveller wants to avoid this",
        "Not mentioned, or the traveller doesn't mind either way",
        "The traveller would enjoy some of this",
        "This is central to what the traveller wants"
    ]

    private static let budgetOptions: [(key: String, description: String, target: Double?)] = [
        ("tight", "A tight budget: as cheap as possible", 0.2),
        ("moderate", "Budget-conscious, good value matters", 0.45),
        ("comfortable", "A comfortable mid-range budget", 0.7),
        ("luxury", "Money is not a concern, or wants luxury", 1.0),
        ("unspecified", "No budget is mentioned or implied", nil)
    ]

    private static let tripLengths: [(key: String, description: String, days: Double?)] = [
        ("weekend", "A weekend or 2–3 days", 3),
        ("short", "A short trip of about 4–5 days", 4.5),
        ("week", "About a week, 6–8 days", 7),
        ("long", "A long trip of 9 days or more", 10),
        ("unspecified", "Trip length is not mentioned or implied", nil)
    ]

    static func questions(for places: [Place]) -> [String: Any] {
        var questions: [String: Any] = [:]
        for param in PlaceParam.allCases {
            questions["wants_\(param.rawValue)"] = [
                "type": "score",
                "instructions": "\(param.preferenceQuestion), judging only from `traveller_wish`.",
                "criteria": preferenceLevels
            ]
        }
        questions["budget"] = [
            "type": "choice",
            "instructions": "What budget does `traveller_wish` express or imply for the whole trip?",
            "criteria": Dictionary(uniqueKeysWithValues: budgetOptions.map { ($0.key, $0.description) })
        ]
        questions["trip_length"] = [
            "type": "choice",
            "instructions": "How long a trip does `traveller_wish` describe?",
            "criteria": Dictionary(uniqueKeysWithValues: tripLengths.map { ($0.key, $0.description) })
        ]
        questions["distance"] = [
            "type": "choice",
            "instructions": "How far from `home_city` is the traveller willing to go, judging from `traveller_wish`?",
            "criteria": [
                "short": "Wants somewhere close: a short flight, a weekend, or not far away",
                "long": "Happy with a long-haul flight or explicitly wants somewhere far",
                "unspecified": "Distance is not mentioned or implied"
            ]
        ]
        for place in places {
            questions[fitKey(place)] = [
                "type": "noul",
                "instructions": "A trip to this place, starting from `home_city`, would fit what the traveller describes in `traveller_wish`. \(place.matchDescription)"
            ]
        }
        return questions
    }

    /// Question ids stay identifier-like: "fits_sri_lanka".
    private static func fitKey(_ place: Place) -> String {
        "fits_" + place.id.replacingOccurrences(of: "-", with: "_")
    }

    // MARK: Ranking

    static func rank(_ places: [Place], answers: [String: JevAnswer], wish: String) -> [PlaceMatch] {
        let profile = profile(from: answers, wish: wish)
        return places.map { place in
            let reasons = reasons(for: place, profile: profile)
            let traitFit = weightedFit(for: place, profile: profile)
            let overall: Double
            switch (answers[fitKey(place)]?.noul, traitFit) {
            // Jev's holistic answer leads; the trait match it explains keeps the two consistent.
            case let (jev?, traits?): overall = jev * 0.65 + traits * 0.35
            case let (jev?, nil): overall = jev
            case let (nil, traits?): overall = traits
            case (nil, nil): overall = 0
            }
            return PlaceMatch(place: place, fit: min(max(overall, 0), 1), reasons: reasons)
        }
        .sorted { $0.fit > $1.fit }
    }

    static func profile(from answers: [String: JevAnswer], wish: String) -> TravellerProfile {
        var profile = TravellerProfile()
        for param in PlaceParam.allCases {
            if let levels = answers["wants_\(param.rawValue)"]?.levelProbabilities(count: preferenceLevels.count) {
                profile.preferences[param] = levels
            }
        }
        profile.budgetAmount = euroAmount(in: wish)
        if profile.budgetAmount == nil, let budget = answers["budget"], let choice = budget.choice,
           (budget.probabilities[choice] ?? 0) >= 0.4,
           let option = budgetOptions.first(where: { $0.key == choice }), let target = option.target {
            profile.budgetTarget = target
        }
        if let length = answers["trip_length"], let choice = length.choice, (length.probabilities[choice] ?? 0) >= 0.4 {
            profile.tripDays = tripLengths.first { $0.key == choice }?.days
        }
        if let distance = answers["distance"], let choice = distance.choice, (distance.probabilities[choice] ?? 0) >= 0.4 {
            profile.wantsShortFlight = choice == "short" ? true : choice == "long" ? false : nil
        }
        return profile
    }

    /// Jev returns no text, so a named amount ("€800", "800 euros") is read from the wish directly.
    static func euroAmount(in wish: String) -> Int? {
        let number = #"(\d{1,3}(?:[ .,]\d{3})+|\d{2,6})"#
        let patterns = ["(?:€|eur(?:o|os)?)\\s?" + number, number + "\\s?(?:€|eur(?:o|os)?\\b)"]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: wish, range: NSRange(wish.startIndex..., in: wish)),
                  let range = Range(match.range(at: 1), in: wish) else { continue }
            let digits = wish[range].filter(\.isNumber)
            if let amount = Int(digits), (50...50_000).contains(amount) { return amount }
        }
        return nil
    }

    private static func budgetFit(_ place: Place, profile: TravellerProfile) -> Double? {
        // Cheaper than the budget is fine; going over costs fit quickly.
        if let amount = profile.budgetAmount {
            let cheapest = Double(place.cheapestTotal), budget = Double(amount)
            return cheapest <= budget ? 1 : max(0, 1 - (cheapest - budget) / budget)
        }
        if let target = profile.budgetTarget {
            return place.costLevel <= target ? 1 : max(0, 1 - (place.costLevel - target) * 2)
        }
        return nil
    }

    private static func lengthFit(_ place: Place, days: Double) -> Double {
        let closest = place.routes.map { abs(Double($0.dayCount) - days) }.min() ?? days
        return max(0, 1 - closest / 5)
    }

    private static func distanceFit(_ place: Place, short: Bool) -> Double {
        let hours = place.flightHoursFromWarsaw
        return short ? (hours <= 4 ? 1 : max(0, 1 - (hours - 4) / 6)) : (hours >= 6 ? 1 : 0.7)
    }

    private static func weightedFit(for place: Place, profile: TravellerProfile) -> Double? {
        var total = 0.0, weight = 0.0
        for param in PlaceParam.allCases {
            let wants = profile.wants(param), avoids = profile.avoids(param)
            total += wants * place.level(param) + avoids * (1 - place.level(param))
            weight += wants + avoids
        }
        if let budget = budgetFit(place, profile: profile) { total += budget; weight += 1 }
        if let days = profile.tripDays { total += lengthFit(place, days: days); weight += 1 }
        if let short = profile.wantsShortFlight { total += distanceFit(place, short: short); weight += 1 }
        return weight >= 0.5 ? total / weight : nil
    }

    private static func reasons(for place: Place, profile: TravellerProfile) -> [PlaceMatch.Reason] {
        var reasons: [PlaceMatch.Reason] = []
        let wanted = PlaceParam.allCases
            .filter { profile.wants($0) >= 0.5 }
            .sorted { profile.wants($0) * place.level($0) > profile.wants($1) * place.level($1) }
        for param in wanted.prefix(3) {
            let level = place.level(param)
            reasons.append(.init(id: param.rawValue, label: param.label, symbol: param.symbol, fit: level, isWarning: level < 0.4))
        }
        if let fit = budgetFit(place, profile: profile) {
            reasons.append(.init(id: "budget", label: "Budget", symbol: "eurosign", fit: fit, isWarning: fit < 0.5))
        }
        if let days = profile.tripDays {
            let fit = lengthFit(place, days: days)
            reasons.append(.init(id: "length", label: place.dayRange, symbol: "calendar", fit: fit, isWarning: fit < 0.5))
        }
        if let short = profile.wantsShortFlight {
            let fit = distanceFit(place, short: short)
            reasons.append(.init(id: "distance", label: "\(formattedHours(place.flightHoursFromWarsaw)) flight",
                                 symbol: "airplane", fit: fit, isWarning: fit < 0.5))
        }
        if let avoided = PlaceParam.allCases.filter({ profile.avoids($0) >= 0.5 && place.level($0) >= 0.6 })
            .max(by: { place.level($0) < place.level($1) }) {
            reasons.append(.init(id: "avoid-\(avoided.rawValue)", label: "Lots of \(avoided.label.lowercased())",
                                 symbol: avoided.symbol, fit: 1 - place.level(avoided), isWarning: true, showsPercent: false))
        }
        return reasons
    }
}

// MARK: - Jev API

/// One answer from Jev's System One endpoint. Only the fields for the question's type are present.
struct JevAnswer: Decodable {
    var noul: Double?
    var choice: String?
    var score: Double?
    var probabilities: [String: Double] = [:]
    var levels: [Double] = []
    var confidence: Double?

    enum CodingKeys: String, CodingKey { case noul, choice, score, probabilities, confidence }

    init(noul: Double? = nil, choice: String? = nil, score: Double? = nil,
         probabilities: [String: Double] = [:], levels: [Double] = []) {
        self.noul = noul; self.choice = choice; self.score = score
        self.probabilities = probabilities; self.levels = levels
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        noul = try c.decodeIfPresent(Double.self, forKey: .noul)
        choice = try c.decodeIfPresent(String.self, forKey: .choice)
        score = try c.decodeIfPresent(Double.self, forKey: .score)
        confidence = try c.decodeIfPresent(Double.self, forKey: .confidence)
        // Choice answers map option → probability; score answers map level index → probability.
        if let map = try? c.decodeIfPresent([String: Double].self, forKey: .probabilities) {
            probabilities = map
        } else if let list = try? c.decodeIfPresent([Double].self, forKey: .probabilities) {
            levels = list
        }
    }

    /// Per-level probabilities for a score answer, falling back to the weighted-mean score.
    /// Jev keys score probabilities by level index ("0", "1", …); a plain list is accepted too.
    func levelProbabilities(count: Int) -> [Double]? {
        if levels.count == count { return levels }
        let indexed = (0..<count).compactMap { probabilities[String($0)] }
        if indexed.count == count { return indexed }
        guard let score else { return nil }
        let position = min(max(score, 0), Double(count - 1))
        return (0..<count).map { max(0, 1 - abs(Double($0) - position)) }
    }
}

enum JevAPI {
    private struct Response: Decodable { let answers: [String: JevAnswer] }

    static func evaluate(state: [String: Any], questions: [String: Any]) async throws -> [String: JevAnswer] {
        guard let endpoint = AppConfig.jev else { throw MatchError.missingKey }
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(endpoint.key)", forHTTPHeaderField: "authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": endpoint.model,
            "state": state,
            "questions": questions
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let body = json?["detail"] as? [String: Any] ?? json?["error"] as? [String: Any] ?? json
            let message = body?["message"] as? String ?? ""
            throw MatchError.http(status, message)
        }
        guard let decoded = try? JSONDecoder().decode(Response.self, from: data) else { throw MatchError.unreadable }
        return decoded.answers
    }
}
