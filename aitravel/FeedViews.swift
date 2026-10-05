import SwiftUI

/// A contribution-graph style world map: land is a grid of rounded squares,
/// shaded by how much travel happened there.
struct DotWorldMap: View {
    let mode: MapActivityMode

    private static let levels: [MapActivityMode: [[Int]]] = Dictionary(
        uniqueKeysWithValues: MapActivityMode.allCases.map { ($0, MapActivityData.levels(for: $0)) }
    )

    var body: some View {
        let levels = Self.levels[mode] ?? []
        Canvas { context, size in
            let step = size.width / CGFloat(WorldGrid.columns)
            let side = step * 0.78
            for row in 0..<WorldGrid.rows {
                for column in 0..<WorldGrid.columns {
                    let level = levels[row][column]
                    guard WorldGrid.land[row][column] || level > 0 else { continue }
                    let rect = CGRect(x: CGFloat(column) * step + (step - side) / 2,
                                      y: CGFloat(row) * step + (step - side) / 2,
                                      width: side, height: side)
                    context.fill(Path(roundedRect: rect, cornerRadius: side * 0.28),
                                 with: .color(ActivityShade.color(level)))
                }
            }
        }
        .aspectRatio(CGFloat(WorldGrid.columns) / CGFloat(WorldGrid.rows), contentMode: .fit)
        .animation(.easeInOut(duration: 0.25), value: mode)
        .accessibilityElement()
        .accessibilityLabel(mode == .mine
            ? "Your sample visits: Lisbon, Rome, and Tokyo"
            : "Sample activity from other travellers, busiest around Europe, Southeast Asia, and North America")
    }
}

enum ActivityShade {
    static func color(_ level: Int) -> Color {
        switch level {
        case 0: Color(uiColor: .systemGray5)
        case 1: Palette.accent.opacity(0.28)
        case 2: Palette.accent.opacity(0.5)
        case 3: Palette.accent.opacity(0.75)
        default: Palette.accent
        }
    }
}

struct ActivityLegend: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Less").padding(.trailing, 2)
            ForEach(0..<5) { level in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(ActivityShade.color(level))
                    .frame(width: 10, height: 10)
            }
            Text("More").padding(.leading, 2)
        }
        .font(.caption2)
        .foregroundStyle(Palette.muted)
        .accessibilityHidden(true)
    }
}

struct ActivityModePicker: View {
    @Binding var mode: MapActivityMode

    var body: some View {
        Picker("Show", selection: $mode.animation(.easeInOut(duration: 0.25))) {
            ForEach(MapActivityMode.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }
}

extension MapActivityMode {
    var summary: String {
        switch self {
        case .mine: "3 countries · 6 visits"
        case .everyone: "34 hotspots · 30 countries"
        }
    }
}

struct WorldMapCard: View {
    @Binding var mode: MapActivityMode
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .mine ? "Your world" : "Where people go")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Palette.text)
                        Text(mode.summary)
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                            .contentTransition(.opacity)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.text)
                        .frame(width: 34, height: 34)
                        .background(Palette.background, in: Circle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open travel map")
            ActivityModePicker(mode: $mode)
                .padding(.top, 14)
            Button(action: action) {
                DotWorldMap(mode: mode)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            HStack {
                Text("Sample activity")
                Spacer()
                ActivityLegend()
            }
            .font(.caption2)
            .foregroundStyle(Palette.muted)
            .padding(.top, 12)
        }
        .padding(18)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct PlaceFeatureCard: View {
    let place: Place
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                CoastImage(name: place.artwork, height: 180, placeholder: place.gradient, symbol: place.symbol)
                    .overlay(alignment: .topLeading) {
                        Text(place.region)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.text)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Palette.surface.opacity(0.94), in: Capsule())
                            .padding(13)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(place.name)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.28), radius: 8)
                            .padding(16)
                    }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(place.routes.count) ROUTES · \(place.dayRange.uppercased())")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Palette.muted)
                            Text(place.tagline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Palette.text)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 10)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                    }
                    PlaceFigures(place: place)
                        .padding(.top, 13)
                }
                .padding(15)
            }
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 21))
        }
        .buttonStyle(.plain)
    }
}

struct PlaceCompactCard: View {
    let place: Place
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                CoastImage(name: place.artwork, height: 132, placeholder: place.gradient, symbol: place.symbol)
                    .frame(width: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 0) {
                    Text(place.region)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.muted)
                    Text(place.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Palette.text)
                        .padding(.top, 4)
                    Text(place.tagline)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .padding(.top, 4)
                    Spacer(minLength: 3)
                    HStack(spacing: 7) {
                        Text("\(place.routes.count) routes")
                        Text("·")
                        Text("from ~\(euro(place.cheapestTotal))")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

struct PlaceFigures: View {
    let place: Place

    var body: some View {
        HStack(spacing: 0) {
            Label("~\(formattedHours(place.flightHoursFromWarsaw)) flight", systemImage: "airplane")
            Spacer()
            Text("from ~\(euro(place.cheapestTotal)) · \(place.dayRange)")
                .fontWeight(.bold)
        }
        .font(.system(size: 12))
        .foregroundStyle(Palette.accent)
        .padding(.top, 11)
        .overlay(alignment: .top) { Palette.separator.frame(height: 1) }
    }
}

struct PlaceSheet: View {
    let place: Place
    let isSaved: Bool
    let toggleSaved: () -> Void
    let openRoute: (TravelRoute) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                CoastImage(name: place.artwork, height: UIImage(named: place.artwork) == nil ? 130 : 225,
                           placeholder: place.gradient, symbol: place.symbol)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                if let credit = PhotoCredits.credit(for: place.artwork) {
                    Link("Photo by \(credit.photographer) · \(credit.license)", destination: URL(string: credit.sourceURL)!)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .padding(.top, 8)
                }
                Kicker(text: place.region)
                    .padding(.top, 16)
                Text(place.name)
                    .font(.system(size: 39, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .padding(.top, 6)
                Text(place.tagline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.text)
                    .padding(.top, 4)
                Text(place.summary)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 10)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(place.highlights, id: \.self) { highlight in
                        HStack(alignment: .firstTextBaseline, spacing: 9) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Palette.accent)
                            Text(highlight)
                                .foregroundStyle(Palette.text)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(.top, 16)
                Label(place.october, systemImage: "calendar")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 16)
                PlaceFigures(place: place)
                    .padding(.top, 18)
                Kicker(text: "\(place.routes.count) ways to go")
                    .padding(.top, 26).padding(.bottom, 12)
                ForEach(place.routes) { route in
                    RouteCard(route: route, total: route.estimatedTotal, travel: route.travelMinutes, visits: route.visitMinutes) {
                        openRoute(route)
                    }
                    .padding(.bottom, 12)
                }
                Text("Ready-made routes with per-person EUR estimates from Warsaw for autumn 2026. Not live fares or availability.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 2)
                Button(action: toggleSaved) {
                    Label(isSaved ? "Saved to your ideas" : "Save this place", systemImage: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 35)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .presentationBackground(Palette.background)
    }
}

struct TravelMapSheet: View {
    @Binding var mode: MapActivityMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "Travel journal")
                Text(mode == .mine ? "Your world, so far." : "Where people go.")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Palette.text).padding(.top, 7)
                Text(mode == .mine
                     ? "Every square you light up is a place you\u{2019}ve been."
                     : "Brighter squares are where other travellers are heading.")
                    .font(.system(size: 14)).foregroundStyle(Palette.muted)
                    .padding(.top, 5)
                ActivityModePicker(mode: $mode)
                    .padding(.top, 20)
                VStack(alignment: .leading, spacing: 12) {
                    DotWorldMap(mode: mode)
                    HStack {
                        Label(mode.summary, systemImage: "globe.europe.africa")
                        Spacer()
                        ActivityLegend()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.muted)
                }
                .padding(16)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
                .padding(.top, 16)
                Kicker(text: mode == .mine ? "Sample places" : "Trending this month")
                    .padding(.top, 26).padding(.bottom, 10)
                if mode == .mine {
                    ForEach(FeedData.previewVisits) { visit in
                        HStack(spacing: 12) {
                            Image(visit.artwork)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(visit.city).font(.system(size: 15, weight: .bold))
                                Text("\(visit.country) · \(visit.note)")
                                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                        }
                        .padding(13)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.separator))
                        .padding(.bottom, 8)
                    }
                } else {
                    let trending = MapActivityData.everyone.sorted { $0.weight > $1.weight }.prefix(6)
                    ForEach(Array(trending.enumerated()), id: \.element.id) { index, spot in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Palette.accent)
                                .frame(width: 36, height: 36)
                                .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 9))
                            Text(spot.name).font(.system(size: 15, weight: .bold))
                            Spacer()
                            Text("~\(spot.weight * 100) travellers")
                                .font(.system(size: 12)).foregroundStyle(Palette.muted)
                        }
                        .padding(11)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.separator))
                        .padding(.bottom, 8)
                    }
                }
                Text(mode == .mine
                     ? "This map uses example visits. It is not connected to your travel history yet."
                     : "Community activity is illustrative sample data, not real traveller counts.")
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .padding(.top, 7)
            }
            .padding(.horizontal, 24).padding(.top, 34).padding(.bottom, 30)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .presentationBackground(Palette.background)
    }

}

struct TravelProfileSheet: View {
    @State private var showPhotoCredits = false
    @State private var showKeySheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(Palette.accent)
                    Spacer()
                    Button { showPhotoCredits = true } label: {
                        Label("Photo credits", systemImage: "photo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                    }
                    .padding(.top, 9)
                }
                Kicker(text: "Travel profile")
                    .padding(.top, 18)
                Text("A place for your kind of travel.")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .padding(.top, 7)
                Text("Your origin, preferences, and visited places will help shape future suggestions.")
                    .font(.system(size: 15)).foregroundStyle(Palette.muted)
                    .padding(.top, 9)
                profileRow("Starting from", "Warsaw", "location.fill")
                    .padding(.top, 26)
                profileRow("Travel style", "Sea + nature", "sparkles")
                profileRow("Usual escape", "3–4 days", "calendar")
                Button { showKeySheet = true } label: {
                    profileRow("Smart matching", AppConfig.jev != nil && AppConfig.miniMaxAPIKey != nil ? "Connected" : "Set up keys", "sparkles")
                }
                .buttonStyle(.plain)
                Text("Example profile settings for this visual mock.")
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .padding(.top, 15)
            }
            .padding(.horizontal, 24).padding(.top, 34).padding(.bottom, 30)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.background)
        .sheet(isPresented: $showPhotoCredits) { PhotoCreditsSheet() }
        .sheet(isPresented: $showKeySheet) {
            KeySetupSheet()
        }
    }

    private func profileRow(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(Palette.accent)
                .frame(width: 22)
            Text(title).font(.system(size: 14)).foregroundStyle(Palette.muted)
            Spacer()
            Text(value).font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.text)
        }
        .padding(.vertical, 15)
        .overlay(alignment: .bottom) { Palette.separator.frame(height: 1) }
    }
}
