import SwiftUI

struct PhotoCredit: Identifiable {
    let asset: String
    let place: String
    let photographer: String
    let license: String
    let sourceURL: String
    let licenseURL: String

    var id: String { asset }
}

enum PhotoCredits {
    static let all: [PhotoCredit] = [
        PhotoCredit(asset: "Madeira", place: "Madeira", photographer: "Ximonic (Simo Räsänen)", license: "CC BY-SA 4.0",
                    sourceURL: "https://commons.wikimedia.org/wiki/File:Laurisilva_mountains_and_Ribeira_da_Metade_valley,_Santana,_Madeira,_Portugal,_2023_May.jpg",
                    licenseURL: "https://creativecommons.org/licenses/by-sa/4.0"),
        PhotoCredit(asset: "Rome", place: "Rome", photographer: "Giuseppe Milo", license: "CC BY 3.0",
                    sourceURL: "https://commons.wikimedia.org/wiki/File:Aerial_View_Of_The_Colosseum_Rome_Italy_Aerial_Photography_(151212315).jpeg",
                    licenseURL: "https://creativecommons.org/licenses/by/3.0"),
        PhotoCredit(asset: "Copenhagen", place: "Copenhagen", photographer: "Moahim", license: "CC BY-SA 4.0",
                    sourceURL: "https://commons.wikimedia.org/wiki/File:2018_-_Nyhavn_on_sunset.jpg",
                    licenseURL: "https://creativecommons.org/licenses/by-sa/4.0"),
        PhotoCredit(asset: "Algarve", place: "Algarve", photographer: "Mimihitam", license: "CC BY 4.0",
                    sourceURL: "https://commons.wikimedia.org/wiki/File:Praia_da_Marinha_2017.jpg",
                    licenseURL: "https://creativecommons.org/licenses/by/4.0"),
        PhotoCredit(asset: "Costa", place: "Costa Vicentina", photographer: "michael clarke stuff", license: "CC BY-SA 2.0",
                    sourceURL: "https://commons.wikimedia.org/wiki/File:Carrapateira_headland_05_(4347980947).jpg",
                    licenseURL: "https://creativecommons.org/licenses/by-sa/2.0"),
        PhotoCredit(asset: "Tavira", place: "Tavira", photographer: "Dmitry Tonkonog", license: "CC BY-SA 3.0",
                    sourceURL: "https://commons.wikimedia.org/wiki/File:Tavira_river_bank_02.jpg",
                    licenseURL: "https://creativecommons.org/licenses/by-sa/3.0"),
        PhotoCredit(asset: "Lisbon", place: "Lisbon", photographer: "Mайкл Гиммельфарб", license: "CC BY-SA 4.0",
                    sourceURL: "https://commons.wikimedia.org/wiki/File:Lisbon_OldCity_Panorama.jpg",
                    licenseURL: "https://creativecommons.org/licenses/by-sa/4.0"),
        PhotoCredit(asset: "Tokyo", place: "Tokyo", photographer: "David Kernan", license: "CC BY 4.0",
                    sourceURL: "https://commons.wikimedia.org/wiki/File:Minato_City,_Tokyo,_Japan_(Night).jpg",
                    licenseURL: "https://creativecommons.org/licenses/by/4.0")
    ]

    static func credit(for asset: String) -> PhotoCredit? {
        all.first { $0.asset == asset }
    }
}

struct PhotoCreditsSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "About the photography")
                Text("Images of elsewhere.")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .padding(.top, 8)
                Text("Location photographs from Wikimedia Commons. Each image is credited below with its source and license.")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 8)

                ForEach(PhotoCredits.all) { credit in
                    HStack(alignment: .top, spacing: 13) {
                        Image(credit.asset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(credit.place)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Palette.text)
                            Text("Photo by \(credit.photographer)")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.muted)
                            HStack(spacing: 13) {
                                Link("Original photo", destination: URL(string: credit.sourceURL)!)
                                Link(credit.license, destination: URL(string: credit.licenseURL)!)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.separator))
                    .padding(.top, 9)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 34)
            .padding(.bottom, 30)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .presentationBackground(Palette.background)
    }
}
