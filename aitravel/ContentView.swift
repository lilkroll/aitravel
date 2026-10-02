import SwiftUI

private enum Screen { case feed, wish, routes, itinerary, saved }

private struct SwapTarget: Identifiable {
    let routeID: Int
    let day: Int
    let stopID: Int
    var id: String { "\(routeID):\(day):\(stopID)" }
}

struct ContentView: View {
    @State private var screen: Screen = .feed
    @State private var wish = TravelData.sampleWish
    @State private var routeID = 0
    @State private var selectedDay = 2
    @State private var swaps: [String: Int] = [:]
    @State private var savedRouteID: Int?
    @State private var swapTarget: SwapTarget?
    @State private var voiceIdeas = false
    @State private var showProfile = false
    @State private var showMap = false
    @State private var selectedDestination: FeedDestination?
    @State private var feedCategory: FeedCategory = .all
    @State private var savedIdeaIDs: Set<Int> = []

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--preview-plan") { _screen = State(initialValue: .wish) }
        if arguments.contains("--preview-saved") { _screen = State(initialValue: .saved) }
        if arguments.contains("--preview-routes") { _screen = State(initialValue: .routes) }
        if arguments.contains("--preview-itinerary") { _screen = State(initialValue: .itinerary) }
        if arguments.contains("--preview-swap") {
            _screen = State(initialValue: .itinerary)
            _swapTarget = State(initialValue: SwapTarget(routeID: 0, day: 2, stopID: 1))
        }
        if arguments.contains("--preview-map") { _showMap = State(initialValue: true) }
        if arguments.contains("--preview-profile") { _showProfile = State(initialValue: true) }
        if arguments.contains("--preview-destination") { _selectedDestination = State(initialValue: FeedData.destinations[0]) }
        #endif
    }

    private var route: TravelRoute { TravelData.routes[routeID] }
    private var day: DayPlan { TravelData.day(selectedDay, for: route) }

    var body: some View {
        TabView(selection: Binding(
            get: { screen == .routes || screen == .itinerary ? .wish : screen },
            set: { screen = $0 }
        )) {
            feedPage
                .background(Palette.background)
                .tabItem { Label("Explore", systemImage: "safari") }
                .tag(Screen.feed)
            Group {
                switch screen {
                case .routes: routesPage
                case .itinerary: itineraryPage
                default: explorePage
                }
            }
            .background(Palette.background)
            .tabItem { Label("Plan", systemImage: "point.topleft.down.curvedto.point.bottomright.up") }
            .tag(Screen.wish)
            savedPage
                .background(Palette.background)
                .tabItem { Label("Saved", systemImage: "heart") }
                .tag(Screen.saved)
        }
        .tint(Palette.accent)
        .sheet(item: $swapTarget) { target in
            let stop = TravelData.day(target.day, for: TravelData.routes[target.routeID]).stops[target.stopID]
            SwapSheet(stop: stop, initialSelection: swaps[target.id] ?? 0) { choice in
                swaps[target.id] = choice
                swapTarget = nil
            }
            .presentationDetents([.height(570), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Palette.background)
        }
        .sheet(isPresented: $showProfile) { TravelProfileSheet() }
        .sheet(isPresented: $showMap) { TravelMapSheet() }
        .sheet(item: $selectedDestination) { destination in
            FeedDestinationSheet(destination: destination, isSaved: savedIdeaIDs.contains(destination.id)) {
                if savedIdeaIDs.contains(destination.id) {
                    savedIdeaIDs.remove(destination.id)
                } else {
                    savedIdeaIDs.insert(destination.id)
                }
            }
        }
        .confirmationDialog("Try a spoken idea", isPresented: $voiceIdeas) {
            Button("A quiet beach and nature") { wish = "Four days somewhere warm with a quiet beach and beautiful nature. Start from Warsaw." }
            Button("Wild coast and hiking") { wish = "Four days of dramatic coastline and easy hikes, starting from Warsaw." }
            Button("Slow coastal days") { wish = "A slow coastal escape with good food and time to rest, starting from Warsaw." }
        } message: {
            Text("Voice entry is represented by sample ideas in this visual mock.")
        }
        .preferredColorScheme(.light)
    }

    private var filteredDestinations: [FeedDestination] {
        feedCategory == .all ? FeedData.destinations : FeedData.destinations.filter { $0.category == feedCategory }
    }

    private var feedPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Brand()
                    Spacer()
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 21))
                            .foregroundStyle(Palette.text)
                            .frame(width: 40, height: 40)
                            .background(Palette.surface, in: Circle())
                            .overlay(Circle().stroke(Palette.separator))
                    }
                    .accessibilityLabel("Travel profile")
                }
                .padding(.bottom, 15)

                WorldMapCard { showMap = true }

                Text("Good places to go")
                    .font(.system(size: 33, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(Palette.text)
                    .padding(.top, 22)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("FROM WARSAW · OCTOBER 2026")
                        .font(.headline.weight(.bold))
                        .tracking(0.5)
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                        .accessibilityHidden(true)
                }
                .padding(.top, 8)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(FeedCategory.allCases) { category in
                            Button { feedCategory = category } label: {
                                Text(category.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(feedCategory == category ? .white : Palette.text)
                                    .padding(.horizontal, 15).padding(.vertical, 9)
                                    .background(feedCategory == category ? Palette.accent : Palette.surface, in: Capsule())
                                    .accessibilityAddTraits(feedCategory == category ? [.isSelected] : [])
                            }
                        }
                    }
                }
                .padding(.top, 15)

                HStack {
                    Text("Worth a closer look")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.text)
                    Spacer()
                    Text("\(filteredDestinations.count) places")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                }
                .padding(.top, 18).padding(.bottom, 12)

                ForEach(filteredDestinations.indices, id: \.self) { index in
                    let destination = filteredDestinations[index]
                    Group {
                        if index == 0 {
                            FeedFeatureCard(destination: destination) { selectedDestination = destination }
                        } else {
                            FeedCompactCard(destination: destination) { selectedDestination = destination }
                        }
                    }
                    .padding(.bottom, 11)
                }

                Text("Seasonal ideas are editorial samples. Travel times and budgets are illustrative, not live availability or fares.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 6)

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Somewhere else in mind?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Palette.text)
                        Text("Start with a feeling. Shape the rest later.")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer(minLength: 4)
                    Button { screen = .wish } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Palette.accent, in: Circle())
                    }
                    .accessibilityLabel("Plan your own trip")
                }
                .padding(17)
                .background(Palette.accentSoft.opacity(0.65), in: RoundedRectangle(cornerRadius: 19))
                .padding(.top, 22)
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 30)
        }
    }

    private var explorePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Brand()
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 17))
                        .frame(width: 39, height: 39)
                        .background(Palette.surface, in: Circle())
                        .overlay(Circle().stroke(Palette.separator))
                        .accessibilityHidden(true)
                }
                .padding(.bottom, 31)
                Kicker(text: "Go somewhere good")
                Text("Where to next?")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(Palette.text)
                    .padding(.top, 11)
                Text("Tell us what you’re longing for. We’ll turn it into a few good ways to go.")
                    .font(.system(size: 15)).foregroundStyle(Palette.muted)
                    .padding(.top, 9)
                CoastImage(name: "Algarve", height: 265)
                    .overlay(alignment: .top) {
                        Text("SOMEWHERE, SOON")
                            .font(.system(size: 11, weight: .bold)).tracking(1.3)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(.white.opacity(0.82), in: Capsule())
                            .padding(.top, 23)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text("The coast is calling.")
                            .font(.system(size: 29, weight: .bold)).tracking(-1)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 8)
                            .padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.top, 25)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your next escape")
                        .font(.system(size: 13, weight: .bold))
                    TextEditor(text: $wish)
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.text)
                        .scrollContentBackground(.hidden)
                        .frame(height: 92)
                        .accessibilityLabel("Describe your next escape")
                    Palette.separator.frame(height: 1)
                    HStack {
                        Text("Start with a feeling")
                            .font(.system(size: 12)).foregroundStyle(Palette.muted)
                        Spacer()
                        Button { voiceIdeas = true } label: {
                            Image(systemName: "mic").font(.system(size: 16))
                                .foregroundStyle(Palette.accent)
                                .frame(width: 38, height: 38)
                                .background(Palette.accentSoft, in: Circle())
                        }
                        .accessibilityLabel("Try a spoken idea")
                        Button { screen = .routes } label: {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Palette.accent, in: Circle())
                        }
                        .accessibilityLabel("See sample routes")
                    }
                }
                .padding(17)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.separator))
                .padding(.top, 19)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        wishChip("☀ Quiet beach", "Somewhere warm with a quiet beach and nature, four days from Warsaw.")
                        wishChip("♧ Wild nature", "Four days of dramatic nature and easy hikes from Warsaw.")
                        wishChip("◷ Slow days", "A slow coastal escape with good food, four days from Warsaw.")
                    }
                }
                .padding(.top, 15)
                HStack {
                    Text("Ideas for the feeling").font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text("Tap to explore").font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                .padding(.top, 27).padding(.bottom, 13)
                HStack(spacing: 10) {
                    inspiration("Costa", "Take the\nscenic route")
                    inspiration("Tavira", "Find a quiet\nshore")
                }
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 30)
        }
    }

    private func wishChip(_ title: String, _ text: String) -> some View {
        Button { wish = text } label: {
            Text(title).font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Palette.accentSoft, in: Capsule())
        }
    }

    private func inspiration(_ image: String, _ title: String) -> some View {
        Button { screen = .routes } label: {
            CoastImage(name: image, height: 116)
                .overlay(alignment: .bottomLeading) {
                    Text(title).font(.system(size: 18, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white).padding(13)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var routesPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    back("Your wish") { screen = .wish }
                    Spacer()
                    Kicker(text: "01 / Compare")
                }
                .padding(.bottom, 29)
                Kicker(text: "Three good ways to go")
                Text("Your escape,\n\(Text("three ways.").foregroundColor(Palette.accent))")
                    .font(.system(size: 34, weight: .bold)).tracking(-0.8)
                    .foregroundStyle(Palette.text).padding(.top, 10)
                Text("Each route answers the same wish with a different balance of ease, nature, and cost.")
                    .font(.system(size: 15)).foregroundStyle(Palette.muted)
                    .padding(.top, 8)
                HStack(spacing: 7) {
                    contextChip("↗ From Warsaw")
                    contextChip("◷ 4 days")
                    contextChip("€ Around 800")
                }
                .padding(.top, 18).padding(.bottom, 20)
                ForEach(TravelData.routes) { candidate in
                    let change = changes(for: candidate)
                    RouteCard(route: candidate,
                              total: candidate.estimatedTotal + change.price,
                              travel: candidate.travelMinutes + change.roadMinutes,
                              visits: candidate.visitMinutes + change.visitMinutes) {
                        routeID = candidate.id
                        selectedDay = 2
                        screen = .itinerary
                    }
                    .padding(.bottom, 12)
                }
                Text("Illustrative route concepts and per-person EUR estimates. These are not live prices or bookable options.")
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .padding(.top, 5)
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 30)
        }
    }

    private func contextChip(_ title: String) -> some View {
        Text(title).font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Palette.text.opacity(0.75))
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Palette.separator.opacity(0.55), in: Capsule())
    }

    private var itineraryPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    back("All routes") { screen = .routes }
                    Spacer()
                    ShareLink(item: "Elsewhere · \(route.name) in \(route.place) · 4 days from Warsaw · estimated \(euro(route.estimatedTotal + changes(for: route).price)) per person") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundStyle(Palette.text)
                            .frame(width: 38, height: 38)
                            .background(Palette.surface, in: Circle())
                            .overlay(Circle().stroke(Palette.separator))
                    }
                    .accessibilityLabel("Share route summary")
                }
                .padding(.bottom, 20)
                Kicker(text: "\(route.name) · \(route.place)")
                Text(route.headline).font(.system(size: 38, weight: .bold))
                    .tracking(-0.8).foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 7)
                Text("4 days · from Warsaw · illustrative plan")
                    .font(.system(size: 13)).foregroundStyle(Palette.muted).padding(.top, 6)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(1...4, id: \.self) { number in
                            Button { selectedDay = number } label: {
                                Text("Day \(number)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(selectedDay == number ? .white : Palette.muted)
                                    .padding(.horizontal, 15).padding(.vertical, 9)
                                    .background(selectedDay == number ? Palette.text : Palette.surface, in: Capsule())
                                    .overlay(Capsule().stroke(selectedDay == number ? Palette.text : Palette.separator))
                            }
                        }
                    }
                }
                .padding(.top, 22)
                Kicker(text: "Day \(selectedDay) / 4").padding(.top, 27)
                Text(day.title).font(.system(size: 26, weight: .bold))
                    .tracking(-0.8).foregroundStyle(Palette.text).padding(.top, 5)
                Text(day.note).font(.system(size: 13)).foregroundStyle(Palette.muted).padding(.top, 4)
                metricsCard.padding(.top, 17)
                if day.stops.contains(where: { choice(for: $0) > 0 }) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Plan updated").font(.system(size: 13, weight: .bold))
                        Text("Times, travel, and the estimate below now reflect your swap.")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(13)
                    .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 18)
                }
                timeline.padding(.top, 23)
                budgetCard.padding(.top, 20)
                Button { savedRouteID = savedRouteID == route.id ? nil : route.id } label: {
                    Text(savedRouteID == route.id ? "♥ Saved to your journeys" : "♡ Save this journey")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.accent)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 13))
                }
                .padding(.top, 17)
                Text("Planning illustration only. Meals and personal spending are not included.")
                    .font(.system(size: 12)).foregroundStyle(Palette.muted).padding(.top, 15)
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 30)
        }
    }

    private var metricsCard: some View {
        let stats = dayStats
        return VStack(spacing: 14) {
            metric(formattedDuration(stats.visitMinutes), "At places", "clock")
            Divider()
            metric(formattedDuration(stats.roadMinutes), "On the road", "car.side")
            Divider()
            metric("~\(euro(stats.price))", "Day spend", "creditcard")
        }
        .padding(18)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func metric(_ value: String, _ label: String, _ symbol: String) -> some View {
        HStack {
            Label(label, systemImage: symbol).foregroundStyle(Palette.muted)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(Palette.text)
        }
        .font(.subheadline)
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            ForEach(day.stops) { stop in
                let option = selectedOption(for: stop)
                let start = startMinute(for: stop.id)
                VisitRow(time: formattedTime(start), option: option, changed: choice(for: stop) > 0) {
                    swapTarget = SwapTarget(routeID: route.id, day: selectedDay, stopID: stop.id)
                }
                if stop.transferMinutes > 0 {
                    TransferRow(time: formattedTime(start + option.visitMinutes),
                                title: stop.transferTitle,
                                minutes: stop.transferMinutes + option.roadDelta,
                                cost: stop.transferCost)
                }
            }
        }
    }

    private var budgetCard: some View {
        let change = changes(for: route)
        return VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "Estimated trip total", color: Palette.accentSoft)
            Text("~\(euro(route.estimatedTotal + change.price))")
                .font(.system(size: 35, weight: .bold))
                .foregroundStyle(.white).padding(.top, 8)
            Text("Per person · 4 days · EUR · illustrative")
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
                .padding(.top, 3).padding(.bottom, 13)
            budgetRow("Travel to destination", route.costs.destinationTravel)
            budgetRow("Stay", route.costs.stay)
            budgetRow("Local transport", route.costs.localTransport)
            budgetRow("Visits and admission", route.costs.visits + change.price)
            Button { screen = .routes } label: {
                Text("Compare other routes →")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 9)
        }
        .padding(19).background(Palette.text, in: RoundedRectangle(cornerRadius: 20))
    }

    private func budgetRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title).foregroundStyle(.white.opacity(0.74))
            Spacer()
            Text("~\(euro(value))").fontWeight(.semibold)
        }
        .font(.system(size: 12)).foregroundStyle(.white)
        .padding(.vertical, 9)
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.15)).frame(height: 1) }
    }

    private var savedPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Brand().padding(.bottom, 35)
                Kicker(text: "Your journeys")
                Text("Saved places")
                    .font(.system(size: 34, weight: .bold)).tracking(-0.8)
                    .foregroundStyle(Palette.text).padding(.top, 10)
                if savedRouteID == nil && savedIdeaIDs.isEmpty {
                    CoastImage(name: "Tavira", height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.top, 35)
                    Text("Room for a new story.")
                        .font(.system(size: 31, weight: .bold)).padding(.top, 24)
                    Text("Save a place or route you love and it will be here when you’re ready to return.")
                        .font(.system(size: 14)).foregroundStyle(Palette.muted).padding(.top, 8)
                    Button { screen = .feed } label: {
                        Text("Explore places")
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 18).padding(.vertical, 13)
                            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 20)
                } else {
                    Text("A place to return to your ideas and plans.")
                        .font(.system(size: 15)).foregroundStyle(Palette.muted).padding(.top, 9)
                    if let savedRouteID {
                        let saved = TravelData.routes[savedRouteID]
                        let change = changes(for: saved)
                        Kicker(text: "Your route").padding(.top, 27).padding(.bottom, 12)
                        RouteCard(route: saved, total: saved.estimatedTotal + change.price,
                                  travel: saved.travelMinutes + change.roadMinutes,
                                  visits: saved.visitMinutes + change.visitMinutes) {
                            routeID = savedRouteID
                            selectedDay = 2
                            screen = .itinerary
                        }
                    }
                    if !savedIdeaIDs.isEmpty {
                        Kicker(text: "Places to revisit").padding(.top, 27).padding(.bottom, 12)
                        ForEach(FeedData.destinations.filter { savedIdeaIDs.contains($0.id) }) { destination in
                            FeedCompactCard(destination: destination) { selectedDestination = destination }
                                .padding(.bottom, 10)
                        }
                    }
                }
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 30)
        }
    }

    private func back(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold))
                Text(title).font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Palette.text)
        }
    }

    private func key(routeID: Int, day: Int, stopID: Int) -> String { "\(routeID):\(day):\(stopID)" }
    private func choice(for stop: TravelStop) -> Int { swaps[key(routeID: route.id, day: selectedDay, stopID: stop.id)] ?? 0 }
    private func selectedOption(for stop: TravelStop) -> TravelOption { stop.allOptions[min(choice(for: stop), stop.allOptions.count - 1)] }

    private func startMinute(for stopID: Int) -> Int {
        var minute = day.startMinute
        for stop in day.stops where stop.id < stopID {
            let option = selectedOption(for: stop)
            minute += option.visitMinutes + stop.transferMinutes + option.roadDelta
        }
        return minute
    }

    private var dayStats: PlanChange {
        var result = PlanChange()
        for stop in day.stops {
            let option = selectedOption(for: stop)
            result.price += option.price + stop.transferCost
            result.visitMinutes += option.visitMinutes
            result.roadMinutes += stop.transferMinutes + option.roadDelta
        }
        return result
    }

    private func changes(for candidate: TravelRoute) -> PlanChange {
        var result = PlanChange()
        for (key, choice) in swaps where choice > 0 {
            let parts = key.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 3, parts[0] == candidate.id else { continue }
            let plan = TravelData.day(parts[1], for: candidate)
            guard let stop = plan.stops.first(where: { $0.id == parts[2] }), choice < stop.allOptions.count else { continue }
            let option = stop.allOptions[choice]
            result.price += option.price - stop.price
            result.roadMinutes += option.roadDelta
            result.visitMinutes += option.visitMinutes - stop.visitMinutes
        }
        return result
    }
}

#Preview {
    ContentView()
}
