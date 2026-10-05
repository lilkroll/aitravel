import SwiftUI

/// The traits every place is rated on (0–1, for October–November) and Jev asks the traveller about.
enum PlaceParam: String, CaseIterable, Identifiable, Codable {
    case beaches, nature, culture, food, nightlife, adventure, relaxation, warmth
    var id: String { rawValue }

    var label: String {
        switch self {
        case .beaches: "Beaches"
        case .nature: "Nature"
        case .culture: "Culture"
        case .food: "Food"
        case .nightlife: "Nightlife"
        case .adventure: "Adventure"
        case .relaxation: "Slow pace"
        case .warmth: "Warm weather"
        }
    }

    var symbol: String {
        switch self {
        case .beaches: "beach.umbrella"
        case .nature: "leaf"
        case .culture: "building.columns"
        case .food: "fork.knife"
        case .nightlife: "moon.stars"
        case .adventure: "figure.hiking"
        case .relaxation: "cup.and.saucer"
        case .warmth: "sun.max"
        }
    }

    /// What Jev is asked to judge in the traveller's wish.
    var preferenceQuestion: String {
        switch self {
        case .beaches: "How much the traveller wants beaches, swimming, and time by the sea"
        case .nature: "How much the traveller wants nature: landscapes, hiking, wildlife, national parks"
        case .culture: "How much the traveller wants culture: history, museums, temples, old towns, architecture"
        case .food: "How much the traveller wants food and eating out to be a highlight of the trip"
        case .nightlife: "How much the traveller wants nightlife: bars, clubs, parties, late evenings out"
        case .adventure: "How much the traveller wants active adventure: diving, surfing, trekking, road trips"
        case .relaxation: "How much the traveller wants a slow, restful pace with time to do very little"
        case .warmth: "How much the traveller wants warm or hot weather"
        }
    }
}

struct Place: Identifiable {
    let id: String
    let name: String
    let region: String
    let tagline: String
    let summary: String
    let highlights: [String]
    let bestMonths: String
    let october: String
    let flightHoursFromWarsaw: Double
    let dailyBudget: Int
    let categories: [FeedCategory]
    let params: [PlaceParam: Double]
    let costLevel: Double
    let palette: [String]
    let symbol: String
    let artwork: String
    let latitude: Double
    let longitude: Double
    let routes: [TravelRoute]

    func level(_ param: PlaceParam) -> Double { params[param] ?? 0 }

    var cheapestTotal: Int { routes.map(\.estimatedTotal).min() ?? 0 }

    var dayRange: String {
        let counts = routes.map(\.dayCount)
        guard let low = counts.min(), let high = counts.max() else { return "" }
        return low == high ? "\(low) days" : "\(low)–\(high) days"
    }

    var gradient: LinearGradient {
        LinearGradient(colors: palette.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// The text Jev reads when judging whether this place fits a wish.
    var matchDescription: String {
        let strengths = PlaceParam.allCases.filter { level($0) >= 0.7 }.map { $0.label.lowercased() }
        return """
        \(name) (\(region)): \(summary) Highlights: \(highlights.joined(separator: "; ")). \
        Strong for: \(strengths.joined(separator: ", ")). October–November: \(october) \
        About \(formattedHours(flightHoursFromWarsaw)) from Warsaw by air. Trips of \(dayRange) from about \
        €\(cheapestTotal) per person including flights; around €\(dailyBudget) a day on the ground.
        """
    }

}

enum PlaceLibrary {
    /// The 20 bundled places from `Places.json`.
    static let all: [Place] = {
        guard let url = Bundle.main.url(forResource: "Places", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        do {
            return try JSONDecoder().decode([PlaceDTO].self, from: data).enumerated().map { $1.place(index: $0) }
        } catch {
            assertionFailure("Places.json failed to decode: \(error)")
            return []
        }
    }()

    static func place(id: String) -> Place? { all.first { $0.id == id } }

    static func place(containing routeID: Int) -> Place? { all.first { $0.routes.contains { $0.id == routeID } } }
}

private struct PlaceDTO: Decodable {
    let id, name, region, tagline, summary: String
    let highlights: [String]
    let bestMonths, october: String
    let flightHoursFromWarsaw: Double
    let dailyBudget: Int
    let categories: [String]
    let params: [String: Double]
    let costLevel: Double
    let palette: [String]
    let symbol, artwork: String
    let latitude, longitude: Double
    let routes: [PlaceRouteDTO]

    func place(index: Int) -> Place {
        Place(
            id: id, name: name, region: region, tagline: tagline, summary: summary, highlights: highlights,
            bestMonths: bestMonths, october: october, flightHoursFromWarsaw: flightHoursFromWarsaw,
            dailyBudget: dailyBudget, categories: categories.compactMap(FeedCategory.init(dataValue:)),
            params: Dictionary(uniqueKeysWithValues: params.compactMap { key, value in PlaceParam(rawValue: key).map { ($0, value) } }),
            costLevel: costLevel, palette: palette, symbol: symbol, artwork: artwork,
            latitude: latitude, longitude: longitude,
            // Unique ids clear of the sample routes (0–2) and generated plans (timestamps).
            routes: routes.enumerated().map { $1.route(id: 1_000 + index * 100 + $0) }
        )
    }
}

private struct PlaceRouteDTO: Decodable {
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

    let badge, name, place, headline, reason, artwork: String
    let travelMinutes: Int
    let costs: Costs
    let days: [Day]

    func route(id: Int) -> TravelRoute {
        let days = days.map { day in
            DayPlan(title: day.title, note: day.note, startMinute: day.startMinute, stops: day.stops.enumerated().map { index, stop in
                TravelStop(id: index, title: stop.title, reason: stop.reason, visitMinutes: stop.visitMinutes,
                           price: stop.price, transferMinutes: stop.transferMinutes, transferTitle: stop.transferTitle,
                           transferCost: stop.transferCost, alternatives: stop.alternatives.map {
                               TravelOption(title: $0.title, reason: $0.reason, visitMinutes: $0.visitMinutes, price: $0.price, roadDelta: $0.roadDelta)
                           })
            })
        }
        let breakdown = CostBreakdown(destinationTravel: costs.destinationTravel, stay: costs.stay,
                                      localTransport: costs.localTransport, visits: costs.visits)
        let anchor = days.count > 1 ? days[1] : days.first
        return TravelRoute(
            id: id, badge: badge, name: name, place: place, headline: headline, reason: reason, artwork: artwork,
            estimatedTotal: costs.destinationTravel + costs.stay + costs.localTransport + costs.visits,
            travelMinutes: travelMinutes,
            visitMinutes: days.flatMap(\.stops).reduce(0) { $0 + $1.visitMinutes },
            costs: breakdown, dayTitle: anchor?.title ?? "", dayNote: anchor?.note ?? "",
            stops: anchor?.stops ?? [], days: days
        )
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}

func formattedHours(_ hours: Double) -> String {
    formattedDuration(Int((hours * 60).rounded()))
}
