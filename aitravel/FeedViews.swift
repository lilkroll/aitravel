import SwiftUI
import MapKit

struct TravelWorldMap: View {
    var body: some View {
        Map(initialPosition: .camera(MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 30, longitude: 60),
            distance: 45_000_000
        )), bounds: MapCameraBounds(maximumDistance: 60_000_000), interactionModes: []) {
            Annotation("Lisbon", coordinate: CLLocationCoordinate2D(latitude: 38.72, longitude: -9.14)) {
                visitPin
            }
            Annotation("Rome", coordinate: CLLocationCoordinate2D(latitude: 41.90, longitude: 12.50)) {
                visitPin
            }
            Annotation("Tokyo", coordinate: CLLocationCoordinate2D(latitude: 35.68, longitude: 139.69)) {
                visitPin
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .allowsHitTesting(false)
        .accessibilityLabel("Sample visited places: Lisbon, Rome, and Tokyo")
    }

    private var visitPin: some View {
        Circle()
            .fill(Palette.accent)
            .frame(width: 10, height: 10)
            .padding(4)
            .background(.white, in: Circle())
            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
    }
}

struct WorldMapCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your world")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Palette.text)
                        Text("3 countries · 3 cities · 3 journeys")
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.text)
                        .frame(width: 34, height: 34)
                        .background(Palette.background, in: Circle())
                }
                .padding(18)
                TravelWorldMap()
                    .frame(height: 150)
                    .overlay(alignment: .topLeading) {
                        Text("Sample visits")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Palette.muted)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.regularMaterial, in: Capsule())
                            .padding(12)
                    }
            }
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Preview your travel map with three sample visits")
    }
}

struct FeedFeatureCard: View {
    let destination: FeedDestination
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                CoastImage(name: destination.artwork, height: 180)
                    .overlay(alignment: .topLeading) {
                        Text(destination.badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.text)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Palette.surface.opacity(0.94), in: Capsule())
                            .padding(13)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(destination.name)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.28), radius: 8)
                            .padding(16)
                    }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(destination.country)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Palette.muted)
                            Text(destination.whyNow)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Palette.text)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 10)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                    }
                    FeedFigures(destination: destination)
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

struct FeedCompactCard: View {
    let destination: FeedDestination
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                CoastImage(name: destination.artwork, height: 142)
                    .frame(width: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 0) {
                    Text(destination.badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.muted)
                    Text(destination.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Palette.text)
                        .padding(.top, 4)
                    Text(destination.whyNow)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .padding(.top, 4)
                    Spacer(minLength: 3)
                    HStack(spacing: 7) {
                        Text("~\(formattedDuration(destination.travelMinutes))")
                        Text("·")
                        Text("~\(euro(destination.estimatedBudget))")
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

struct FeedFigures: View {
    let destination: FeedDestination

    var body: some View {
        HStack(spacing: 0) {
            Label("~\(formattedDuration(destination.travelMinutes)) travel", systemImage: "airplane")
            Spacer()
            Text("~\(euro(destination.estimatedBudget)) / \(destination.days) days")
                .fontWeight(.bold)
        }
        .font(.system(size: 12))
        .foregroundStyle(Palette.accent)
        .padding(.top, 11)
        .overlay(alignment: .top) { Palette.separator.frame(height: 1) }
    }
}

struct FeedDestinationSheet: View {
    let destination: FeedDestination
    let isSaved: Bool
    let toggleSaved: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                CoastImage(name: destination.artwork, height: 225)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                if let credit = PhotoCredits.credit(for: destination.artwork) {
                    Link("Photo by \(credit.photographer) · \(credit.license)", destination: URL(string: credit.sourceURL)!)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .padding(.top, 8)
                }
                Kicker(text: destination.badge)
                    .padding(.top, 16)
                Text(destination.name)
                    .font(.system(size: 39, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .padding(.top, 6)
                Text(destination.country)
                    .font(.system(size: 14)).foregroundStyle(Palette.muted)
                Text(destination.whyNow)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.text)
                    .padding(.top, 18)
                Text(destination.detail)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 7)
                FeedFigures(destination: destination)
                    .padding(.top, 22)
                Text("Travel time and budget are illustrative per-person estimates from Warsaw, not live fares.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 12)
                Button(action: toggleSaved) {
                    Label(isSaved ? "Saved to your ideas" : "Save this idea", systemImage: isSaved ? "heart.fill" : "heart")
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
        .presentationDetents([.height(680), .large])
        .presentationBackground(Palette.background)
    }
}

struct TravelMapSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "Travel journal")
                Text("Your world, so far.")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Palette.text).padding(.top, 7)
                Text("A preview of how visited places could live in Elsewhere.")
                    .font(.system(size: 14)).foregroundStyle(Palette.muted)
                    .padding(.top, 5)
                TravelWorldMap()
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.top, 24)
                Label("3 countries · 3 cities · 3 journeys", systemImage: "globe.europe.africa")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.muted)
                    .padding(.vertical, 19)
                Kicker(text: "Sample places")
                    .padding(.top, 11).padding(.bottom, 10)
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
                Text("This map uses example visits. It is not connected to your travel history yet.")
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
