import Foundation

enum FeedCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case warmth = "Warmth"
    case culture = "Culture"
    case weekend = "Weekend"
    var id: String { rawValue }
}

struct FeedDestination: Identifiable {
    let id: Int
    let name: String
    let country: String
    let artwork: String
    let category: FeedCategory
    let badge: String
    let whyNow: String
    let detail: String
    let travelMinutes: Int
    let estimatedBudget: Int
    let days: Int
}

struct PreviewVisit: Identifiable {
    let id: Int
    let city: String
    let country: String
    let note: String
    let artwork: String
}

enum FeedData {
    static let destinations: [FeedDestination] = [
        FeedDestination(
            id: 0, name: "Madeira", country: "Portugal", artwork: "Madeira", category: .warmth,
            badge: "Nature in season", whyNow: "Mild autumn days and quieter trails.",
            detail: "Green ridges, ocean viewpoints, and levada walks make this a slower nature escape.",
            travelMinutes: 330, estimatedBudget: 720, days: 4
        ),
        FeedDestination(
            id: 1, name: "Rome", country: "Italy", artwork: "Rome", category: .culture,
            badge: "Autumn culture", whyNow: "Long walks, softer light, and a full October calendar.",
            detail: "A city break for art, old streets, and unhurried meals between sights.",
            travelMinutes: 150, estimatedBudget: 560, days: 3
        ),
        FeedDestination(
            id: 2, name: "Copenhagen", country: "Denmark", artwork: "Copenhagen", category: .weekend,
            badge: "Easy city break", whyNow: "Golden parks, design stops, and cosy cafés.",
            detail: "A compact weekend of waterfront walks, museums, and neighbourhood cafés.",
            travelMinutes: 120, estimatedBudget: 630, days: 3
        )
    ]

    static let previewVisits: [PreviewVisit] = [
        PreviewVisit(id: 0, city: "Lisbon", country: "Portugal", note: "Coastal days", artwork: "Lisbon"),
        PreviewVisit(id: 1, city: "Rome", country: "Italy", note: "Art and streets", artwork: "Rome"),
        PreviewVisit(id: 2, city: "Tokyo", country: "Japan", note: "A longer journey", artwork: "Tokyo")
    ]
}
