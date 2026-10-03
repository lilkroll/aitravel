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

enum MapActivityMode: String, CaseIterable, Identifiable {
    case mine = "You"
    case everyone = "Everyone"
    var id: String { rawValue }
}

struct ActivitySpot: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    /// Visits for "You", sample travellers per month (in hundreds) for "Everyone".
    let weight: Int
}

/// Equirectangular land mask from Natural Earth 110m land, latitude 78° N to 56° S.
/// `#` is land, `.` is ocean. Each cell is 3.75° of longitude by 3.35° of latitude.
enum WorldGrid {
    static let columns = 96
    static let rows = 40
    static let maxLatitude = 78.0
    static let minLatitude = -56.0

    static func cell(latitude: Double, longitude: Double) -> (row: Int, column: Int) {
        let column = Int((longitude + 180) / 360 * Double(columns))
        let row = Int((maxLatitude - latitude) / (maxLatitude - minLatitude) * Double(rows))
        return (min(max(row, 0), rows - 1), min(max(column, 0), columns - 1))
    }

    static let land: [[Bool]] = mask.map { $0.map { $0 == "#" } }

    private static let mask: [String] = [
        "................####.#..###...#############.....................#.......######.......#..........",
        "...............####..#######.....#########....................#......#############...###........",
        "....################...#######....#######............#####......#.###########################.##",
        "##..######################..###...#####...##.......#############################################",
        "....####################..##.##...###.............#############################################.",
        "....####.##############....###...................####.###################################..##...",
        ".............############..#####..............##..##.################################....##.....",
        "..............############.######............###.#####################################...#......",
        "..............###################..............#######################################..........",
        "...............#################.#.............######################################...........",
        "...............##############.................####.#####...#########################..#.........",
        "...............#############.................###....##.#########################.#...#..........",
        "................############..................#####.....########################..#.##..........",
        ".................##########...................######.....#######################................",
        ".................#######.##..................####################################...............",
        "..................####......................#############.######################................",
        "....................##.....................#####################..#############.................",
        "....................##..#...##.............###############.####....####..####...................",
        "......................####.................###################......##...####...#...............",
        "........................##.................#################........##....###...................",
        ".........................#.#####............##################......#...........................",
        "...........................#######...........################..................#................",
        "...........................########...............##########..............##.###................",
        "..........................##########..............#########................#.##....#............",
        "..........................############.............########................#....#.#.###.........",
        "...........................############............########.................#.#......###........",
        "...........................###########.............########.....................................",
        "............................##########.............########..#....................##..#.........",
        ".............................#########.............#######..#....................######.........",
        ".............................########..............#######..#..................#########........",
        ".............................#######................#####...#.................##########........",
        ".............................######.................#####.....................###########.......",
        ".............................######..................###.......................##########.......",
        ".............................#####...................##........................##....###........",
        "............................#####.....................................................##........",
        "............................###...............................................................#.",
        "............................##...............................................................#..",
        "............................##..................................................................",
        "............................##..................................................................",
        ".............................#..................................................................",
    ]
}

enum MapActivityData {
    static let mine: [ActivitySpot] = [
        ActivitySpot(name: "Lisbon", latitude: 38.72, longitude: -9.14, weight: 3),
        ActivitySpot(name: "Rome", latitude: 41.90, longitude: 12.50, weight: 2),
        ActivitySpot(name: "Tokyo", latitude: 35.68, longitude: 139.69, weight: 1)
    ]

    static let everyone: [ActivitySpot] = [
        ActivitySpot(name: "Lisbon", latitude: 38.72, longitude: -9.14, weight: 9),
        ActivitySpot(name: "Barcelona", latitude: 41.39, longitude: 2.17, weight: 11),
        ActivitySpot(name: "Paris", latitude: 48.86, longitude: 2.35, weight: 14),
        ActivitySpot(name: "London", latitude: 51.51, longitude: -0.13, weight: 10),
        ActivitySpot(name: "Rome", latitude: 41.90, longitude: 12.50, weight: 9),
        ActivitySpot(name: "Copenhagen", latitude: 55.68, longitude: 12.57, weight: 6),
        ActivitySpot(name: "Reykjavík", latitude: 64.15, longitude: -21.94, weight: 4),
        ActivitySpot(name: "Madeira", latitude: 32.65, longitude: -16.91, weight: 5),
        ActivitySpot(name: "Athens", latitude: 37.98, longitude: 23.73, weight: 7),
        ActivitySpot(name: "Istanbul", latitude: 41.01, longitude: 28.98, weight: 8),
        ActivitySpot(name: "Marrakech", latitude: 31.63, longitude: -7.99, weight: 6),
        ActivitySpot(name: "Cairo", latitude: 30.04, longitude: 31.24, weight: 5),
        ActivitySpot(name: "Cape Town", latitude: -33.92, longitude: 18.42, weight: 5),
        ActivitySpot(name: "Zanzibar", latitude: -6.16, longitude: 39.20, weight: 3),
        ActivitySpot(name: "Dubai", latitude: 25.20, longitude: 55.27, weight: 8),
        ActivitySpot(name: "Mumbai", latitude: 19.08, longitude: 72.88, weight: 4),
        ActivitySpot(name: "Kathmandu", latitude: 27.72, longitude: 85.32, weight: 3),
        ActivitySpot(name: "Bangkok", latitude: 13.76, longitude: 100.50, weight: 9),
        ActivitySpot(name: "Bali", latitude: -8.34, longitude: 115.09, weight: 8),
        ActivitySpot(name: "Singapore", latitude: 1.35, longitude: 103.82, weight: 6),
        ActivitySpot(name: "Hanoi", latitude: 21.03, longitude: 105.85, weight: 5),
        ActivitySpot(name: "Seoul", latitude: 37.57, longitude: 126.98, weight: 6),
        ActivitySpot(name: "Tokyo", latitude: 35.68, longitude: 139.69, weight: 13),
        ActivitySpot(name: "Sydney", latitude: -33.87, longitude: 151.21, weight: 6),
        ActivitySpot(name: "Queenstown", latitude: -45.03, longitude: 168.66, weight: 3),
        ActivitySpot(name: "New York", latitude: 40.71, longitude: -74.01, weight: 12),
        ActivitySpot(name: "Los Angeles", latitude: 34.05, longitude: -118.24, weight: 7),
        ActivitySpot(name: "Vancouver", latitude: 49.28, longitude: -123.12, weight: 4),
        ActivitySpot(name: "Mexico City", latitude: 19.43, longitude: -99.13, weight: 6),
        ActivitySpot(name: "Cancún", latitude: 21.16, longitude: -86.85, weight: 7),
        ActivitySpot(name: "Lima", latitude: -12.05, longitude: -77.04, weight: 3),
        ActivitySpot(name: "Rio de Janeiro", latitude: -22.91, longitude: -43.17, weight: 6),
        ActivitySpot(name: "Buenos Aires", latitude: -34.60, longitude: -58.38, weight: 4),
        ActivitySpot(name: "Patagonia", latitude: -50.34, longitude: -72.26, weight: 2)
    ]

    static func spots(for mode: MapActivityMode) -> [ActivitySpot] {
        mode == .mine ? mine : everyone
    }

    /// Activity level 0–4 for every land cell, like a contribution graph.
    /// Your visits light a cell with a faint halo; everyone's activity spreads to nearby land.
    static func levels(for mode: MapActivityMode) -> [[Int]] {
        var heat = Array(repeating: Array(repeating: 0.0, count: WorldGrid.columns), count: WorldGrid.rows)
        let radius = mode == .mine ? 1 : 3
        for spot in spots(for: mode) {
            let center = WorldGrid.cell(latitude: spot.latitude, longitude: spot.longitude)
            for dr in -radius...radius {
                for dc in -radius...radius {
                    let row = center.row + dr, column = center.column + dc
                    guard heat.indices.contains(row), heat[row].indices.contains(column) else { continue }
                    let distance = Double(max(abs(dr), abs(dc)))
                    // Your visits keep a faint halo; everyone's activity fades out gradually.
                    let falloff = mode == .mine ? (distance == 0 ? 1 : 0.15) : 1 / (1 + distance * distance)
                    heat[row][column] += Double(spot.weight) * falloff
                }
            }
        }
        let peak = heat.joined().max() ?? 1
        return heat.enumerated().map { row, values in
            values.enumerated().map { column, value in
                guard value > 0 else { return 0 }
                let isSpot = spots(for: mode).contains { spot in
                    let cell = WorldGrid.cell(latitude: spot.latitude, longitude: spot.longitude)
                    return cell.row == row && cell.column == column
                }
                guard WorldGrid.land[row][column] || isSpot else { return 0 }
                return min(4, max(1, Int((sqrt(value / peak) * 4).rounded(.up))))
            }
        }
    }
}
