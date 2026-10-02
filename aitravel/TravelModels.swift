import Foundation

struct TravelOption: Equatable {
    let title: String
    let reason: String
    let visitMinutes: Int
    let price: Int
    let roadDelta: Int
}

struct TravelStop: Identifiable {
    let id: Int
    let title: String
    let reason: String
    let visitMinutes: Int
    let price: Int
    let transferMinutes: Int
    let transferTitle: String
    let transferCost: Int
    let alternatives: [TravelOption]

    var originalOption: TravelOption {
        TravelOption(title: title, reason: reason, visitMinutes: visitMinutes, price: price, roadDelta: 0)
    }

    var allOptions: [TravelOption] {
        if alternatives.isEmpty {
            return [
                originalOption,
                TravelOption(title: "A quieter nearby stop", reason: "A slower local alternative", visitMinutes: visitMinutes + 30, price: 0, roadDelta: transferMinutes > 0 ? -10 : 0),
                TravelOption(title: "Guided local experience", reason: "More context with a local guide", visitMinutes: visitMinutes, price: price + 25, roadDelta: transferMinutes > 0 ? 5 : 0)
            ]
        }
        return [originalOption] + alternatives
    }
}

struct CostBreakdown {
    let destinationTravel: Int
    let stay: Int
    let localTransport: Int
    let visits: Int
}

struct TravelRoute: Identifiable {
    let id: Int
    let badge: String
    let name: String
    let place: String
    let headline: String
    let reason: String
    let artwork: String
    let estimatedTotal: Int
    let travelMinutes: Int
    let visitMinutes: Int
    let costs: CostBreakdown
    let dayTitle: String
    let dayNote: String
    let stops: [TravelStop]
}

struct DayPlan {
    let title: String
    let note: String
    let startMinute: Int
    let stops: [TravelStop]
}

struct PlanChange {
    var price = 0
    var roadMinutes = 0
    var visitMinutes = 0
}

enum TravelData {
    static let sampleWish = "I want four days somewhere warm. A beautiful beach, quiet nature, and time to relax. Start from Warsaw. Keep it around €800 per person."

    static let routes: [TravelRoute] = [
        TravelRoute(
            id: 0, badge: "Easiest journey", name: "Easy coast", place: "Algarve",
            headline: "Sea, lagoon, slow afternoons.",
            reason: "The shortest travel day, with gentle beaches and lagoon nature.",
            artwork: "Algarve", estimatedTotal: 760, travelMinutes: 480, visitMinutes: 1380,
            costs: CostBreakdown(destinationTravel: 352, stay: 270, localTransport: 86, visits: 52),
            dayTitle: "Sea, lagoon, slow afternoon",
            dayNote: "A relaxed loop from Faro to the golden cliffs.",
            stops: [
                TravelStop(id: 0, title: "Ria Formosa nature walk", reason: "Lagoon trails and birdlife", visitMinutes: 120, price: 12, transferMinutes: 55, transferTitle: "Drive to the coast", transferCost: 13, alternatives: [
                    TravelOption(title: "Ludo nature trail", reason: "A quieter walk through the wetlands", visitMinutes: 90, price: 0, roadDelta: -10),
                    TravelOption(title: "Guided lagoon boat", reason: "See the islands from the water", visitMinutes: 90, price: 28, roadDelta: 5)
                ]),
                TravelStop(id: 1, title: "Praia da Marinha", reason: "Beach rest and cliff viewpoint", visitMinutes: 180, price: 0, transferMinutes: 25, transferTitle: "Drive to Carvoeiro", transferCost: 5, alternatives: [
                    TravelOption(title: "Benagil cave boat tour", reason: "A short adventure under the cliffs", visitMinutes: 90, price: 35, roadDelta: 15),
                    TravelOption(title: "Albandeira beach", reason: "A quieter cove for swimming", visitMinutes: 150, price: 0, roadDelta: -10)
                ]),
                TravelStop(id: 2, title: "Carvoeiro boardwalk", reason: "Sea caves and sunset views", visitMinutes: 90, price: 0, transferMinutes: 0, transferTitle: "", transferCost: 0, alternatives: [
                    TravelOption(title: "Seven Hanging Valleys viewpoint", reason: "Sweeping coast from above", visitMinutes: 90, price: 0, roadDelta: 0),
                    TravelOption(title: "Benagil village stroll", reason: "A slow finish by the water", visitMinutes: 60, price: 0, roadDelta: 0)
                ])
            ]
        ),
        TravelRoute(
            id: 1, badge: "Most nature", name: "Wild coast", place: "Costa Vicentina",
            headline: "Where the cliffs feel endless.",
            reason: "Longer drives lead to quiet coves, open trails, and wilder scenery.",
            artwork: "Costa", estimatedTotal: 810, travelMinutes: 660, visitMinutes: 1410,
            costs: CostBreakdown(destinationTravel: 380, stay: 265, localTransport: 110, visits: 55),
            dayTitle: "Cliff paths and hidden coves",
            dayNote: "A nature-first day along the western shore.",
            stops: [
                TravelStop(id: 0, title: "Carrapateira dune trail", reason: "Wide views over dunes and sea", visitMinutes: 150, price: 0, transferMinutes: 45, transferTitle: "Drive to Praia do Amado", transferCost: 12, alternatives: [
                    TravelOption(title: "Bordeira beach walk", reason: "More beach, fewer climbs", visitMinutes: 120, price: 0, roadDelta: -10),
                    TravelOption(title: "Guided birdwatching walk", reason: "A closer look at coastal wildlife", visitMinutes: 120, price: 26, roadDelta: 5)
                ]),
                TravelStop(id: 1, title: "Praia do Amado", reason: "Surf beach and a picnic stop", visitMinutes: 150, price: 0, transferMinutes: 50, transferTitle: "Drive to Sagres", transferCost: 14, alternatives: [
                    TravelOption(title: "Praia da Bordeira", reason: "An open, peaceful shoreline", visitMinutes: 150, price: 0, roadDelta: -15),
                    TravelOption(title: "Guided cliff hike", reason: "A deeper look at the wild coast", visitMinutes: 180, price: 30, roadDelta: 10)
                ]),
                TravelStop(id: 2, title: "Sagres headland", reason: "Big Atlantic views at dusk", visitMinutes: 120, price: 5, transferMinutes: 0, transferTitle: "", transferCost: 0, alternatives: [
                    TravelOption(title: "Beliche viewpoint", reason: "Clifftop sunset without the crowds", visitMinutes: 90, price: 0, roadDelta: 0),
                    TravelOption(title: "Fortress of Sagres", reason: "History at the edge of the land", visitMinutes: 120, price: 8, roadDelta: 0)
                ])
            ]
        ),
        TravelRoute(
            id: 2, badge: "Best value", name: "Quiet shores", place: "Eastern Algarve",
            headline: "A little more room to breathe.",
            reason: "Lower stay costs and slower island beaches, with a few extra transfers.",
            artwork: "Tavira", estimatedTotal: 690, travelMinutes: 600, visitMinutes: 1410,
            costs: CostBreakdown(destinationTravel: 330, stay: 225, localTransport: 95, visits: 40),
            dayTitle: "Island sand and old streets",
            dayNote: "A gentle day around Tavira and its barrier islands.",
            stops: [
                TravelStop(id: 0, title: "Tavira old town", reason: "Quiet lanes, tiled facades, and coffee", visitMinutes: 120, price: 0, transferMinutes: 30, transferTitle: "Ferry to Ilha de Tavira", transferCost: 4, alternatives: [
                    TravelOption(title: "Cacela Velha village", reason: "A tiny hilltop with sea views", visitMinutes: 90, price: 0, roadDelta: 15),
                    TravelOption(title: "Tavira market and museum", reason: "Food stalls and local history", visitMinutes: 120, price: 8, roadDelta: 0)
                ]),
                TravelStop(id: 1, title: "Ilha de Tavira", reason: "Long sandy beach and easy swimming", visitMinutes: 210, price: 0, transferMinutes: 30, transferTitle: "Ferry back to Tavira", transferCost: 4, alternatives: [
                    TravelOption(title: "Barril beach", reason: "A quieter shore with an easy train ride", visitMinutes: 180, price: 4, roadDelta: -10),
                    TravelOption(title: "Ria Formosa ferry tour", reason: "More lagoon, less beach time", visitMinutes: 120, price: 24, roadDelta: 20)
                ]),
                TravelStop(id: 2, title: "Salt pans at sunset", reason: "Flamingos and soft evening light", visitMinutes: 90, price: 0, transferMinutes: 0, transferTitle: "", transferCost: 0, alternatives: [
                    TravelOption(title: "Tavira riverside", reason: "A slow walk before dinner", visitMinutes: 90, price: 0, roadDelta: 0),
                    TravelOption(title: "Guided salt pan visit", reason: "Learn how the landscape works", visitMinutes: 90, price: 15, roadDelta: 0)
                ])
            ]
        )
    ]

    static let sharedDays: [Int: DayPlan] = [
        1: DayPlan(title: "Arrive and settle in", note: "A light first day after the journey.", startMinute: 660, stops: [
            TravelStop(id: 0, title: "Arrive in Faro", reason: "Airport to your base", visitMinutes: 60, price: 0, transferMinutes: 25, transferTitle: "Transfer to your stay", transferCost: 12, alternatives: []),
            TravelStop(id: 1, title: "Old town wander", reason: "Get your bearings at your own pace", visitMinutes: 120, price: 0, transferMinutes: 15, transferTitle: "Walk to dinner", transferCost: 0, alternatives: []),
            TravelStop(id: 2, title: "First evening by the water", reason: "A calm start to the trip", visitMinutes: 90, price: 0, transferMinutes: 0, transferTitle: "", transferCost: 0, alternatives: [])
        ]),
        3: DayPlan(title: "Follow the coast", note: "A full day with time left to linger.", startMinute: 540, stops: [
            TravelStop(id: 0, title: "Clifftop morning walk", reason: "Sea air and open views", visitMinutes: 150, price: 0, transferMinutes: 40, transferTitle: "Local drive", transferCost: 10, alternatives: []),
            TravelStop(id: 1, title: "Coastal village lunch", reason: "A long pause between places", visitMinutes: 120, price: 0, transferMinutes: 35, transferTitle: "Drive to the beach", transferCost: 9, alternatives: []),
            TravelStop(id: 2, title: "Afternoon by the sea", reason: "Swim, read, or do very little", visitMinutes: 180, price: 0, transferMinutes: 0, transferTitle: "", transferCost: 0, alternatives: [])
        ]),
        4: DayPlan(title: "One last look", note: "A gentle goodbye before heading home.", startMinute: 540, stops: [
            TravelStop(id: 0, title: "Morning market", reason: "Coffee and a few local finds", visitMinutes: 90, price: 0, transferMinutes: 25, transferTitle: "Travel to the airport", transferCost: 12, alternatives: []),
            TravelStop(id: 1, title: "Homeward journey", reason: "Leave with time to spare", visitMinutes: 180, price: 0, transferMinutes: 0, transferTitle: "", transferCost: 0, alternatives: [])
        ])
    ]

    static func day(_ number: Int, for route: TravelRoute) -> DayPlan {
        if number == 2 {
            return DayPlan(title: route.dayTitle, note: route.dayNote, startMinute: 540, stops: route.stops)
        }
        return sharedDays[number] ?? sharedDays[1]!
    }
}

func formattedDuration(_ minutes: Int) -> String {
    let hours = minutes / 60
    let rest = minutes % 60
    if hours == 0 { return "\(rest)m" }
    return rest == 0 ? "\(hours)h" : "\(hours)h \(rest)m"
}

func formattedTime(_ minutes: Int) -> String {
    String(format: "%02d:%02d", minutes / 60, minutes % 60)
}

func euro(_ amount: Int) -> String { "€\(amount)" }
