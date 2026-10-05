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
    @State private var selectedDay = 1
    @State private var swaps: [String: Int] = [:]
    @State private var savedRoute: TravelRoute?
    @State private var routes = TravelData.routes
    @State private var planContext = PlanContext.sample
    @State private var planner = TripPlanner()
    @State private var planError: String?
    @State private var refineText = ""
    @State private var wishBeforeImprove: String?
    @State private var wishError: String?
    @State private var matcher = PlaceMatcher()
    @State private var showAllMatches = false
    @FocusState private var wishFocused: Bool
    @State private var showKeySetup = false
    @State private var swapTarget: SwapTarget?
    @State private var voiceIdeas = false
    @State private var showProfile = false
    @State private var showMap = false
    @State private var mapMode: MapActivityMode = .mine
    @State private var selectedPlace: Place?
    @State private var feedCategory: FeedCategory = .all
    @State private var savedIdeaIDs: Set<String> = []

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
            _selectedDay = State(initialValue: 2)
        }
        if arguments.contains("--preview-map") { _showMap = State(initialValue: true) }
        if arguments.contains("--preview-map-everyone") {
            _showMap = State(initialValue: true)
            _mapMode = State(initialValue: .everyone)
        }
        if arguments.contains("--preview-profile") { _showProfile = State(initialValue: true) }
        if arguments.contains("--preview-destination") { _selectedPlace = State(initialValue: PlaceLibrary.all.first) }
        if arguments.contains("--preview-place-routes"), let place = PlaceLibrary.all.first {
            _screen = State(initialValue: .routes)
            _routes = State(initialValue: place.routes)
            _routeID = State(initialValue: place.routes[0].id)
            _planContext = State(initialValue: .place(place, origin: "Warsaw"))
        }
        #endif
    }

    private var route: TravelRoute { routeWith(id: routeID) ?? routes[0] }
    private var isGeneratedPlan: Bool { planContext.source == .generated }

    private func routeWith(id: Int) -> TravelRoute? {
        routes.first { $0.id == id } ?? (savedRoute?.id == id ? savedRoute : nil)
    }
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
            let stop = TravelData.day(target.day, for: routeWith(id: target.routeID) ?? route).stops[target.stopID]
            SwapSheet(stop: stop, initialSelection: swaps[target.id] ?? 0) { choice in
                swaps[target.id] = choice
                swapTarget = nil
            }
            .presentationDetents([.height(570), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Palette.background)
        }
        .sheet(isPresented: $showProfile) { TravelProfileSheet() }
        .sheet(isPresented: $showKeySetup) { KeySetupSheet() }
        .sheet(isPresented: $showMap) { TravelMapSheet(mode: $mapMode) }
        .sheet(item: $selectedPlace) { place in
            PlaceSheet(place: place, isSaved: savedIdeaIDs.contains(place.id)) {
                if savedIdeaIDs.contains(place.id) {
                    savedIdeaIDs.remove(place.id)
                } else {
                    savedIdeaIDs.insert(place.id)
                }
            } openRoute: { route in
                selectedPlace = nil
                open(place, route: route)
            }
        }
        #if DEBUG
        .task {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--preview-plan-run") { startPlanning() }
            if arguments.contains("--preview-matches") { matcher.preview(answers: PlaceMatcher.sampleAnswers, wish: wish) }
        }
        #endif
        .confirmationDialog("Try a spoken idea", isPresented: $voiceIdeas) {
            Button("A quiet beach and nature") { wish = "Four days somewhere warm with a quiet beach and beautiful nature. Start from Warsaw." }
            Button("Wild coast and hiking") { wish = "Four days of dramatic coastline and easy hikes, starting from Warsaw." }
            Button("Slow coastal days") { wish = "A slow coastal escape with good food and time to rest, starting from Warsaw." }
        } message: {
            Text("Voice entry is represented by sample ideas in this visual mock.")
        }
        .preferredColorScheme(.light)
    }

    private var filteredPlaces: [Place] {
        feedCategory == .all ? PlaceLibrary.all : PlaceLibrary.all.filter { $0.categories.contains(feedCategory) }
    }

    /// Shows a place's ready-made routes, or one route's itinerary.
    private func open(_ place: Place, route: TravelRoute? = nil) {
        routes = place.routes
        planContext = .place(place, origin: "Warsaw")
        planError = nil
        if let route {
            routeID = route.id
            selectedDay = 1
            screen = .itinerary
        } else {
            routeID = place.routes[0].id
            screen = .routes
        }
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

                WorldMapCard(mode: $mapMode) { showMap = true }

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
                    Text("\(filteredPlaces.count) places")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                }
                .padding(.top, 18).padding(.bottom, 12)

                ForEach(filteredPlaces.indices, id: \.self) { index in
                    let place = filteredPlaces[index]
                    Group {
                        if index == 0 {
                            PlaceFeatureCard(place: place) { selectedPlace = place }
                        } else {
                            PlaceCompactCard(place: place) { selectedPlace = place }
                        }
                    }
                    .padding(.bottom, 11)
                }

                Text("Places and routes are editorial samples. Flight times and budgets are per-person estimates from Warsaw, not live availability or fares.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 6)

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Somewhere else in mind?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Palette.text)
                        Text("Describe it and we’ll match it to places.")
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
        ScrollViewReader { proxy in
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
                CoastImage(name: "Algarve", height: 150)
                    .overlay(alignment: .top) {
                        Text("SOMEWHERE, SOON")
                            .font(.system(size: 11, weight: .bold)).tracking(1.3)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(.white.opacity(0.82), in: Capsule())
                            .padding(.top, 16)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text("The coast is calling.")
                            .font(.system(size: 24, weight: .bold)).tracking(-0.8)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 8)
                            .padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.top, 20)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your next escape")
                        .font(.system(size: 13, weight: .bold))
                    TextEditor(text: $wish)
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.text)
                        .scrollContentBackground(.hidden)
                        .frame(height: 92)
                        .focused($wishFocused)
                        .accessibilityLabel("Describe your next escape")
                    Palette.separator.frame(height: 1)
                    HStack {
                        if let wishBeforeImprove {
                            Button {
                                wish = wishBeforeImprove
                                self.wishBeforeImprove = nil
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Palette.accent)
                            }
                        } else {
                            Text("Start with a feeling")
                                .font(.system(size: 12)).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Button(action: improveWish) {
                            Group {
                                if planner.isImprovingWish {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "sparkles").font(.system(size: 16))
                                }
                            }
                            .foregroundStyle(Palette.accent)
                            .frame(width: 38, height: 38)
                            .background(Palette.accentSoft, in: Circle())
                        }
                        .disabled(planner.isImprovingWish || wish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Make my wish clearer")
                        Button { voiceIdeas = true } label: {
                            Image(systemName: "mic").font(.system(size: 16))
                                .foregroundStyle(Palette.accent)
                                .frame(width: 38, height: 38)
                                .background(Palette.accentSoft, in: Circle())
                        }
                        .accessibilityLabel("Try a spoken idea")
                        Button { findPlaces(proxy) } label: {
                            Group {
                                if matcher.isMatching {
                                    ProgressView().controlSize(.small).tint(.white)
                                } else {
                                    Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Palette.accent, in: Circle())
                        }
                        .disabled(matcher.isMatching || wishLength < PlaceMatcher.minimumCharacters)
                        .accessibilityLabel("Find places that fit")
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
                if let wishError {
                    Text(wishError)
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                        .padding(.top, 10)
                }
                matchesSection
                    .id("matches")
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 30)
        }
        #if DEBUG
        .task {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--preview-submit") { findPlaces(proxy) }
            guard arguments.contains("--preview-matches") else { return }
            try? await Task.sleep(for: .milliseconds(600))
            proxy.scrollTo("matches", anchor: .top)
        }
        #endif
        }
    }

    private var wishLength: Int { wish.trimmingCharacters(in: .whitespacesAndNewlines).count }

    /// Asks Jev to match the wish against every place. Runs only when the traveller submits.
    private func findPlaces(_ proxy: ScrollViewProxy) {
        guard wishLength >= PlaceMatcher.minimumCharacters else { return }
        wishFocused = false
        showAllMatches = false
        withAnimation { proxy.scrollTo("matches", anchor: .top) }
        Task { await matcher.match(wish: wish, origin: "Warsaw") }
    }

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Places that fit you").font(.system(size: 14, weight: .bold))
                Spacer()
                if matcher.isMatching {
                    ProgressView().controlSize(.small)
                } else if !matcher.matches.isEmpty {
                    Text("Matched by Jev").font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
            }
            .padding(.top, 27).padding(.bottom, 13)
            if let error = matcher.error, !matcher.isMatching {
                MatchNoticeCard(symbol: "exclamationmark.triangle", message: error,
                                actionTitle: AppConfig.jev == nil ? "Set up keys" : nil) { showKeySetup = true }
                    .padding(.bottom, matcher.matches.isEmpty ? 0 : 9)
            }
            if matcher.matches.isEmpty {
                if matcher.isMatching {
                    MatchNoticeCard(symbol: "sparkle.magnifyingglass", message: "Matching your wish to \(PlaceLibrary.all.count) places…")
                } else if matcher.error == nil {
                    MatchNoticeCard(
                        symbol: "text.cursor",
                        message: wishLength < PlaceMatcher.minimumCharacters
                            ? "Describe your trip in at least \(PlaceMatcher.minimumCharacters) characters (\(wishLength)/\(PlaceMatcher.minimumCharacters)), then tap → to find places that fit."
                            : "Tap → to match your wish to \(PlaceLibrary.all.count) places."
                    )
                }
            } else {
                if !matcher.isMatching, matcher.matchedWish != wish.trimmingCharacters(in: .whitespacesAndNewlines) {
                    Label("You’ve edited your wish. Tap → to update these matches.", systemImage: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .padding(.bottom, 10)
                }
                let shown = showAllMatches ? matcher.matches : Array(matcher.matches.prefix(5))
                ForEach(shown) { match in
                    PlaceMatchRow(match: match) { open(match.place) }
                        .padding(.bottom, 9)
                }
                .opacity(matcher.isMatching ? 0.55 : 1)
                .animation(.easeInOut(duration: 0.2), value: matcher.isMatching)
                if matcher.matches.count > 5 {
                    Button(showAllMatches ? "Show top 5" : "Show all \(matcher.matches.count) places") {
                        withAnimation { showAllMatches.toggle() }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .padding(.top, 2)
                }
            }
            Button(action: startPlanning) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Not quite it?").font(.system(size: 15, weight: .bold)).foregroundStyle(Palette.text)
                        Text("Plan a custom trip from your words with MiniMax.")
                            .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Palette.accent, in: Circle())
                }
                .padding(15)
                .background(Palette.accentSoft.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .disabled(planner.isWorking || wishLength == 0)
            .padding(.top, 14)
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
                Text("\(planContext.title),\n\(Text("three ways.").foregroundColor(Palette.accent))")
                    .font(.system(size: 34, weight: .bold)).tracking(-0.8)
                    .foregroundStyle(Palette.text).padding(.top, 10)
                Text(planContext.source == .place
                     ? "Ready-made routes, each with a different balance of ease, nature, and cost."
                     : "Each route answers the same wish with a different balance of ease, nature, and cost.")
                    .font(.system(size: 15)).foregroundStyle(Palette.muted)
                    .padding(.top, 8)
                HStack(spacing: 7) {
                    contextChip("↗ From \(planContext.origin)")
                    contextChip("◷ \(planContext.duration)")
                    contextChip("€ \(planContext.budget)")
                }
                .padding(.top, 18).padding(.bottom, 20)
                if planner.isWorking {
                    PlanningProgressCard(status: planner.progress)
                        .padding(.bottom, 12)
                } else if let planError {
                    PlanErrorCard(message: planError, retry: isGeneratedPlan ? nil : { startPlanning() }) {
                        self.planError = nil
                    }
                    .padding(.bottom, 12)
                }
                if !planner.isWorking {
                    routeCards
                    if isGeneratedPlan {
                        RefinePlanCard(text: $refineText, submit: refinePlan)
                            .padding(.top, 8)
                    }
                }
                if !planner.isWorking {
                    Text(routesFootnote)
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                        .padding(.top, 5)
                }
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 30)
        }
    }

    private var routesFootnote: String {
        switch planContext.source {
        case .generated: "Planned with MiniMax. Prices and times are estimates per person in EUR, not live fares or bookable options. Check details before you book."
        case .place: "Ready-made routes with per-person EUR estimates from Warsaw for autumn 2026. Not live prices or bookable options."
        case .sample: "Illustrative route concepts and per-person EUR estimates. These are not live prices or bookable options."
        }
    }

    private var routeCards: some View {
        ForEach(routes) { candidate in
                    let change = changes(for: candidate)
                    RouteCard(route: candidate,
                              total: candidate.estimatedTotal + change.price,
                              travel: candidate.travelMinutes + change.roadMinutes,
                              visits: candidate.visitMinutes + change.visitMinutes) {
                        routeID = candidate.id
                        selectedDay = 1
                        screen = .itinerary
                    }
                    .padding(.bottom, 12)
        }
    }

    private func startPlanning() {
        guard LLMAPI.apiKey != nil else {
            showKeySetup = true
            return
        }
        planError = nil
        screen = .routes
        Task {
            do {
                apply(try await planner.plan(wish: wish, origin: "Warsaw"))
            } catch {
                planError = error.localizedDescription
            }
        }
    }

    private func refinePlan(_ feedback: String) {
        let feedback = feedback.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !feedback.isEmpty else { return }
        planError = nil
        Task {
            do {
                apply(try await planner.refine(feedback))
                refineText = ""
            } catch {
                planError = error.localizedDescription
            }
        }
    }

    private func apply(_ plan: GeneratedPlan) {
        guard let first = plan.routes.first else { return }
        routes = plan.routes
        planContext = plan.context
        routeID = first.id
        selectedDay = 1
    }

    private func improveWish() {
        guard LLMAPI.apiKey != nil else {
            showKeySetup = true
            return
        }
        let original = wish
        wishError = nil
        Task {
            do {
                wish = try await planner.improve(wish: original, origin: "Warsaw")
                wishBeforeImprove = original
            } catch {
                wishError = error.localizedDescription
            }
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
                    ShareLink(item: "Elsewhere · \(route.name) in \(route.place) · \(route.dayCount) days from \(planContext.origin) · estimated \(euro(route.estimatedTotal + changes(for: route).price)) per person") {
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
                Text("\(route.dayCount) days · from \(planContext.origin) · \(sourceLabel)")
                    .font(.system(size: 13)).foregroundStyle(Palette.muted).padding(.top, 6)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(1...route.dayCount, id: \.self) { number in
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
                Kicker(text: "Day \(selectedDay) / \(route.dayCount)").padding(.top, 27)
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
                Button { savedRoute = savedRoute?.id == route.id ? nil : route } label: {
                    Text(savedRoute?.id == route.id ? "♥ Saved to your journeys" : "♡ Save this journey")
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

    private var sourceLabel: String {
        switch planContext.source {
        case .generated: "planned with MiniMax"
        case .place: "ready-made route"
        case .sample: "illustrative plan"
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
            Text("Per person · \(route.dayCount) days · EUR · \(planContext.source == .sample ? "illustrative" : "estimate")")
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
                if savedRoute == nil && savedIdeaIDs.isEmpty {
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
                    if let saved = savedRoute {
                        let change = changes(for: saved)
                        Kicker(text: "Your route").padding(.top, 27).padding(.bottom, 12)
                        RouteCard(route: saved, total: saved.estimatedTotal + change.price,
                                  travel: saved.travelMinutes + change.roadMinutes,
                                  visits: saved.visitMinutes + change.visitMinutes) {
                            if let place = PlaceLibrary.place(containing: saved.id) {
                                planContext = .place(place, origin: "Warsaw")
                                routes = place.routes
                            }
                            routeID = saved.id
                            selectedDay = 1
                            screen = .itinerary
                        }
                    }
                    if !savedIdeaIDs.isEmpty {
                        Kicker(text: "Places to revisit").padding(.top, 27).padding(.bottom, 12)
                        ForEach(PlaceLibrary.all.filter { savedIdeaIDs.contains($0.id) }) { place in
                            PlaceCompactCard(place: place) { selectedPlace = place }
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
