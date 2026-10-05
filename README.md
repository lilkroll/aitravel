# Elsewhere iOS mock

Open `aitravel.xcodeproj` in Xcode and run the `aitravel` scheme on an iPhone simulator. The app display name is **Elsewhere**.

The first screen is a native travel feed for departures from Warsaw. It includes a world map travel history preview, profile, category filters, save controls, and 20 places (Thailand, Japan, Portugal, Iceland, Mexico, and more). Each place has three ready-made routes with day-by-day itineraries, stored in [`aitravel/Places.json`](aitravel/Places.json). The Plan tab takes a travel wish of at least 10 characters. When the traveller taps the arrow, the app asks [Jev](https://api.typesafe.ai) how well each place fits and lists the places with a fit percentage and the traits behind it (beaches, warmth, budget, trip length, flight length, and so on). Editing the wish does not call Jev until it is submitted again. Opening a match shows its routes; itineraries support stop swaps that update time and price estimates, and sharing. "Not quite it?" plans a custom trip from the wish with MiniMax M3.1, which can then be refined. The Saved tab collects saved places and journeys.

## API keys

Copy `.env.example` to `.env` in the project folder and fill in `JEV_API_KEY` or `OPENROUTER_API_KEY` (place matching through TypeSafe or OpenRouter) and `MINIMAX_API_KEY` (custom plans). `.env` is gitignored; the **Bundle .env** build phase copies it into the app as `app.env`, so rebuild after editing it. Variables set in the Xcode scheme override the file. Keys bundled this way are readable by anyone with the app binary, so a shipped build should call both services through a backend instead.

Destination and route cards use bundled location photographs. Lisbon, Rome, and Tokyo have photos in the sample travel journal. Sources and licenses are listed in [PHOTO_CREDITS.md](PHOTO_CREDITS.md) and in the app under Profile → Photo credits.

All places, routes, prior visits, travel times, and prices are illustrative autumn 2026 estimates. Places without a bundled photo use a gradient card. Saved state lasts only while the app is running. There is no live pricing, booking, account, or travel history backend.

The Debug launch arguments `--preview-plan`, `--preview-saved`, `--preview-map`, `--preview-map-everyone`, `--preview-profile`, `--preview-destination`, `--preview-routes`, `--preview-itinerary`, and `--preview-swap` open specific views for visual review. `--preview-place-routes` opens the first place's routes, `--preview-submit` submits the sample wish to Jev on launch, `--preview-matches` shows matches for the sample wish from built-in sample preferences (no Jev key needed), and `--preview-plan-run` starts a custom MiniMax plan for the sample wish on launch.

Simulator captures of the main screens are in `previews/`.

## Visual directio

Revolut and Apple are the only current visual references: neutral grouped surfaces, system typography, blue accents, rounded photo cards, native iOS tabs, and a dot-grid world map (shaded like a contribution graph) for the travel journal, with "You" and "Everyone" views. Mobbin references: [Revolut](https://mobbin.com/screens/48b789cf-a061-4e74-b3f2-e553d3e885e5), [Apple Maps](https://mobbin.com/screens/12157e3f-ceb2-4a6e-b620-bf8bf28d710e). The world map and destination photos are bundled and work offline. Updated simulator captures use the `elsewhere-revolut-apple-` prefix.
