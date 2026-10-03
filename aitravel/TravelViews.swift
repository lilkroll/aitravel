import SwiftUI

enum Palette {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color.white
    static let text = Color(red: 17/255, green: 19/255, blue: 24/255)
    static let accent = Color(red: 0/255, green: 100/255, blue: 230/255)
    static let accentSoft = Color(red: 233/255, green: 241/255, blue: 255/255)
    static let muted = Color(uiColor: .secondaryLabel)
    static let separator = Color(uiColor: .separator).opacity(0.3)
}

struct Kicker: View {
    let text: String
    var color = Palette.muted
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
    }
}

struct Brand: View {
    var body: some View {
        Text("elsewhere")
            .font(.system(size: 24, weight: .bold))
            .tracking(-0.8)
            .foregroundStyle(Palette.text)
    }
}

struct CoastImage: View {
    let name: String
    let height: CGFloat
    var body: some View {
        GeometryReader { geometry in
            Group {
                if UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Generated places without a bundled photo get a calm sea-to-sky gradient.
                    LinearGradient(colors: [Color(red: 0.55, green: 0.75, blue: 0.95), Palette.accent],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(16)
                        }
                }
            }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay {
                    LinearGradient(colors: [.clear, Palette.text.opacity(0.43)], startPoint: .center, endPoint: .bottom)
                }
        }
        .frame(height: height)
    }
}

struct RouteCard: View {
    let route: TravelRoute
    let total: Int
    let travel: Int
    let visits: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                CoastImage(name: route.artwork, height: 120)
                    .overlay(alignment: .topLeading) {
                        Text(route.badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.accent)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Palette.surface.opacity(0.92), in: Capsule())
                            .padding(12)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(route.place)
                            .font(.system(size: 25, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 7)
                            .padding(15)
                    }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(route.name).font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.text)
                            Text(route.reason)
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.muted)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 2)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("~\(euro(total))").font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.text)
                            Text("per person").font(.system(size: 11)).foregroundStyle(Palette.muted)
                        }
                    }
                    HStack(spacing: 16) {
                        Label("\(formattedDuration(travel)) travel", systemImage: "car.side")
                        Label("\(formattedDuration(visits)) at places", systemImage: "clock")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    .overlay(alignment: .top) { Palette.separator.frame(height: 1) }
                    .padding(.top, 12)
                }
                .padding(14)
            }
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 21))
            .overlay(RoundedRectangle(cornerRadius: 21).stroke(Palette.separator))
        }
        .buttonStyle(.plain)
    }
}

struct VisitRow: View {
    let time: String
    let option: TravelOption
    let changed: Bool
    let swap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(time)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .frame(width: 41, alignment: .leading)
                .padding(.top, 5)
            Circle().fill(Palette.background).frame(width: 13, height: 13)
                .overlay(Circle().stroke(Palette.accent, lineWidth: 3))
                .frame(width: 16).padding(.top, 3)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(option.title).font(.system(size: 14, weight: .bold))
                    Spacer(minLength: 4)
                    Text(option.price == 0 ? "Free" : euro(option.price))
                        .font(.system(size: 13, weight: .bold))
                }
                Text(option.reason).font(.system(size: 12)).foregroundStyle(Palette.muted).padding(.top, 5)
                HStack {
                    Text("\(formattedDuration(option.visitMinutes)) visit")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.muted)
                    Spacer()
                    Button(action: swap) {
                        Text("↔ Swap stop")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.accent)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(Palette.accentSoft.opacity(0.5), in: Capsule())
                            .overlay(Capsule().stroke(Palette.separator))
                    }
                }
                .padding(.top, 10)
            }
            .padding(13)
            .background(changed ? Palette.accentSoft.opacity(0.42) : Palette.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(changed ? Palette.accent.opacity(0.5) : Palette.separator))
        }
        .padding(.bottom, 13)
    }
}

struct TransferRow: View {
    let time: String
    let title: String
    let minutes: Int
    let cost: Int
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(time).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.muted).frame(width: 41, alignment: .leading)
            Circle().fill(Palette.accentSoft).frame(width: 12, height: 12).frame(width: 16)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(Text(title).fontWeight(.bold).foregroundColor(Palette.text)) · \(formattedDuration(minutes)) on the road")
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                Text(cost == 0 ? "On foot · free" : "~\(euro(cost)) local transport")
                    .font(.system(size: 11)).foregroundStyle(Palette.muted)
            }
        }
        .padding(.bottom, 17)
    }
}

struct SwapSheet: View {
    let stop: TravelStop
    let onApply: (Int) -> Void
    @State private var selection: Int

    init(stop: TravelStop, initialSelection: Int, onApply: @escaping (Int) -> Void) {
        self.stop = stop
        self.onApply = onApply
        self._selection = State(initialValue: initialSelection)
    }

    private var option: TravelOption { stop.allOptions[selection] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "Make it yours")
                Text("Swap this stop.")
                    .font(.system(size: 31, weight: .bold)).tracking(-1)
                    .foregroundStyle(Palette.text).padding(.top, 7)
                Text("Choose a different way to spend this part of the day. The plan will adjust around it.")
                    .font(.system(size: 13)).foregroundStyle(Palette.muted)
                    .padding(.top, 4).padding(.bottom, 18)
                ForEach(Array(stop.allOptions.enumerated()), id: \.offset) { index, candidate in
                    Button { selection = index } label: {
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(candidate.title).font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.text)
                                Text("\(index == 0 ? "Current stop · " : "")\(candidate.reason) · \(formattedDuration(candidate.visitMinutes)) visit")
                                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 6)
                            Text(candidate.price == 0 ? "Free" : euro(candidate.price))
                                .font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(13)
                        .background(selection == index ? Palette.accentSoft.opacity(0.5) : Palette.surface, in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(selection == index ? Palette.accent : Palette.separator, lineWidth: selection == index ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 9)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("What changes").font(.system(size: 13, weight: .bold))
                    Text(impactText).font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
                .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 13))
                .padding(.top, 6)
                Button { onApply(selection) } label: {
                    Text(selection == 0 ? "Keep this stop" : "Use this stop")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 17)
            }
            .padding(.horizontal, 23).padding(.top, 31).padding(.bottom, 30)
        }
    }

    private var impactText: String {
        guard selection > 0 else { return "Your current time and cost stay the same." }
        let visit = option.visitMinutes - stop.visitMinutes
        let cost = option.price - stop.price
        return "\(signedTime(visit)) at places · \(signedTime(option.roadDelta)) on the road · \(signedPrice(cost)) trip estimate"
    }
    private func signedTime(_ value: Int) -> String {
        value == 0 ? "0m" : "\(value > 0 ? "+" : "−")\(formattedDuration(abs(value)))"
    }
    private func signedPrice(_ value: Int) -> String {
        value == 0 ? "€0" : "\(value > 0 ? "+" : "−")\(euro(abs(value)))"
    }
}

struct PlanningProgressCard: View {
    let status: String

    var body: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(Palette.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Planning three ways to go")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.text)
                Text(status)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .contentTransition(.opacity)
                    .animation(.easeInOut, value: status)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

struct PlanErrorCard: View {
    let message: String
    let retry: (() -> Void)?
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.text)
            HStack(spacing: 14) {
                if let retry {
                    Button("Try again", action: retry)
                        .font(.system(size: 13, weight: .bold))
                }
                Button("Dismiss", action: dismiss)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.muted)
            }
            .foregroundStyle(Palette.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.separator))
    }
}

struct RefinePlanCard: View {
    @Binding var text: String
    let submit: (String) -> Void

    private let suggestions = ["Make it cheaper", "More nature", "Less time on the road", "Slower pace", "Add one more day"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Make it better", systemImage: "sparkles")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.text)
            HStack(spacing: 8) {
                TextField("Tell Claude what to change…", text: $text, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(1...3)
                    .submitLabel(.send)
                    .onSubmit { submit(text) }
                Button { submit(text) } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Palette.accent, in: Circle())
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Update the plan")
            }
            .padding(.leading, 13).padding(.trailing, 6).padding(.vertical, 6)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: 16))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button { submit(suggestion) } label: {
                            Text(suggestion)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Palette.accent)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Palette.accentSoft, in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.separator))
    }
}

struct ClaudeKeySheet: View {
    let onSaved: () -> Void
    @State private var key = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "Connect Claude")
            Text("Plan real trips.")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Palette.text)
                .padding(.top, 7)
            Text("Elsewhere uses Claude to turn your wish into routes and itineraries. Paste an Anthropic API key from platform.claude.com. It stays in this device’s Keychain.")
                .font(.system(size: 14)).foregroundStyle(Palette.muted)
                .padding(.top, 8)
            SecureField("sk-ant-…", text: $key)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, design: .monospaced))
                .padding(14)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.separator))
                .padding(.top, 22)
            Button {
                KeyStore.save(key)
                onSaved()
            } label: {
                Text("Save and continue")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.top, 14)
            Spacer()
        }
        .padding(.horizontal, 24).padding(.top, 34)
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
        .presentationBackground(Palette.background)
    }
}
