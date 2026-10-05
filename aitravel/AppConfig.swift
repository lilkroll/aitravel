import Foundation

/// API keys and endpoints. Read from the process environment first (Xcode scheme),
/// then from `app.env`, which the "Bundle .env" build phase copies from the project-root `.env`.
enum AppConfig {
    /// Where Jev requests go: TypeSafe directly (`JEV_API_KEY`) or through OpenRouter (`OPENROUTER_API_KEY`).
    struct JevEndpoint {
        let url: URL
        let key: String
        let model: String
        let keyName: String
    }

    static var jev: JevEndpoint? {
        let model = value("JEV_MODEL") ?? "jev-latest"
        if let key = value("JEV_API_KEY") {
            return JevEndpoint(url: URL(string: "https://api.typesafe.ai/v1/systemone")!, key: key,
                               model: model, keyName: "JEV_API_KEY")
        }
        if let key = value("OPENROUTER_API_KEY") {
            return JevEndpoint(url: URL(string: "https://openrouter.ai/api/alpha/decisions")!, key: key,
                               model: openRouterModel(model), keyName: "OPENROUTER_API_KEY")
        }
        return nil
    }

    /// OpenRouter names Jev "typesafe/jev-1.13", with "~typesafe/jev-latest" tracking the newest release.
    private static func openRouterModel(_ model: String) -> String {
        if model.contains("/") { return model }
        return model == "jev-latest" ? "~typesafe/jev-latest" : "typesafe/\(model)"
    }

    static var miniMaxAPIKey: String? { value("MINIMAX_API_KEY") }
    static var miniMaxModel: String { value("MINIMAX_MODEL") ?? "MiniMax-M3.1-Flash-Preview" }
    static var miniMaxBaseURL: String { value("MINIMAX_BASE_URL") ?? "https://api.minimax.io/anthropic" }

    static func value(_ key: String) -> String? {
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty { return value }
        if let value = bundled[key], !value.isEmpty { return value }
        return nil
    }

    private static let bundled: [String: String] = {
        guard let url = Bundle.main.url(forResource: "app", withExtension: "env"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var values: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let line = line.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#"), let equals = line.firstIndex(of: "=") else { continue }
            let key = line[..<equals].trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "export ", with: "")
            var value = line[line.index(after: equals)...].trimmingCharacters(in: .whitespaces)
            if value.count >= 2, let first = value.first, first == value.last, first == "\"" || first == "'" {
                value = String(value.dropFirst().dropLast())
            }
            values[key] = value
        }
        return values
    }()
}
