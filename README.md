# Elsewhere iOS mock

Open `aitravel.xcodeproj` in Xcode and run the `aitravel` scheme on an iPhone simulator. The app display name is **Elsewhere**.

The first screen is a native travel feed for departures from Warsaw. It includes a world map travel history preview, profile, destination filters, save controls, and destination details for Madeira, Rome, and Copenhagen. The Plan tab contains a travel wish, three illustrative route options, a four-day itinerary, stop swaps that update time and price estimates, and sharing. The Saved tab collects selected feed ideas and the sample journey.

Destination and route cards use bundled location photographs. Lisbon, Rome, and Tokyo have photos in the sample travel journal. Sources and licenses are listed in [PHOTO_CREDITS.md](PHOTO_CREDITS.md) and in the app under Profile → Photo credits.

All destinations, prior visits, travel times, and prices are illustrative October 2026 content. Saved state lasts only while the app is running. There is no live pricing, trip generation, booking, account, or travel history backend.

The Debug launch arguments `--preview-plan`, `--preview-saved`, `--preview-map`, `--preview-profile`, `--preview-destination`, `--preview-routes`, `--preview-itinerary`, and `--preview-swap` open specific views for visual review.

Simulator captures of the main screens are in `previews/`.

## Visual direction

Revolut and Apple are the only current visual references: neutral grouped surfaces, system typography, blue accents, rounded photo cards, native iOS tabs, and MapKit for the sample travel journal. Mobbin references: [Revolut](https://mobbin.com/screens/48b789cf-a061-4e74-b3f2-e553d3e885e5), [Apple Maps](https://mobbin.com/screens/12157e3f-ceb2-4a6e-b620-bf8bf28d710e). Map tiles require a network connection; destination photos remain bundled. Updated simulator captures use the `elsewhere-revolut-apple-` prefix.
