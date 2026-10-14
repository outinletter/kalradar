import Foundation
actor RouteClient {
    static let shared = RouteClient()
    struct Route: Sendable { let origin: String?; let destination: String?; let number: String? }
    private var cache: [String: (Date, Route)] = [:]
    private var blockedUntil = Date.distantPast
    private let session = URLSession(configuration: .ephemeral)
    static func decode(_ data: Data, callsign: String) -> Route? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let response = root["response"] as? [String: Any], let route = response["flightroute"] as? [String: Any],
              (route["callsign_icao"] as? String)?.uppercased() == callsign else { return nil }
        func airport(_ key: String) -> String? { let airport = route[key] as? [String: Any]; return (airport?["iata_code"] as? String)?.nonEmpty ?? (airport?["icao_code"] as? String)?.nonEmpty }
        return Route(origin: airport("origin"), destination: airport("destination"), number: (route["callsign_iata"] as? String)?.nonEmpty)
    }
    func route(callsign: String) async -> Route? {
        let key = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard key.range(of: SharedRadar.filterPattern, options: .regularExpression) != nil else { return nil }
        if let (date, value) = cache[key], Date().timeIntervalSince(date) < 3600 { return value }
        guard Date() >= blockedUntil, let url = URL(string: SharedRadar.routeBaseURL + key) else { return nil }
        do {
            let (data, response) = try await session.data(for: URLRequest(url: url, timeoutInterval: 8))
            guard !Task.isCancelled, let http = response as? HTTPURLResponse else { return nil }
            if http.statusCode == 429 { blockedUntil = PublicADSBClient.retryDate(http, now: Date()); return nil }
            guard http.statusCode == 200, let result = Self.decode(data, callsign: key) else { return nil }
            cache[key] = (Date(), result); return result
        } catch { return nil }
    }
}
